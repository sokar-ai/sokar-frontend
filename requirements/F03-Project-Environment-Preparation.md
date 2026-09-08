# F03 — Project Environment Preparation

**Status:** open, and its one design question is answered. Settled on 2026-09-08:

- **Three depths are real, not two.** The image layers are base → OS packages → *agent layers* →
  project snippet, so invalidating from the agent layer genuinely keeps the package layer. The
  middle choice is honest about what it keeps.
- **It is a mechanism rather than a flag**, which is why it was worth asking before drawing three
  buttons: podman has no *"rebuild from layer N"*, so the middle depth needs a build argument
  placed at the agent layer whose value changes. Implementable, not free — and a screen offering
  three depths where only two were real would have been a lie about cost.
- ~~**Staleness is not computable today.**~~ — **`Project.preparedState` landed on 2026-09-08**
  with `ABSENT`, `READY`, `STALE` and `UNKNOWN`, and the criterion *"starting work against a
  project whose environment is stale or absent says so before anything is started"* is **met**:
  the row marks a stale environment separately from an absent one.
  - **`UNKNOWN` is never drawn as stale.** An image that does not record what it was built from —
    an older Sokar, or a project whose file has moved — is not known to be either, and rebuilding
    for no reason is how the word stops being read.
  - **What counts as a change is narrow, and that is what makes the mark worth reading**: the base
    image and the image snippet, nothing else. Egress, limits and the upstream change what a task
    may *do* rather than what it is built *from*.
  - What is still missing is the preparing itself, at depths — see
    [B19](https://github.com/fuinorg/sokar/blob/main/requirements/base/B19-Preparing-An-Environment-On-Purpose.md).

Making a project runnable, and rebuilding it when something underneath has moved.
The distinction that matters is how much gets thrown away, because the cheapest
rebuild takes seconds and the most thorough takes many minutes.

## Acceptance

- Preparing a project's environment from scratch is one action, and it completes or
  fails with a stated reason.
- Rebuilds are offered at distinct depths, described by what each one replaces and
  roughly what it costs in time — reuse what exists, replace only the agent tooling,
  or discard everything and rebuild.
- Progress is visible while a build runs, and the rest of the interface stays usable
  meanwhile.
- A build that fails names the step that failed, and the failure is still readable
  after the fact.
- Starting work against a project whose environment is stale or absent says so
  before anything is started, not after.

## Notes

The depth choice is the whole requirement. A person who cannot tell the three apart
picks the slowest one every time, or the fastest one and gets a stale result.
