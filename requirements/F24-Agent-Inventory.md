# F24 — Agent Inventory

**Status:** open — one of four criteria built, three waiting on reply fields that are agreed and
being added.

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

Built: every installed agent with the version it pins and where it was found, an agent reporting no
version saying so rather than showing a blank, the hosts it needs, and the ones that could not
describe themselves listed rather than left out.

Three criteria wait on reply fields, all of them asked for and all of them agreed:

- **The destinations deliberately refused.** An agent declares `refusedDomains` beside
  `allowedDomains` — it has always done so, and the backend's own acceptance suite asserts that a
  refused name comes back NXDOMAIN. It is simply not on the wire yet. This criterion is right as
  written and belongs here, not in the project egress view.
- **The pinned build and its digest.** `Agent.version` **is** the pin: it comes from the agent's
  own manifest, not from asking the binary. The digest is per *artifact* rather than per agent —
  an agent has a list, and an artifact may be deliberately unverified with a stated reason, or
  there may be nothing to fetch at all. Three honest states to render, once the list arrives.
- **Which copy is shadowed.** The rule exists and runs: locations are searched most specific
  first and the first filename wins, with the loser never started. `Agents` answers one entry per
  name, so the losers never reach an interface. Coming as a reply field.

## A correction, 2026-09-07

An earlier version of this view detected two entries sharing a name and marked them, saying it
could not tell which one ran. **`Agents` cannot answer that** — entries are keyed by name — and the
fixtures had been altered to produce it, which is exactly why the tests did not object. Removed.

The rule this breaks is already written down: a stand-in must not be able to describe something the
contract could not deliver. It was broken here by editing a fixture to fit a feature rather than
the other way round.
