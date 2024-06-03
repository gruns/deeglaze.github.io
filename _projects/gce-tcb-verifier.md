---
layout: page
title: gce-tcb-verifier
description: Open Virtual Machine Firmware code signing for SEV-SNP and TDX on Google Compute Engine
img:
importance: 2
category: work
---

I'm the primary author of the [gce-tcb-verifier](https://github.com/google/gce-tcb-verifier) project.
This repository holds a suite of tools I needed for signing reference measurements of Google's fork of [edk2](https://github.com/tianocore/edk2) that we use in VMs that request a UEFI.
EDK2 is a toolkit for many firmwares, but we just use it for OVMF (Open Virtual Machine Firmware).
The things you need for code signing are a key, and a document to sign that represents the code metadata and cryptographic digest.
This repo provides tools for generating a document from an OVMF binary, signing that document, and managing said signing keys.
There are other tools out there for calculating the expected SEV-SNP measurement of an OVMF binary, but this one is specific to GCE configurations.

## Keys

For a key to be trustworthy, you need a certificate to share with users.
To diffuse risk of key material loss or signing too many times that its security is diminished, it's best for the signing key to be short-lived, and for its certificate to be signed by a longer-lived authority.
I went with just a 2 level chain-the root certificate authority key and the signing key.
I wrote my own offline certificate authority software for managing key creation, certification, and rotation, because the Private Certificate Authority Service product had just gone General Availability, and it didn't support key rotation for asymmetric keys.
That is all available in the gce-tcb-verifier endorse tool as the `bootstrap` and `rotate` commands.
The open source project has Cloud KMS API interface abstractions but not a full end-to-end implementation since I use a non-standard pathway to Google Cloud connections, and I didn't want to write a whole bunch more software I wasn't going to use.
PRs welcome!

When first starting the project, I wanted signing to be offline in a secure room with a hardware security module (HSM).
When that was vetoed for being too time-consuming, I chose to use a Cloud KMS HSM key for my certificate authority root key.
Signing keys are less expensive software keys that get rotated frequently.
Certificates and key metadata are stored in a Google Cloud Storage bucket.
The hardest part of the whole project was just configuring all the role accounts and connection permissions.

## Signing

I have a UEFI and I have a measurement to sign.
The Trusted Computing Group (TCG) already specified a document for this purpose, called a Reference Integrity Manifest (RIM)!
I checked it out though, and it didn't really look like something we wanted to mess with.
First, the format is signed XML, so you need a whole XML canonicalization algorithm, which is too much.
Second, the format is essentially not used at all, according to my contacts at the TCG, Chris Fenner and Darren Krahn.
Third, the unmeasured event in the TCG PC Client Platform Firmware Profile for referencing the RIM document gave readers no actual method of locating the document-only its name by GUID.
Finally, the IETF was working on a replacement in a more suitable encoding based on CBOR and COSE.
They named the draft format CoRIM.
When I looked into it in 2022, I was overwhelmed with its complexity and unintuitiveness.
I had no idea how to apply the format to virtual machines in SEV-SNP or TDX.

My team said to leave CoRIM for the future and do something simple, so our cryptography team just suggested delivering a pair of serialized protocol buffer and the signature of that serialization.
That's what I did, but the serialized protocol buffer itself contained the certificate of the key that signed the document.
Only later did I learn that is a bad design choice.
It's two years later, and I've since learned many hardware manufacturers are keeping their hopes up for CoRIM as the reference measurement format of choice.
The CoRIM spec needs a lot of prose and supporting documentation to understand its spirit, as well as multiple example profiles that use it for representing reference values in real systems.
Thus, I started my work on RATS in the CoRIM working group.

## Future?

The document format will need to be binned eventually.
I need to work with industry on a profile definition for SEV-SNP and TDX launch measurements, but the landscape is changing quickly.

### Confession

The document we sign is something I designed in 2022 before I had been knee deep in code signing and IETF working group responsibilities for a long time.
It's a little embarrassing how bad it is, but it gets the job done.
Our crypto department signed of on the format as secure, but it does violate a common principle.
The document should not require parsing in order to verify its signature, but it does.
It's not egregious, since it uses protocol buffers for parsing, so it's very heavily tested, but still.

Why is this bad practice?
For one, parsers are responsible for understanding untrusted data, and thus need to be very well-designed and tested to prevent attacks on a system.
Say you trust your parser unquestioningly, why else is signing the key certificate bad practice?
Suppose you have a key that you use for a while.
You can then assign that key a unique identifier separate from its certificate and only include the key's identifier in the signed contents.
You are then free to deliver the key's certificate in some unsigned header.
A key's use can outlast its certificate, so if you need to issue another certificate for the same key, you can do so without affecting the verifiability of documents signed with that key.
Luckily for me, we rotate our signing keys essentially every release and therefore have no need for such a use case.

It is the key identity's separation from the key's certificate that gives rise to the notion of a "signing envelope format".
The envelope has generic ways of representing

- unprotected headers: data that can be independently verified or is otherwise not security-relevant
- protected headers: data that is included in the signed payload in a documented deterministic manner which is relavent to the security of the message but is not the primary message itself
- payload: data that is meant to be protected by the signature
- signature: the representation of the signature of the protected headers and payload.

This envelope concept is captured in COSE, a CBOR representation of a signing envelope.
