# F52 — Release A Device's Key Only With A Touch Or A PIN

**Status:** later.

**What must be true.** A person can enroll this device so that its key is released only with a
touch on a security key or a PIN at this machine's TPM, which code running as the same user cannot
supply.

## Why

On Linux and Windows a device keeps the key that opens a vault in a store that unlocks at login, so
anything running as that user can read it. Sokar's keyslots already carry `FIDO2` and `TPM2`
(`EnrollDevice`, `Keyslot.storage`), and this interface already says what each is worth when a
device declares one; nothing here can enroll a device that way.

## Acceptance

- **The share is derived at unlock time**, from a FIDO2 token's `hmac-secret` or from a TPM2 object
  behind a PIN, and is never kept where same-user code can read it. Seen to fail: a test that
  enrolls with a fake token and finds no share in any store or file afterwards.
- **The device declares `FIDO2` or `TPM2` accordingly**, and every place it is shown says what that
  protects against, as for the other classes. Seen to fail: the enrollment request in a test, and
  widget tests of each place a device is shown.
- **A token or PIN that is not there refuses the unlock in words**, and offers nothing it cannot
  do. Seen to fail: a widget test unlocking without the token and with a wrong PIN.
