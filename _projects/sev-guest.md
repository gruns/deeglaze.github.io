---
layout: page
title: go-sev-guest
description: Client and server logic for AMD SEV-SNP attestations
img:
importance: 1
category: work
---

I'm the primary author of the [go-sev-guest](https://github.com/google/go-sev-guest) project.
When AMD contributed the /dev/sev-guest driver to Linux, it was based on ioctls.
To test Google Compute Engine's support for attestation quality of service controls (anti-DoS) and partner distributions' support for remote attestation, we needed an easy way to collect an attestation report.
From that need came the initial `client` library.
To get good unit testing support, I ended up writing a simulator for attestation report signing.

Things kind of snowballed from there.
After we found that attestations were able to be collected, we needed a way to check that they meet the basic requirements of the platform.
That is, we needed to check the signatures rooted back to AMD in the way we expected.
Then we wanted to check that other aspects of the report matched some expectations.
These latter two needs are less "guest" responsibility and more "server", so the repo is named weirdly, but it's all being implemented over and over by different projects like Confidential Containers, VirTEE, cc-trusted-api, and probably PARSEC soon enough.
We're all making our own message formats and policy logic, but eventually, if we do it right, the IETF standards will make it so everyone converges on the same formats for attestation report and reference value interchange.

An adjacent team had been developing the infrastructure needed to provision machine-specific certificates for verifying attestation reports.
They weren't deployed yet though, so I needed to manually provision the certificates for all our test machines every time there was a host firmware upgrade (which changes the `TCB_VERSION`).
I just threw everything into a protocol buffer that I checked into version control and looked up expected certificates by the machine's hostname.
So far so good.

Certificate storytime.
AMD published a specification for their Key Distribution Service (KDS), which allows you to fetch the VCEK certificate given a `CHIP_ID`, the `TCB_VERSION` it's versioned against, and which model of chip it is.
I then made sure that certificates from AMD matched their specification down to every detail of metadata and x.509 certificate extension.
There's a problem with this however.
The `productName` extension uses a name that is assigned outside the system specification.
There's a "family/model/stepping" (FMS) triple of numbers that `CPUID[1]_EAX` reports that allows you to determine which chip version you're running.
The FMS corresponds to a product name according to the phase of development their change to stepping has caused, with some letter assignment something-or-other.
You thus have to hardcode a table of "x,y,0 means Product-B0", "x,y,1 means Product-E0", "x,y,2 means Product-E1" etc.
We then got the next version of the hardware.
Machines were now Milan-B1 instead of Milan-B0.
Something weird happened, though. We updated the CPUID table to report the correct stepping value for the hardware, but the certificates no longer matched expectations.
The new stepping value was hardcoded to mean "Milan-B1", but the KDS-delivered `productName` was still "Milan-B0".
After some communication with AMD, we learned that the `productName` got assigned at the wrong time during AMD's manufacturing process.
The `productName` was assigned according to the IO chip's FMS, and not the core compute chip's FMS, so we couldn't trust the extension.
As of June 2024, that's still the case with KDS.
The go-sev-guest verification library requires a workaround flag to not cross-reference the productName with the CPUID.
Given that the FMS for the attestation-collector wasn't collected into the report itself, I needed to make the client add that information to the message it created to represent the attestation report.
AMD says that need will go away in the future, since they're going to update the firmware to include the FMS in the report to not need extra information that the report itself to fetch the correct VCEK certificate.

Security storytime.
The AMD Security Processor (AMD-SP) is the rebranded name of the AMD Platform Security Processor (PSP).
The PSP is a small ARM chip in the EPYC package that is a bottleneck for measuring AMD SEV-SNP VM launches and for signing attestation reports.
The host kernel has to manage guest requests from VMs to the chip through serialized locking, so it's possible for one customer to affect another's ability to get an attestation report unless we throttle the requests.
The AMD system programming manual also says as much.
The guest driver did not respond correctly to being throttled, however.

It was possible to have a guest reuse its Galois counter in the encryption on messages getting sent to the PSP.
The PSP maintains its own monotonic counter, and the guest needs to maintain the same counter.
If the counters are ever out of sequence, the protocol may be under attack.
A failure from throttling would mean the message did not reach the PSP, so the guest should not increment its counter.
The driver did not protect itself from using the same counter on different messages, so a concurrent request from user space for an attestation report could cause a communication key (VMPCK0) to leak from simple cryptanalysis.
The solution had some nuances.

1.  The encryption was happening on an unencrypted page.
    Intermediate results of computing the encrypted message allow for information to leak.
    The solution is to encrypt on an encrypted temporary buffer and only copy the result to the unencrypted page for the VMM to pass along to the PSP.
    I found that the Coconut-SVSM attestation report logic had the same vulnerability when it was in PR review, so 2 crypto bugs found at the price of one.
2.  Failure from the host could lead to counter skew between the PSP and guest, so instead of blithely reusing the same counter after returning a failure to user space, the driver would have to fail closed.
    To avoid key leaks, a host failure now drives the response that the communication key gets destroyed and any other attempt to use it returns `-ENOTTY`.
    Thanks to my team's tech lead Peter Gonda for finding this when reviewing my throttling fix.
3.  Failure from the host due to throttling should lead to backoff and retry without returning to user space, and without destroying the communication key.
    The retry is safe in the throttling case because the message is always the same.
    I convinced AMD to update their GHCB protocol specification to allow for a "good faith" VMM error code to work with the guest.
    The guest can use this code to retry sending a request after some time before failing with a timeout.
    Since throttling is an expected host response, this allows the guest to make progress given the new key destruction behavior. 
4.  The VMM error code is stored in the upper 32 bits of the host return value, whereas the lower 32 bits are reserved for the firmware error code.
    The kernel had some type mismatch (`int` instead of `__u64`) in its response encoding, and it was returning uninitialized stack memory in some cases.
    The error code piece needed updating in the GHCB specification, and the uninitialized memory bug led to some extra go-sev-guest workaround code.

The go-sev-guest library design is what our Confidential Computing India team has used as a template for their [go-tdx-guest](https://github.com/google/go-tdx-guest) implementation of the analogous Intel technology stack.
Both libraries are used in [go-tpm-tools](https://github.com/google/go-tpm-tools) as the lead attestation package for Google Compute Engine (GCE) virtual machines.

I wrote go-sev-guest to be independent of GCE so it could be used more broadly.
Indeed many issues opened on it have been from folks working in AWS or Oracle.
Oracle has been testing Genoa machines (the product after Milan) and found that `productName` in the VCEK certificates doesn't even reference the stepping value.
Similarly, the VLEK does not reference the stepping value.
The security posture of the signing key with respect to its `TCB_VERSION` is all relative to the productName, so it pays to test the nittiest of gritty details in cryptographic systems.

The GCE-dependent logic that can fuse with the go-sev-guest APIs is implemented in the `gce-tcb-verifier` project.
