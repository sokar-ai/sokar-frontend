# F15 — Secret Store Control

**Status:** open — three of seven criteria built. **Two of the remaining four will never be met
here**, by design rather than by omission, and the requirement now says which.

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
| how the unlocking is remembered, an explicit choice | **coming**, as a bounded unlock (`sokar vault unlock --for 30m`). Today there is one behaviour and no choice, and the screen says so. |
| the recovery secret revealed once, and acknowledged | **never over this interface.** `Credentials` answers names, kinds and lengths and no value — the whole promise of the method — on a socket that can be forwarded over ssh. If a recovery secret is ever introduced it belongs at the machine, with a person present. |
| the passphrase can be changed | **coming, at the machine.** And worth stating precisely: **nothing can do this today**, in the command line either. *"Nothing can do this yet"* is a fairer admission than *"the interface cannot"*, which implies somewhere else can. |
| the revealed secret is never written to a log or operation record | **built by construction**: nothing is revealed, and nothing about the store passes through the session record. |
| two parts asking at once never leave a stale answer over a newer one | **built.** Each question is stamped and an answer that arrives after a newer question is dropped rather than drawn. A stale answer landing on a newer one is invisible — both look like an answer — which is why it has a scenario driving a slow read against a fast one. |

## What locking cannot reach

`Lock` reports `holding`: how many running tasks still hold what their credential proxy read when
they started. Locking cannot reach that memory. **It is said in the same breath as *"the store is
shut"***, never in a detail underneath, because reporting the store closed without it claims more
than happened.
