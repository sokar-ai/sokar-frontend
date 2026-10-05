# F99 — An Attached Agent Shown At Rest Or Working

**Status:** soon; blocked by `sokar` B118.

**What must be true.** A person sees on a work tile whether the agent in an attached session is at
rest or working, as the machine reads it from the agent's screen, never as a guess from silence.

## Why

For an attached session the machine says neither today, so a quiet tile is shown as a guess; `sokar`
B118 has the machine read the agent's declared rest from its screen, as it reads waiting.

## Acceptance

- A tile of attached work says *at rest* or *working* from the machine's answer, beside what it
  shows today. Seen to fail: a scenario whose stand-in machine answers at rest, and one that answers
  working, each finding the other word or neither.
- Waiting, ended and stopped still win over it, as on the machine. Seen to fail: a scenario with an
  agent waiting on a person whose tile says *at rest*.
- A machine older than B118, or an agent that declares no rest, is shown as today, never as at rest.
  Seen to fail: a scenario against such an answer that shows *at rest* or *working*.
- `doc/Contract-Gaps.md` no longer lists a quiet attached task as a guess. Seen to fail: the page
  still says it once this is built.

## To be checked

- Whether *at rest* arrives as an `activity` value of its own or as `idle` read from the screen
  (`sokar` B118's own question); the tile follows the machine's answer either way.
