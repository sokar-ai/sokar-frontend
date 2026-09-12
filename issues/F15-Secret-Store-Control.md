# F15 — Secret Store Control

**Status:** open — three of seven criteria built here, and **the other four are answered somewhere
by design rather than left undone.** Two will never be possible over this interface; two happen at
the machine. The requirement says which is which, and the screen says it where somebody looks.

The protected store holding credentials has states a person must be able to see and
change: locked, unlocked, and how its unlocking is remembered between sessions.

## Acceptance

- The current state of the store is visible without performing any action on it.
- The store can be unlocked, and locked again, from the interface.
- How the unlocking is remembered — for this session only, or persisted so it survives
  a restart — is an explicit choice with its trade-off stated.
- The recovery secret can be revealed once, deliberately, and the interface records
  that the person confirmed they have stored it. Until they confirm, the interface
  keeps saying so.
- The passphrase protecting the store can be changed, and the change states what it
  affects.
- The revealed secret is not written to any log, transcript or operation record.
- Two parts of the interface asking about the store at once never leave a stale answer
  displayed over a newer one.

## Notes

The unacknowledged-recovery-key reminder is not a nag: a store whose recovery secret
was never written down is a total loss waiting for a disk failure.

## Where each criterion stands, 2026-09-08

Settled with the Sokar side, who separated *"never"* from *"not yet"* rather than leaving four
criteria looking like work somebody forgot. **Everything the screen can do about the other four is
say where it happens** — and *"this happens at the machine"* is a different sentence from *"this
cannot be done"*.

| criterion | |
|---|---|
| the state is visible without acting on it | **built** |
| unlocked **and** locked again | shutting is built. **Unlocking will never be possible here**: a daemon has no terminal to take a passphrase at, so it can shut the store and can never open it. Said beside the button that shuts it, which is where somebody looks for the one that opens it. |
| how the unlocking is remembered, an explicit choice | **built, at the machine**: `sokar vault unlock --for 30m`, with the kernel doing the discarding so nothing has to remember. **No default** — a bound that crept in would start asking people for a passphrase they never used to be asked for. |
| the recovery secret revealed once, and acknowledged | **never over this interface.** `Credentials` answers names, kinds and lengths and no value — the whole promise of the method — on a socket that can be forwarded over ssh. If a recovery secret is ever introduced it belongs at the machine, with a person present. |
| the passphrase can be changed | **built, at the machine**: `sokar vault passphrase`. It re-encrypts under the new one inside the lock `update()` already holds, verifies the old one *before* asking for the new one twice, and drops the cached passphrase — which is now the wrong one, and would otherwise turn the next command into a failure that reads like a damaged store. |
| the revealed secret is never written to a log or operation record | **built by construction**: nothing is revealed, and nothing about the store passes through the session record. |
| two parts asking at once never leave a stale answer over a newer one | **built.** Each question is stamped and an answer that arrives after a newer question is dropped rather than drawn. A stale answer landing on a newer one is invisible — both look like an answer — which is why it has a scenario driving a slow read against a fast one. |

## What locking cannot reach

`Lock` reports `holding`: how many running tasks still hold what their credential proxy read when
they started. Locking cannot reach that memory. **It is said in the same breath as *"the store is
shut"***, never in a detail underneath, because reporting the store closed without it claims more
than happened.

## Updated, 2026-09-08

Both rows that read *"coming"* were built the same day, and neither is a method: `sokar vault
passphrase` and `sokar vault unlock --for 30m`. **Nothing here is "not yet" any more** — every
criterion this interface does not meet is met at the machine, or is refused on purpose.

One consequence to watch rather than discover: a bounded unlock makes a locked store **ordinary**
rather than something somebody did deliberately. `CanStart` answers `VAULT_LOCKED` for it, which is
the outcome the start dialog already keeps apart from a missing credential — so the sentence that
was written for a rare case is about to carry real traffic. It reads *"unlock it at the machine: a
daemon has no terminal to take a passphrase at"*, which stays true whether the store was shut by
hand or by a bound running out.
