# What the contract does not yet cover

What the interface needs that `org.fuin.sokar.Tasks1` has no method or field for yet. It is short
because almost everything once listed here has landed; when it is empty, delete it.

**Read it before picking up a requirement.** A convincing screen with no method behind it is the
most expensive kind of wasted work, because it looks finished.

## The rule that makes these real gaps

- **Never shell out to the `sokar` CLI and parse it.** An interface that did would be a second
  implementation of every refusal the product makes, and those refusals are the product.
- **Never read or write the backend's files directly.** Over a forwarded socket there is no
  filesystem on that machine at all, so the API is the only way in.

Both rules, and why running `ssh` is not a breach of the first, are in [AGENTS.md](../AGENTS.md). A
gap here is a backend method that has to be added, not a workaround waiting to be found.

## Not on the wire yet

- **A bounded unlock of the secret store, and changing its passphrase, both at the machine.** The
  operator's decision is parked; see [Secret Store Control](../issues/F15-Secret-Store-Control.md).
- **Whether an agent is waiting on a person for its own question.** `WAITING` covers clearance
  questions only. The backend will observe working and quiet from outside for every agent, and let
  each agent declare waiting where it can; until then a quiet task is shown as a guess.

- **A held message's text, and declaring a peer.** Sokar B14's `Talk` never carries text, and a
  project's `mail.peers` and `unread_work_may_leave` live in its project file, which neither
  `CreateProject` nor `Moderate` writes. Asked as QS8 and QF17; see
  [F42](../issues/README.md).

- **Clearing away a project left from before following** (Sokar B74, decided, not built).
  `Unfollow` with `dryRun` answers `NoSuchProject` for a project the machine still lists but does not
  follow, so *Stop following* has nothing to show and nothing is removed from here; a blind `force`
  is not offered, because what it destroys includes pushes nobody reviewed. B74 makes the preview
  answer `PREVIEWED` with `removes`, `keeps` and `unreviewed`, and the refusals a followed project
  gets.

- **Adding a connection step by step** (F47). Agreed with Sokar on 2026-09-19 and not built yet:
  `CredentialDeclare` with `dryRun`, saying who a key logs in as, and with `fromFile`, taking a
  key on the machine into the vault. OAuth is not offered, by the operator's decision.
  (The machine's own ssh keys, F46, are built as `SshKeys()` in `25fdcff` and not yet published.)

- **Trusting a host key a person has seen** (F48, asked 2026-09-19). A fetch that meets an unknown
  host fails as *host key verification failed* and is reported as a missing credential. There is
  no outcome naming the host and its fingerprint, and no way to trust exactly that key.

- **An agent's own login** (F49, asked 2026-09-19). Nothing says how a given agent logs in, so a
  missing credential can only be stored as a key or a token. The agent declaring its login
  command, and Sokar passing it on, is the smallest way.

## On the wire, not used here yet

- **`WatchProjects`**, a push for what `Projects` answers. The project row still asks again after
  anything that would change it; moving it onto the push makes its counts arrive rather than age.

## What to do with this

- **Do not design around a gap**, and do not invent a local workaround: it will not survive the
  first remote backend.
- **Raise it as a backend requirement**, in the `sokar` repository. Adding a method is additive and
  costs nothing under the compatibility promise.
- **Keep this file honest.** When something lands, take it off; when the file is empty, delete it.
