---
layout: post
title: "Transparency has value"
date: 2025-06-18 17:15:00 PDT
categories: attestation business
---

In this post, I want to highlight where the value is for hyperscalers, and specifically public Cloud Service Providers (CSPs), to reach for transparency standards and surpass them when it comes to being in their customer's trusted computing base.

# Trustworthy computation

Confidential Computing has a promising potential that has not yet been fully realized in CSPs like Amazon Web Services (AWS), Azure, and Google Cloud Platform (GCP).
The general idea is that by using this technology, you are assured by the hardware manufacturer themselves that

1. you **can** know exactly what the service you're talking to will do with the data you give it (integrity reporting with remote attestation)
2. the host platform will have limited visibility into the computation, only what the service elects to share (confidentiality through memory encryption)
3. the host platform will have limited influence on the computation, since it can only offer information that the service can elects to act upon or not (integrity enforcement)

There are nuances in how the different technologies ensure those properties in order for their claims to be trustworthy.
It's important for the platform maintainers to promptly roll out security updates as flaws are found and fixed with microcode or firmware updates.
The platform firmware version numbers are part of the remote attestation report so you can keep track of your platform provider's obligation to keep hosts maintained.

In my previous post on standards, I gave a realistic look at what it means to build trust in the trusted computing base that is measured for remote attestation.

# Opacity will not be tolerated.

All CSPs right now introduce their own virtual firmware into confidential VMs.
We know from our own sensibilities and many customer conversations that binary blobs simply aren't enough.
Folks are willing to accept incremental progress from nothing, to blob, to signed blob, to yet more information, but we know at least one thing: CSPs MUST allow customer-provided virtual firmware (with a well-documented interface for achieving UEFI variable persistence and ACPI table information) OR publish the sources for their virtual firmware.
Doing both is better, but given the amount of management folks are coming to the Cloud for, published sources are a higher priority.

In the ACM article, [Why should I trust your code?](https://queue.acm.org/detail.cfm?id=3623460), the authors describe a Code Transparency Service that non-repudiably logs claims about the binaries that ultimately measured and included in remote attestation reports.
The publication's research service as described is remarkably similar to https://sigstore.dev for tracking in-toto attestations.
Let's concretize with in-toto.

What claims are foundational to really understanding the software?
At the bare minimum, the binary should be available such that its measurement can be extracted from it, and potentially analyzed, but that is unsatisfying to those of us that don't spend their days staring at disassembly.
You **can** know what it does, but it's time-consuming and error-prone.

Let's say beyond the actual bits, you need assurance that the binary was released by a particular party.
Sigstore tracks a signature of the binary for a claim of authenticity.
You **can** know that the binary does what it does if you trust what the party says about it.

Customers are saying that they don't trust CSPs at their word.
Firmware is too complicated for a single organization to get it right.
They need to see it, or they need to have trusted parties see it and give their endorsement.

# Reproducibility: source is not enough

If I provide a repository of source that has a Makefile, and I say commit XYZ corresponds to binary B, but when I run `make` on my machine, the two binaries are different, then how can I trust that claim?
Do I really have to rebuild everything from scratch to believe this claim?

If you can maintain a reproducible build, that's fantastic.
Anyone who trusts their own build environment can sign a claim that they were able to reproduce the measurement from the sources to not need to do a full build on the fly during an online attestation verification.

Indeed AWS has a reproducible UEFI that corresponds to their attested measurements (https://github.com/aws/uefi).
Signal messenger has a reproducible build for their contact discovery service with their releases' MRENCLAVE value represented in the branch name (https://github.com/signalapp/ContactDiscoveryService-Icelake).
Project Oak has a reproducible build of their stage0 firmware (https://github.com/project-oak/oak/blob/main/README.md#transparent-release).

I don't think reproducible builds are a particularly durable property to maintain over a project's lifetime, especially if everything is expected to shift to confidential computing.

## Durable properties

When toolchains and other dependencies are updated, non-determinism tends to creep in.
Most starting points for common dependencies do not include reproducible builds.
Not every project for libraries and packages used for confidential computing environments are fully committed to maintaining binary reproducibility of their build configurations.

For a durable property, we need the build service's claims linking inputs to outputs to be trustworthy even when the service operators aren't fully trusted.
The SLSA build environment track is working out the standards now, and it looks like the highest level of assurance will require the builds themselves to be in confidential computing environments, with attestation verification done by a trusted verifier against a policy that is also part of the build attestation.

AWS has implemented and formally proven correct an attestation verification engine called [Cedar](https://docs.cedarpolicy.com/), so the margin of error for policy interpretation to build trust in a build is near zero.
It's not yet clear if Cedar can be used for verifying confidential computing remote attestations, but I would expect it is on their roadmap.
The engine, and not the verification service, is verified, so you'd still have a bit of a gap to cross to build trust, but the margins are shrinking.

What's clear is that trust in the build service can eventually be reduced to the build environment definition and its attested runtime protections.
Provide the source and the toolchain container, and you can trust the built outputs came from running that toolchain on those sources, regardless of reproducibility.

# Source transparency

What the ACM article and Project Oak have in common is a focus on transparency.
When sources are firmly linked to the measured binaries with verifiable (indeed falsifiable) tests, you can start building understanding.
Since source code is written for humans, it's this starting point that allow experts to audit published sources for potential problems.

Let's work from an example of some component you need that is running at version 1.0 with security version number 1.
Say 1.0 is supplanted with 1.1 without a security version number increase.
Without transparency, you wouldn't necessarily know if this was adding something you needed and just updated to be at the latest version.
Say the 1.1 release adds a feature you don't depend on, but it also introduces a bug to a feature in 1.0.
Auditors find the bug due to the commitment to transparency, and responsibly disclose the problem to the dependency in question.
The dependency creators release a CVE along with a new release that fixes the bug, increase the project's security version number, and say to update to 1.2 since the latest security version number is 2.
You don't really need to do all that if you're doing fine on 1.0, since it's not affected.
You know you're not affected because you too can read the code.
You can wait to adopt 1.1, and will be glad you did because it's flawed.

It's a bit strange to say that security version number 2 is "most secure", but this is how versioning is.
Software might be released in the single dimension of linear time, but the behavior of those releases don't follow a single dimension.
With in-toto's `vulns` predicate, however, every artifact that's within its service lifetime can should have "heartbeat" endorsements of what is known about that artifact.
It's a "heartbeat" since it should only last a short while, as "current" gets outdated quickly.
You can learn that the dependency you're on is not affected by any particular CVE.
The 1.1 release might have a non-empty "known-CVEs" endorsement.
It's this granularity of nuance that claims and access to source code allow you to best understand your security posture.

# Release transparency

Let's now talk about CSPs' ability to change your TCB without your awareness.
The virtual firmware is still the CSP's responsibility.
In 2023 there was a UEFI vulnerability called BlackLotus.
Machines running affected firmware had to be updated.
Since the CSP is the firmware provider, they need to force the VM to restart into a mitigated firmware.
This happens faster than most customers managing their own firmware would have been able to orchestrate on their own.
Still, it's troubling for confidential computing customers to know that at any time their VM could reboot on a different (still signed) firmware that attestation verification services might be updated to allow, but which is still unannounced.

There was previously no reason to announce a new firmware version.
The firmware should maintain its behavior and update transparently.
But software does not progress linearly.

Firmware release candidates should be announced with their sources and measurement well ahead of their rollout to allow for auditing and reports of flaws.
The problem with this is there is no opt-out of a new release.
If you manage your own verification service instead of using the CSP's provided service, you will be hit with unknown measurements frequently when there is no forewarning.
One of the leaders of the Confidential Computing Consortium, Mike Bursell, believes that maintaining an attestation verification service is a viable business as a means of putting in more effort in finding quality signal, so there's certainly a reason to support third party verifiers.

Unannounced releases remove customer agency and drives many to ask for the ability to bring their own firmware.
Bringing your own firmware allows you to innovate faster with features you need, not just stick to tried and true versions without new unused features; consider Project Oak's small and hardened stage0 firmware.

# Interface transparency

Every CSP seems to have their own virtual machine monitor with bespoke virtual devices to interact with the tightly-coupled virtual firmware.
OpenVMM and OpenHCL (from Microsoft, now under the Confidential Computing Consortium) use the `firmware_uefi` virtual device.
Qemu uses `uefi-vars` for UEFI variable storage and `QemuFwCfg` for configuration of things like ACPI tables.
AWS uses `ExtVarStore` for its UEFI variable persistence (and perhaps `QemuFwCfg`, I haven't dug too deeply).
GCP uses `PvUefi` for UEFI variables and telemetry about boot progress and `QemuFwCfg`, though the source is not public (all the diffs are buried under years of merges, so it's hard to release cleanly without a good chunk of effort).

The `firmware_uefi` and `ExtVarStore` devices are admittedly bespoke since there isn't really a good gathering place for VMM implementers to decide the best way to provide a uniform experience with virtual firmware across platforms.
It wasn't really an issue before.
But now we ought to come together to decide what is it that ought to be provided on virtual platforms so confidential computing use cases can be served everywhere.

When the interface between VMM and user-provided firmware is clearly documented, and there's a place for implementers and customers to come together and agree on what should be available, it's not a bad idea to allow the user to bring their own firmware.

## User-provided firmware

The firmware-unified kernel image ([FUKI](https://people.redhat.com/~anisinha/fuki-ref.pdf)) idea from AWS and RedHat allows a user provided firmware to replace the cloud's firmware, as fetched from the disk image.

The interface is not developed to a mature state for broad adoption–it is a subset of the firmware launch description capability possible with the IGVM format.
The requirement for using the interface is not particularly popular–if we can ensure that the firmware is at a known location on the disk image, can we allow the CSP to launch the user firmware directly without the extra discarded boot sequence?
We will need to solve these problems for users to have full control of their TCB and for CSPs to provide the best possible experience for their customers.

# Conclusion

There are many aspects of transparency, each with their own merits and their own value that confidential computing customers are aware of and have a desire for.
Without commitment to transparency and a clear timeline to achieve it, I have strong reason to believe that will drive the most risk-averse and security-savvy customers to other platforms that take it more seriously.
