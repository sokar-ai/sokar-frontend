# F38 — Enroll This Device To Open The Vault

Opened on 2026-09-18 from Sokar B60, *keyslots*, which the operator decided that day. **Blocked by
Sokar B60**: none of the four methods it needs exist on the contract yet, and the contract is to be
designed with the backend agent before either side builds.

## What B60 changes

The vault's master key is stored only in wrapped form, once per credential allowed to open it. A
device enrolls by generating a random 32-byte share, keeping it in its platform's keystore and
sending it **once**; the node derives a wrapping key from it, stores the wrapped master key and
discards the share. From then on this device opens the vault without anybody typing a passphrase —
the share is worthless without the node's blob, the blob is worthless without a share.

**This screen is the only place a device becomes trusted.**

## What must be true

**A person can make this interface a device that opens a machine's vault: it generates a share,
keeps it in the platform's keystore, sends it once under a name the person chose, and says what the
node recorded.**

## Acceptance

- The share is generated here, **stored only in the platform's keystore**, sent once, and never
  written to a file, a log, the settings, an operation record or the screen.
- The person names the device; the name is what the device list shows later (F40).
- **The storage the share lands in is declared with it** — user-scoped, application-scoped, or a
  stronger release — so the node can record it and nobody later has to guess from the operating
  system (F41).
- What the node answers is shown: the device's id, its name and what it recorded about the storage.
- Enrolling a device that is already enrolled on that machine is refused or repeated in words, as the
  contract decides, never silently doubled.
- A failure says what failed: the keystore refused, the node refused, or the connection went; and a
  share that was generated but not accepted is removed from the keystore again.

## What the backend is short of

**Sokar B60**: a method to enroll a device with a share, a name and a declared storage class.

## To be checked

- **What makes a first enrolling device the operator's rather than somebody else's.** B60 leaves it
  undecided on purpose; the screen must leave room for whatever the node requires at enrollment.
