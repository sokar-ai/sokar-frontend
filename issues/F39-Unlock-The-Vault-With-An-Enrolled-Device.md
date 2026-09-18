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

- Offered wherever a locked vault stands in the way — the vault view and a start refused with
  `VAULT_LOCKED` — and only on a machine where this device is enrolled.
- **Bounded like `sokar vault unlock --for`**: the person chooses how long, and there is no default
  that would quietly change what they are asked for.
- The share is read from the keystore for the call and held nowhere afterwards.
- A device whose keyslot was revoked is told so in words, and offered nothing it cannot do.
- **The passphrase stays the recovery path at the machine**, and the screen says so beside the
  unlock, rather than offering a field to type it into.

## What the backend is short of

**Sokar B60**: a method to unlock with a share for a bounded session.
