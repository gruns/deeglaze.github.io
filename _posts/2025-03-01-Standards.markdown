---
layout: post
title: "Move fast, make shit"
date: 2025-03-01 09:15:00 PDT
categories: musings standards
---

# Innovate privately on trusted technologies and weep

I work on Confidential Computing at Google, and I'm idealistic when it comes to collaboration, developing in the open, and the construction of standards.

Confidential Computing is in its infancy because it's been conflating a few different ideas and has failed to get the ball rolling for some time now.
The first idea is execution environment isolation through hardware-enabled cryptographic protections.
The second idea is remotely attesting to the isolated workload's code identity with manufacturer-endorsed claims that "this is the code you're talking to (in the expected isolation environment)".

Everything in this post is in the context of enterprise software security, because if you care about software supply chain as a startup and aren't a software supply chain startup... I mean, good on you, but this is a lot of cost and worry for smaller operations.

## Execution environment isolation

Enabling both the isolation technologies and remote attestation at a system level are years-long efforts even for Google and Microsoft.
I was 2 years out of my Ph.D. before I started working on making SGX semi-usable, and we unknowingly wrote our own POSIX(-ish) operating system, Asylo.
We had to simulate every system call and try to do so while being extremely skeptical of any information the untrusted environment presented.
It was porous. After a few years, we hired the security researcher that sustained himself for a couple years off bug bounties on Asylo and froze development.

In Intel SGX, AMD SEV, Intel TDX, ARM CCA, and RISC-V CoVE, all the execution contexts are at least protected through memory encryption.
Intel SGX was the first to get enabled on Linux upstream but has failed as a technology for myriad reasons: vulnerabilities, limited hardware support (90MiB RAM total???), and a difficult programming model are all valid "final nails" to seal its coffin.

With AMD SEV, we see the execution isolation capabilities scaling from small "enclave" solutions to full virtual machines.
A VM can be "enclave-like" with specialized virtual firmware, but to get there practically we have to start where people are _now_ with their big environments.
Project Oak has their stage0 firmware that launches a WASM environment.
It's the closest to an SGX on SEV-SNP situation as I've seen.
I will have a hard time making it available to use on Compute Engine though, and that's another story.
AMD SEV had a way to measure its code at launch, but the workflow to do so was not easy for cloud platforms to enable, and it wasn't real remote attestation with PKI.

I think with AMD SEV-SNP and Intel TDX host patches landing in upstream Linux, things are finally starting to get interesting.
Apple launched their private AI based on SEV-SNP, Microsoft launched Confidential Inference, Google's got Confidential Match for ads privacy, and that's just the beginning.

Google, Microsoft, Oracle, Alibaba, Intel, AMD, IBM, Huawei and yet more organizations' emails are all represented on the Linux Kernel Mailing List patch review threads over the years to get these technologies supported in Linux.
The addition of virtualization technologies that promise to remove the hypervisor from the trusted computing base (TCB) add a fundamentally different threat model to the Linux kernel.
In fact, bug fixes for closing holes related to that threat model would not be accepted for many months because we didn't have an agreed-upon baseline definition for what the threat model was.
Thankfully, Elena Reshetova (Intel) and Carlos Bilbao (AMD, then) authored and got merged such a [baseline threat model](https://www.kernel.org/doc/Documentation/security/snp-tdx-threat-model.rst).

A single threat model for multiple technologies.
We should expect the AMD CCA and RISC-V CoVE patches once they come to further add themselves to this threat model document.
We converge on founding principles.

## Remote attestation

Before I talk about the potential good of remote (software) attestation, I must first address the elephant in the room.

### Software attestation as a "big bad"

[Software attestation is a term soaked in controversy](https://datatracker.ietf.org/doc/statement-iab-statement-on-the-risks-of-attestation-of-software-and-hardware-on-the-open-internet/).
At its core, cryptographic signing of exact software bits is usable for making claims of authenticity.
"This code is known to be exactly the same as (those produced by corporation A)" is a valuable statement for protecting enterprise workloads from insider threats on running systems.
"This code is known to be exactly the same as (MPAA-allowlisted video decoders that are given access to decrypt a video purchase)" is technically the same form of statement but much more chilling to a consumer or art historian.
End User License Agreements (EULA) attached to physical and virtual things we buy are long legalese that boils down to, "you don't own this. You're buying limited access. Also you can't sue us in court because we figured out people will just accept that now hahaha."

Remote attestation, cryptography, and encrypted execution environments make it possible to protect cryptographic keys in use, keep them stored remotely in a secure location, and only release the keys to authorized software.
This is a powerful capability is used to protect your Chrome passwords, access to your personal data for personalized ads, and soon so much more.
On the client side though, we're looking at the same forced network connectivity to access your purchased content the way Valve's Steam pushed on us over a decade ago.
If a key server is down, your ISP has an outage, or you're in most any rural area, you are out of luck.
The digital divide grows wider with added restrictions and meager developments in widespread free or low-cost internet access.

Cory Doctorow came to speak at Google years ago to decry DRM technologies that lock consumers out of their own hardware.
His story was similar.
A colleague of mine decided to troll him, though.
"I _love_ DRM technologies, because they can better protect customer privacy in the Cloud!"
Not all the way wrong, but Cory was not on his back foot.

If SGX taught us anything, it's that hubris is folly.
Cryptographic isolation technologies will never be bullet-proof.

> All it takes is one machine to have its fused secrets extracted for the system to tumble down.
> The Cloud provider still has control of job scheduling.
> If you have a target, you just send them to the compromised machine and then extract their secrets.

A not-incorrect quip.
A very real situation in fact, given [Google did indeed find a way to steal a chip's secrets](https://github.com/google/security-research/security/advisories/GHSA-4xq7-4mgh-gp6w).
It does speak to the increased cost of an attack, but it doesn't stop a motivated, skilled, and well-funded attacker.

### Untrusted hosts

The "selling point" of Confidential Computing is that it removes the host from the trust boundary, or at least makes boundary violations more discoverable through remote attestation.
This is mistinterpreted by many to say, "the host is untrustworthy and if they have any kind of security hole, then they will immediately attack it."
You have to trust your host service, because there is no unbreakable system, especially with physical access.
It makes _no_ business sense to attack your customers, unless compelled at gunpoint like my colleagues in Russia were.

Confidential Computing is a means of stopping your trusted hosts from being able to comply with blind subpoenas (or other legally questionable data breaches).
So, how do we make compelled attacks detectable?

- We make it really hard to execute (bad word choice) by closing as many unchecked communication channels as we can.
- We sign our software to make one-off builds with malware stand out.
- If a compelled backdoor is forced through the proper channels to roll out to everyone, a good host will try to telegraph its operations:
  - Make the user experience terrible so the change is noticeable to customer performance metrics.
    If the compelling force is not so callous as to destroy the entire business and perhaps instigate public outrage, they will back off and allow business to restore non-malware to the fleet.
  - Have a business practice of posting signed binaries at least a couple weeks before they're rolled out to allow for researcher so do binary differential analysis.
    A patient compelling force may still be fine with this, since it's expensive to reverse-engineer binaries.
  - Have a business practice of posting the source code that correspond to its binaries to allow for auditing.
    Compelling force in a non-authoritarian jurisdiction is not permitted to compel publishing false statements, so malware could be caught by audit.
    There are still legally required to _not_ post source code, in the case of vulnerability embargo.
    Embargos are contractual agreements to delay publishing the fix or the vulnerability details ahead of a contractually agreed-upon date as condition to being made aware of the vulnerability and/or its fix.

Now, this all assumes that the host is the one in charge of the TCB like the virtual firmware.
People pay for hosting because they want the maintenance operations taken care of for them, so it makes sense that something as extremely host-specific as virtual firmware will be provided by the host.

### Virtual firmware

Every Cloud Service Provider (CSP) has their own virtual firmware they put in customers' VMs, unless the customer rents an entire server blade to manage the "bare metal".
Azure previously had a private preview for folks to bring their own firmware, but they deleted the blog post about it to memory-hole the effort.
Google controls its virtual firmware.
AWS controls its virtual firmware, although it is published online with a reproducible build (based on a 2022 EDK2 release, so it's not well-maintained).

All of the compelled firmware takeovers can be very discoverable with Bring Your Own Firmware.
If the measurement is not a measurement you made yourself and trust because it's from you, then don't release secrets to that machine.

Azure tried this though, and not enough customers wanted to maintain their own firmware.
There isn't really an easy way to debug virtual firmware when you don't get to see how the VMM works.
We don't have a consortium of hypervisor technologies where we try to offer a consistent experience to folks across platforms.
Google's Vanadium uses KVM and has some Qemu device emulation capabilities, but it's still not Qemu.
Hyper-V is another world.
OverVMM was donated to the Confidential Computing Consortium (CCC), but it will not be what any other major CSP starts to offer folks.

We need trusted second parties to figure out how to provide trusted firmware, and sell that maintenance cost in order to diffuse the responsibility away from the host.
RedHat, a long time maintainer of Qemu and OVMF (a flavor of EDK2), is a great example of a party that folks ought to consider trusting to provide virtual firmware maintenance licenses.
CSPs have to build support for it though, and it'll cost tens of millions of dollars realistically.
There's not enough customer demand.

I sure do wish we could standardize on something.
Microsoft is doing a lot of open source publishing with OpenVMM, OpenHCL, OpenEnclave, contributions to Coconut-SVSM, and the IGVM format.
Whereas my employer and Microsoft are battling over GPUs and AI, I think there's a lot of decent professionals that could make the VM ecosystem better for their customers by talking to each other.
The CCC is one place that's happening, but it doesn't have the charter for standardizing hypervisors.
The more standards, the more redundancies we can eliminate.

However, the more standards, the more commoditized a platform becomes (as seen by business folks).
For something as small as how to launch a VM and operate a UEFI, I don't think there's a lot to differentiate, so there's not a lot of business opportunity in avoiding open collaboration.

### Transparency?

Let's say I require absolutely all the IP in my CSP's host stack to be publicly available, built with a toolchain I trust, and reproducible down to the bits that I see in remote attestation.
You better be a government spending billions and be happy with an NDA to view the source code, because no way any CSP will publish their infrastructure for competition to copy.
Each CSP has spent billions of dollars to learn how to build that infrastructure, and they want their competition to have that same opportunity.

So let's just say virtual firmware.
Confidential Computing means you don't have to trust the host, right?
Wrong, but trust less I suppose.
Still, virtual firmware is mostly all publicly available in EDK2 because of the OVMF project.
There is some glue to paravirtually communicate with the host VMM because emulating SMM (x86-specific) for flash storage is foolish from a security perspective.
There may be some different measurements to TPM PCRs than upstream.

This is not a big cost to make public, right?
Embargos make this hard.
Say you're a UEFI forum member (~$3,200/yr) and have access to the security group communication.
You might negotiate access to the repository to stay within the embargo.
Okay, so which toolchain should the CSP use to build those sources?

#### Toolchain trust is the hardest

Google at least has a toolchain team that contributes fixes to LLVM and other tools, and keeps an internal release close to HEAD.
There is no publicly available Linux distribution that has that cadence of developer tool package deployments.
So, Google trusts that toolchain.
It may even have embargoed patches in it, I don't know.
It certainly did during the Spectre/Meltdown situation.
So, Google trusts firmware built by its toolchain.
Google does use Google Compute Engine, so if we just have the one firmware, we're going to want "max good" for ourselves.

Do you trust that toolchain?
You probably should, since a compelled attack on a customer through first compromising the compiler to insert malware into EDK2 is really hard to do.
If the toolchain container gets published (just the binaries), then a compelled software supply chain attack would be much more obvious with a binary differential analysis.

If instead you're more of a purist and want a non-Google toolchain to build the firmware, then I don't know why you would trust Google to produce the maintained EDK2 source code either.
Say you do, though, for some reason.
Say we build two firmwares: one with our maintained toolchain and one with.. I dunno, RedHat's? No, their sources are behind a paywall because you ought to pay for maintenance.
Let's say Debian. They're a principled bunch.
Oh, that's a really old compiler package.
Hope you don't have toolchain problems that need to be fixed, which often happens with the CLANGDWARF build of OVMF.

Okay.
Toolchain is built transparently.
OVMF is built transparently and somehow works.
We deploy that as an option.
But you get the deployed firmware since it's tighly coupled to the VMM version.
One reset and you upgrade.
Are you on a transparent release?
Oh, okay good.
Did you audit the changes in time?
Oh, okay good.
Oh there's a problem with it?
That's going to take a lot longer to fix, and won't be prioritized until lots of customers decide they want the worse-maintained firmware.

I don't know how to please everyone with just one or two firmwares.
I would point you back at Bring Your Own as a demand for your host.
The whole firmware distribution and compatibility situation has to change, which I repeat I would judge as costing at least 20 million dollars to build, and at least a million yearly to maintain.

You should still absolutely demand as much transparency as is reasonable.
Maintenance costs, and you're paying for it by using the platform anyway.
But you can at least get sources and a build attestation that the sources correspond to the published binary using Google's maintained toolchain.
With Bring Your Own, you get to choose when you upgrade.
You can read our latest updates and then use your agency to bring the most recent release to your VM.

## Your TCB will never be small enough, but it should be inventoried

I don't know about you, but I have a hard time trusting myself to get things right all the time.
I do know that I can trust myself to not intentionally backdoor a system.
Now imagine a system built by several companies through open source collaboration and private innovation.
Can you trust all of them?
What about who they trust?
Do you even know who that is?

You'll have to, realistically, to get work done, but there is something you can start to do to improve the trustworthiness of code generally.
Go to your projects and ensure you have good enough source controls enabled, where "good enough" is scored by the OpenSSF scorecard.
Do it for your own projects first before you try to encourage any dependency projects to do it, because you need to understand what it is you're asking people to do.
If your dependencies do not have the time to do OpenSSF scorecard, give them grace, and see what your employer can do to support its maintenance.
If your dependency cannot be maintained sustainably, then fork it and maintain it yourself.
If you can't do that, then you've identified a weakness in your supply chain that ought to be documented as a risk to your project's health.

Now imagine that we live in a world where your transitive dependencies have demonstrated that they're well-protected from supply chain attacks: no unilateral changes, no downloaded dependencies without integrity-checks, and even demonstrated responsiveness to vulnerability reports.
Let's say they're all scoring 90%, an A- on a difficult comprehensive test.
Your dependencies show good signs of health, but these are still metrics that can be gamed.

### A plea for developers and companies

If you maintain an open source project, please don't sell yourself short.
Make your responsiveness to issues a paid service.
Make your dependency maintenance and release cadence a paid service (if the code is in maintenance mode, update your toolchain and enable the latest sanitizers and warnings).

The open source spirit is essential to collaboration to solve big problems that are shared across companies.
The open source business model is the tragedy of the commons, and the plundered, unfunded maintainers can be leveraged against your company.
Please pay maintainers for service level agreements (SLAs).
We need more contractual agreements with financial support to reduce risk to supply chain health and to combat the tragedy of the commons.

### Attestation Verification Services

The internet runs on Transport Layer Security (TLS) for websites to use HTTPS.
The security of the internet comes from the Certificate Authorities (CAs) that are paid to do the due diligence that a certificate signing request comes from someone who can demonstrate their ownership of a domain.
The internet depends on domain owners to keep their keys safe.
This ensures that communications between you and that domain are encrypted by keys only you and that domain operator have access to.

Notice that none of this trust is based on what that domain operator does with any of your communications to them.
If you're communicating sensitive information, like in a patient portal on an online banking service, then your trust is in the name alone that they are doing what they say they're doing with your data.

The HIPAA, GDPR, and PCI/DSS regulations have some bearing on those operations, but security standards don't have supply chain protections.
They don't have requirements for certain code quality metrics.

Let's be honest about Remote Attestation letting you know exactly what software you're talking to.
You can have a trusted firmware, a trusted cloud provider, a trusted bootloader, operating system, initrd, discoverable disk images, one of which contains some kind of workload orchestration daemon and another that handles the credential activation.
Did you audit all of those?
Read all 10 billion lines of code?
Of course not.
It's the producers of that code that you have to trust, ultimately.
How do we account for all the folks that produced the code that the domain operator is running?
This is the role of an Attestation Verification Service (AVS).

An AVS like Google Cloud Attestation (GCA), Microsoft Azure Attestation (MAA), Intel's Trust Authority (ITA), or SPIRE takes in a bunch of evidence, verifies all the signatures, does... something.. with the measurements, and presents the Attestation Results in some kind of signed token.
What is that something?
What are the results?
How can a lay person make sense of the results?

The answer is very nuanced, because right now everyone is trying to produce something, anything, that satisfies some of their customers' requirements.
Requirements in this are not particularly well-scoped.
So we all do something different.

Intel Trust Authority has grand visions like a lot of us do, but we need to build a lot more infrastructure and convince people it's worth using before any AVS is truly successful.
At the moment can just verify a TDX quote as genuine and was generated by a host with TDX TCB with a particular security posture (e.g., some TDX module releases have had security bugs).
What else it quoted, like the MRTD and RTMRs and other measurements (MR is "measurement register") are unchecked, but... could be checked.
MAA similarly checks the authenticity of the quotes, but just parrots back the measurement values it thinks might be important to you; they could be checked by MAA, but they're left to the relying party to check for themselves using an source of reference values.
They likely are working on more features, but I'm unfamiliar with them beyond the documentation.

GCA works for SEV VMs, so it trustes the host, but it at least as a host-provided virtual Trusted Platfor Module (vTPM) that measures all the boot components and signs them with a Google-issued key; it checks Confidential Space measurements.
Confidential Space is a product that runs a special flavor of Container-Optimized OS (COS) called Attested COS, or aCOS.
aCOS emphasizes measured-boot integrity protections and a more locked-down user space, which includes a trusted container launcher that will also measure the digest of the one container it's allowed to launch.
So, GCA checks that secure boot passed muster and that GRUB2 measured the kernel and (integrity-protected) initrd that were built for that version of aCOS, and it produces a token that the container digest is indeed running on the Confidential Space platform.
Knowing that a single container digest is running on your platform is still not particularly useful for relying parties.
They get a very restricted policy language called Common Expression Language (CEL) that's basically propositional logic with basic comparisons in order to assign a "Workload Identity Pool" to a matching Attestation Result.
It's inclusion in this pool that can be used in Identity and Access Management policies to restrict access to certain resources only to acceptable workloads running in Confidential Space.

When you have vertical integration of firmware down to user space, it's much easier to know what reference measurements to use, but if you want a "general purpose" AVS, there's so much more to do.
Let's talk about what a coherent ecosystem for general purpose AVSes might look like.

### Attestation Ecosystem

Let's say you want to may your own flavor of Confidential Space, but you want to use some form of general purpose Attestation Verification Service.
What would that look like?
The only company that has written down enough information about what this would look like soup to nuts is ARM, since they sell their IP for other folks to implement, and it better have clear documentation.
They have a reference AVS implementation at https://github.com/veraison/services.
All the inputs and outputs of the Veraison stack are documented in Internet Drafts on the IETF datatracker, and are going through the RFC process.
By doing this all out in the open, they're inviting other folks to join the conversation and to ensure we can all satify each others' needs with a small set of (extensible) standards.

The generic formats they've been specifying include EAT, CoRIM, and CMW.
There are specific uses of each of these formats that they use for ARM CCA and Veraison.

ARM CCA uses the Trusted Computing Group's DICE measured boot standard to measure the boot chain up to the Realm Management Monitor (RMM).
The RMM itself has a Platform Service Attestation Token with the DICE boot chain's verified measurements in it to certify the key that signs CCA tokens for each of the confidential VMs (realms) the RMM launches.
These tokens are similar to TDX quotes and SEV-SNP Attestation reports, except it splits the platform from the guest.
Where TDQUOTE has MRSEAM and CPUSVN and SEV-SNP has all the TCB_VERSION entries that each describe host TCB state, ARM puts those concerns into the separate PSA token.

To understand the values of these tokens, there's a need for signed reference measurements that are understandable by all the AVSs that want to support ARM CCA.
These are CCA endorsements, and they use CoRIM to wrap "reference triples" to match target environments with reference measurements that will appear in the CCA tokens.
Endorsements do not have to cover every measured element.
Just as there can be a different firmware provider from bootloader provider, so too can there be different endorsement providers for their respective components.
Signed endorsements can be published for each component, ingested by AVSs, matched against evidence, and then the Attestation Result can carry information about "who" signed "what", or simply fail if an additional policy evaluates these whosiwotsits as unacceptable.

Is this still too much information?
You bet your butt it is.
If we're talking about a global ecosystem of everybody signing whatever they want and making it available to match against for attestation results, then that's an abuse vector.
So we use federation: only take information about particular feeds of software from particular sources of endorsements.
But if we're using pub/sub and staying up to date, then we have to be careful about what view of the endorsement database we're presenting to the AVS so the information is internally consistent.
We also might have a problem with query latency if we need to query an endorsement database multiple times or with a complex query in order to gather all the revelant endorsements about the evidence being appraised.

If you're an AVS, now you've got an issue of which endorsement database is important to which customer and how to make the service scale.
As an attester, you're in control of what information you share with any particular party.
As a user of an attestation verification service, you're in control of which policy you want executed for a particular set of evidence.
As a relying party, there's a particular policy and set of results you're looking for in the attestation results.
It's the policy selection that plays an important part.
The policy decides which slice of the global federation of endorsement databases is relevant.
The policy decides which claims to share with relying parties.
How do we define these policies so they scale to the internet?

Will anyone write policy that isn't "every measurement has a signature, and that signature is from the set of binary providers I trust"?
Any kind of online analysis of trustworthiness of a measurement is going to fall over at scale.
That has to be done offline as batch jobs.
So if you do analysis and find something concerning, there's a good chance it's a false positive, since static analysis is still pretty awful.
Example from GitHub's dependabot, paraphrased, "your little tool uses a language that has a vulnerability in its standard library for servers" and you'll say, "yeah but it's not a server" and move on.
Rinse and repeat for a gajillion packages in your deployment.
Still there could be something it finds that is indeed a problem, so you should have these scans on to check periodically, but they shouldn't stop your endorsement pipeline.
If the quality of these tools does matter to you sometimes, you can add the vulns in-toto predicate to your build attestation and surface that in attestation results.
So, sometimes you might see a policy that says "every measurement has a signature, and that signature is from the set of binary providers I trust. Also `sensitive-dependency` better have a vuln score less than 7".

We're just looking at signatures of binaries, so are we just doing secure boot again?
No, because each and every deployment isn't expected to be updated with new secure boot variables to retract binaries that have a score one user doesn't like and another is fine with.
At the end of this exercise, we have an extra layer of protection at the AVS after secure boot might let some bad measurements through.
Once you've booted to user space, in a production system, you ought to not be measuring anything else into boot integrity registers.
If you do, you do it to poison your environment in response to some intrusion detection or emergent human SSH access (after shutting down the workload and deleting the attested credentials).

So for your own Confidential Space, let's say you have an offline policy generator that synthesizes information from a set of endorsements into a single executable policy.
A general AVS will not permit arbitrary computation.
There will be limits to what you can express, and there may be billing consideration for the execution time charged to the execution of your policy.
You may be able to get a WASM module to run on a representation of partially appraised and annotated evidence and be expected to produce some JSON token of claims, but that makes the data model of annotation a commitment from the AVS.
You may more likely get an Open Policy Agent interface to run a Repo policy document, where you can query what is known about the evidence using provided functions.
You could be looking at endorsed measurement registers as signed by different parties, and you decide who is expected to sign what, given your set of Trust Anchors (see the CoTS internet draft from IETF RATS).
You could also be looking at a list of events that were replayed and integrity-checked against the RTMRs.
Event log analysis is tricky using Rego, given the state machine involved in checking the expected invariants, and the sheer number of queries to the endorsement database you might need to make of event endorsements.
Achieving any kind of acceptable means of understanding reference endoresments from a global ecosystem means getting involved in standards.
At the end of all the checking, what do you report?
Well... what is expected from the relying party?

Relying parties have different levels of sophistication of what they want checked and reported to them.
There is no one size fits all.
If you're using your bank's website, you may just care that the server uses remote attestation in a trusted computed environment, and all the software is accounted for by the bank's production governance policies.
If you're using private AI, you may care about just about all that information, and maybe even the identity of the binaries involved in feeding your data to models, with the same kind of transparency problem as above, but at least here it's AI, so... AI AI AI attestation transparency AI AI.

Then you have the workload attestations and the web of trust woven by microservices and service meshes.
Do you care about the topology?
Probably not, but this is a trust but verify situation.
Best case scenario, the vendor goes through the accounting process to make it reportable, and in so doing finds a bunch of open holes and closes them.
More likely scenario, they do the checkbox security to put pretty paint on their pumice stone of a service.

## Wrapping up

There's more to talk about with respect to meaningful attestation results, automated policy construction, endorsement database federation, and a notion of governance oversight with respect to attestation policies.
One thing is clear to me: attestation will continue to confuse everyone until we build things together to realize a standard.
But, to "differentiate ourselves", we'll move fast, think some, and make absolutely unusable shit.
For a topic as rich and frought as attestation and cryptographic protocols, we need to involve more expert minds.
I may be an expert, but I work too much and need more folks.
Did I mention this could apply to AI? AI AI woo get hype.

Maybe this rambling will make more sense when I present it at OC3.

Attestation, code integrity, and binary transparency has been my focus for 5 of my 8 years at Google.
The first 3 were making the toolchain for Asylo, publishing it as open source, and making its website.
Which was a learning experience.
Fun fact, three other Asylo engineers still work on confidential computing with me at Google Cloud.
