# F41 — Say What A Device's Key Storage Is Worth

Opened on 2026-09-18 from Sokar B60, *keyslots*. **Blocked by Sokar B60**, which records a device's
declared storage class with its keyslot, an acceptance criterion there at this interface's request.

## Why this is its own requirement

Where a device keeps its share decides who can use it. On **Linux and Windows** the share sits in a
**user-scoped** store — a Secret Service keyring that unlocks at login, or DPAPI keyed to the logon —
so any process running as that user can ask for it. Only **iOS, Android and signed macOS** keep it
**application-scoped**. A lock icon that implies hardware backing on a Linux desktop would be the
interface saying something the platform does not.

## What must be true

**Everywhere a device is shown, the interface says in words what its share's storage protects
against and what it does not, from what the device declared, never from a guess.**

## Acceptance

- Enrollment (F38) says, before the share is sent, which storage it will use on this platform and
  what that means: on Linux, *readable by anything running as this user*.
- The device list (F40) says it per device, from the storage class the node recorded.
- **No wording or icon claims more than the class does.** A user-scoped store is never drawn like a
  hardware-backed one.
- Held by scenarios per class, so a softened sentence fails a test.

## What the backend is short of

**Sokar B60**: the declared storage class, recorded with the keyslot and returned in the list.

## To be checked

- **A stronger release per device** — the share derived at unlock time from a FIDO2 token's
  `hmac-secret` or a TPM2 object behind a PIN, so releasing it needs a touch or a PIN that same-user
  code cannot supply. B60 names it as optional; if it is to be built, it becomes an issue of its own.

## Built against the proposal, 2026-09-18

One sentence per class, said in the enroll dialog before the share is sent and per device in the
list: a user-scoped key is *"readable by anything running as this user"*, and a class this build does
not know claims nothing. **The lock beside the stop is the store's state, not the device's
protection**, and is drawn the same for every class.
