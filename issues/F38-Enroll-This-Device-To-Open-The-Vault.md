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

## Built against the proposal, 2026-09-18

**Where it lives, decided by the operator on 2026-09-18:** in the machine's title, beside the
emergency stop, because a vault belongs to a machine and a device that cannot open it from here is
as important to see as being able to stop what runs. A **lock** shows whether the store is open and
opens or shuts it; **"Enroll this device"** stands beside it, filled, only while this device is not
enrolled on that machine. The machine's menu offers all three as well, so an open store on a device
that is not enrolled can still be shut. **No paragraphs of explanation**: a tooltip and one line in
each dialog.

Built against B60's proposal and a mock that answers it (`EnrollDevice`, `Keyslots`, `RevokeKeyslot`,
`UnlockWithShare`), so what is left when B60 is built is to check the names match:

- The key is kept **before** it is sent and removed again on a refusal, so an answer lost after the
  node took it leaves a device that still holds it; a second try sends the same share, which the node
  answers `ALREADY_ENROLLED` rather than making a second keyslot.
- Enrolling is offered only into an **open** store; a shut one says to unlock it at the machine first.
- The answer is said in the dialog that asked, like the emergency stop's.

**Still open:** the key is held in memory until the platform keystore is wired
(`flutter_secure_storage`, which needs `libsecret-1-dev` to build on Linux). Nothing is pushed
before it is.
