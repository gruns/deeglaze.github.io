---
layout: page
title: go-configfs-tsm
description: Golang interface to Linux's TSM configfs subsystem
img:
importance: 1
category: work
---

I'm the primary author of the [go-configfs-tsm](https://github.com/google/go-configfs) project.
This is meant to be a thin wrapper around the already pretty simple configfs interface, but just to make Golang uses of it easier.

## Main features

The TSM report system is the only real subsystem that is merged.
It has several attributes for interacting with AMD SEV-SNP and the SVSM.
The RTMR subsystem that the Intel crowd has been trying to get upstream has a provisional interface in the library.
We have support just for the initial patchset from the mailing list.
The new set being discussed 2025 February/March is not yet part of it.

## Influence and application

This library is meant to be the unifying client library between go-tdx-guest, go-sev-guest, and eventually the expected way to get ARM CCA attestations.
Apparently the ARM and Linaro folks have used it during their own testing.
