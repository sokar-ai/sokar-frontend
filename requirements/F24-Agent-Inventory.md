# F24 — Agent Inventory

**Status:** open — two of four criteria built. The pinned build and its digest, and which copy of
a shadowed name is in use, have nothing behind them.

An agent is installed separately from the tool that runs it, so what is installed is a real
question. So is what it may reach, and which build of its own binary it will fetch.

Moved here from the central index, where it was 0011.

## Acceptance

- Every installed agent is listed with its version and where it was found.
- The destinations it may reach are shown, including those deliberately refused.
- The pinned tool version and its digest are shown.
- An agent shadowed by another copy is reported as not in use.

## Notes

**Nothing in the interface may name a specific agent**; the list is discovered. The daemon's
`Agents` call answers it, including the agents that failed to describe themselves - one that
cannot answer is installed and unusable, and leaving it out would read as absent.

## What is left, 2026-09-07

Built: every installed agent with its version and where it was found, an agent reporting no version
saying so rather than showing a blank, the hosts each one needs, and the ones that could not
describe themselves listed rather than left out. Two copies under one name are both listed and the
name is marked as having more than one.

Two criteria have nothing behind them, both asked for on the channel:

- **The pinned tool version and its digest.** `Agent.version` is what the binary reports about
  itself. The criterion is about the build it will *fetch*, pinned so two machines run the same
  one, and the digest that makes the pin checkable. Neither is on the wire.
- **Which copy of a shadowed name is in use.** `from` says where each copy was found; nothing says
  which one runs. The interface says so rather than guessing — this is the one field where being
  wrong is invisible, because both copies look plausible and the wrong one is only found by a run
  behaving unlike the version somebody read on screen.

A third criterion may be misplaced rather than missing: *"including those deliberately refused"*.
There is no refused list per agent, and *"asked for and deliberately not given"* already exists in
the project egress view. Waiting on confirmation before rewording it.
