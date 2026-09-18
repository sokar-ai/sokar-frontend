# F39 — Unlock The Vault With An Enrolled Device

Opened on 2026-09-18 from Sokar B60, *keyslots*. **Blocked by Sokar B60.**

## What is wrong today

A locked vault can only be opened at the machine: `sokar vault unlock`, because a daemon has no
terminal to take a passphrase at. With a bounded unlock (`--for 30m`) a locked vault becomes
ordinary, and `CanStart` answering `VAULT_LOCKED` sends a person to a terminal on another machine.

With B60, an enrolled device releases its share, the node unwraps the master key for that session
and persists nothing. **No passphrase is typed and no secret travels in either direction.**

## What must be true

**Where a machine's vault is locked and this device is enrolled there, the interface opens it for a
bounded time with one action, without anybody typing anything.**

## Acceptance

- Offered wherever a locked vault stands in the way — **the lock in the machine's title** and a start
  refused with `VAULT_LOCKED` — and only on a machine where this device is enrolled.
- **Bounded like `sokar vault unlock --for`**: the person chooses how long, and there is no default
  that would quietly change what they are asked for.
- The share is read from the keystore for the call and held nowhere afterwards.
- A device whose keyslot was revoked is told so in words, and offered nothing it cannot do.
- **The passphrase stays the recovery path at the machine**, and the lock's tooltip says so where it
  cannot open the store, rather than offering a field to type it into.

## What the backend is short of

**Sokar B60**: a method to unlock with a share for a bounded session.

## Built against the proposal, 2026-09-18

**Where it lives, decided by the operator on 2026-09-18:** in the machine's title, beside the
emergency stop, because a vault belongs to a machine and a device that cannot open it from here is
as important to see as being able to stop what runs. A **lock** shows whether the store is open and
opens or shuts it; **"Enroll this device"** stands beside it, filled, only while this device is not
enrolled on that machine. The machine's menu offers all three as well, so an open store on a device
that is not enrolled can still be shut. **No paragraphs of explanation**: a tooltip and one line in
each dialog.

The lock opens a shut store with this device's key after asking how long — 15 minutes, an hour,
8 hours or until it is shut, **none chosen beforehand** — and says until when in the same dialog.
It sends the slot id kept beside the share.

**Still open:** offering it from a start refused with `VAULT_LOCKED`; that sentence still sends a
person to the machine.
