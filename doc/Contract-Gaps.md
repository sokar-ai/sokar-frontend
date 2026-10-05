# What the contract does not yet cover

What the interface needs that `org.fuin.sokar.Tasks1` has no method or field for yet. When it is
empty, delete it.

**Read it before picking up a requirement.** A convincing screen with no method behind it is the
most expensive kind of wasted work, because it looks finished.

## The rule that makes these real gaps

- **Never shell out to the `sokar` CLI and parse it.** An interface that did would be a second
  implementation of every refusal the product makes, and those refusals are the product.
- **Never read or write the backend's files directly.** Over a forwarded socket there is no
  filesystem on that machine at all, so the API is the only way in.

Both rules, and why running `ssh` is not a breach of the first, are in [AGENTS.md](https://github.com/sokar-ai/sokar-frontend/blob/main/AGENTS.md). A
gap here is a backend method that has to be added, not a workaround waiting to be found.

## Not on the wire yet

- **Whether an agent is waiting on a person for its own question.** `WAITING` covers clearance
  questions only. The backend will observe working and quiet from outside for every agent, and let
  each agent declare waiting where it can; until then a quiet task is shown as a guess.

- **Clearing away a project left from before following** (decided in Sokar, not built).
  `Unfollow` with `dryRun` answers `NoSuchProject` for a project the machine still lists but does not
  follow, so *Stop following* has nothing to show and nothing is removed from here; a blind `force`
  is not offered, because what it destroys includes pushes nobody reviewed. Sokar's change makes the preview
  answer `PREVIEWED` with `removes`, `keeps` and `unreviewed`, and the refusals a followed project
  gets.

- **Where content Sokar delivered into a task came from.** The ranked review shows what a push
  changes in the machine's order, and would show the origin of what reached the task beside it;
  `Review` does not carry it yet.

- **Matrix in `sokar doctor`.** Whether a machine can carry messages, the transport and its
  homeserver answering, is shown for a project; the machine's own readiness does not include it.

- **A central homeserver shared by several machines**, which `sokar-message-matrix` plans. Until it is
  there, a machine's `Project.messages` says it is not admitted, with its address and the room, and
  a person invites each machine's account from a client of their own.

## On the wire, not used here yet

- **`WatchProjects`**, a push for what `Projects` answers. The project row still asks again after
  anything that would change it; moving it onto the push makes its counts arrive rather than age.

## What to do with this

- **Do not design around a gap**, and do not invent a local workaround: it will not survive the
  first remote backend.
- **Raise it as a backend requirement**, in the `sokar` repository. Adding a method is additive and
  costs nothing under the compatibility promise.
- **Keep this file honest.** When something lands, take it off; when the file is empty, delete it.
