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

Both rules, and why running `ssh` is not a breach of the first, are in [AGENT.md](../AGENT.md). A
gap here is a backend method that has to be added, not a workaround waiting to be found.

## Not on the wire yet

- **A bounded unlock of the secret store, and changing its passphrase, both at the machine.** The
  operator's decision is parked; see [Secret Store Control](../requirements/F15-Secret-Store-Control.md).
- **Whether an agent is waiting on a person for its own question.** `WAITING` covers clearance
  questions only. The backend will observe working and quiet from outside for every agent, and let
  each agent declare waiting where it can; until then a quiet task is shown as a guess.

## On the wire, not used here yet

- **`WatchProjects`**, a push for what `Projects` answers. The project row still asks again after
  anything that would change it; moving it onto the push makes its counts arrive rather than age.

## What to do with this

- **Do not design around a gap**, and do not invent a local workaround: it will not survive the
  first remote backend.
- **Raise it as a backend requirement**, in the `sokar` repository. Adding a method is additive and
  costs nothing under the compatibility promise.
- **Keep this file honest.** When something lands, take it off; when the file is empty, delete it.
