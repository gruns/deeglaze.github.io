---
layout: about
title: about
permalink: /
subtitle: Logic. Security. Justice.

profile:
  align: right
  image: me.jpg
  image_circular: false # crops the image to make it circular
  more_info: >
    <p>Apple South Lake Union</p>
    <p>333 Dexter Ave N</p>
    <p>Seattle, WA 98109</p>

selected_papers: false # includes a list of papers marked as "selected={true}"
social: true # includes social icons at the bottom of the page

announcements:
  enabled: true # includes a list of news items
  scrollable: true # adds a vertical scroll bar if there are more than 3 news items
  limit: 5 # leave blank to include all the news in the `_news` folder

latest_posts:
  enabled: true
  scrollable: true # adds a vertical scroll bar if there are more than 3 new posts items
  limit: 3 # leave blank to include all the blog posts
---

I'm a software engineer and computer science researcher.
I've worked on programming languages, computer-aided theorem proving, databases, confidential computing (virtualization), distributed systems, and computer graphics.
I live in Seattle, Washington and currently work for Apple PrivateCloud Compute.

My main current project is providing source-to-binary cryptographically verifiable claims that the software you're connecting to is exactly the software you expect to be connecting to.
The software supply chain problem doesn't end at deliverying binary artifacts-those artifacts must have endorsements of build security and software provenance that are checkable at runtime.
The IETF RATS (RFC9334) framework discusses the concepts.
I'm making sure that enterprise-managed software can be made transparent to the end user, and doing so in all cases I can.

## Research interests

I love when reasoning and software combine at the linguistic level.
When there are problems to solve in a domain, I develop languages to express the solution as well as logical frameworks for reasoning about their correctness.
Concretely, recently I've been exploring the connection between code reference value representations as profiles and satisfiability modulo theories (SMT).
The assertions we express about our software in an extensible representation can have theoretical interpretations that cross-pollinate for shared understanding.
A language of profiles doesn't exist yet, but we may yet see them as remote attestation verification services seek to expand their expressiveness.

## Professional interests

Distributed system integrity, operational excellence through software-defined infrastructure, and industry standards for computer security.

My preference is for the computer languages we use to have consistent, concise, and cogent behavior with tooling to assist with unenforced norms and language evolution. I prefer to view data representations with complex interpretations as programming languages to simplify their specification and providing principles for their evolution.
