# F40 — See And Revoke The Devices That Open The Vault

Opened on 2026-09-18 from Sokar B60, *keyslots*. **Blocked by Sokar B60.**

## What must be true

**A person can see every device that can open a machine's vault, and take one away, and is told what
remains.**

## Acceptance

- The list shows, per device, its name, when it was enrolled, when it last opened the vault, and
  **what its storage is worth** (F41), as the node recorded it.
- This device is marked as this device.
- Revoking one is a confirmed action that names the device, and the answer says which devices can
  still open the vault. Revocation deletes that one keyslot; nothing else is disturbed.
- Revoking this device says that this interface will no longer open that vault, before it is done.

## What the backend is short of

**Sokar B60**: methods to list keyslots and to revoke one by id.

## To be checked

- **Whether the last way in may be revoked**, and what the passphrase keyslot is in this list. B60
  leaves both undecided; the screen must leave room for either answer.

## Built against the proposal, 2026-09-18

The list is in *Show the protected store*, under what it holds: name, storage words (F41), when it
was enrolled and last used, **this device** marked from the slot id it keeps rather than from `self`,
which is only known after an unlock. Revoking is confirmed by name; revoking this device also
forgets its key here, and "Enroll this device" comes back beside the lock. **The recovery passphrase
is listed and not revocable from here**: it is the way in when every device is gone.
