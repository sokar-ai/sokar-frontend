# F31 — A Consent Granted Once, Outside The Interface

The interface half of Sokar's B31 (an authorization a person grants once), handed to the frontend
on 2026-09-13. **Blocked by Sokar B31**, which itself waits on B28 and B30.

## What must be true

**When work needs an authorization nobody has granted, the interface asks the person as a question
with a link — naming the service, the project and the task — shows that link whole, opens it on
request, and waits visibly for a grant that finishes outside it.**

Sokar's B31 states the whole of it as *a person grants an authorization once, where a person
actually is, and every task afterwards uses it without holding it and without asking again*. The
criteria below are the ones that reach the interface, taken from B31 as Agent Sokar quoted them on
2026-09-13.

## Acceptance

- **A missing grant is a question, not an authentication failure.** It names the service, the
  project and the task, and carries the link to grant it.
- **An expired or revoked grant reads as needing authorization again** — distinct from a wrong
  credential and from an expired task token, which are different problems with different fixes.
- **The link arrives whole and is shown whole**: one string from the machine, rendered and opened as
  it came, never assembled here from parts, never shortened or elided. It can be selected and
  copied, and stays on screen after opening for a person whose browser is on another device.
- **The wait says what it waits for and that it ends outside the interface** — never a spinner that
  implies the interface is doing the work. It ends, in words, when the machine reports the grant
  complete, failed or expired.
- **Who granted it is shown** where the grant is shown, from the machine's record, which outlives the
  task.
- It is raised the way a clearance question already is — *a question raised by work that is now
  blocked, answered by somebody who may not be looking* — so it reaches **Needs you** and a person
  who is not at the window. What it adds is a link to open and an ending the interface does not see.

## What the backend is short of

**The wire shape, all of it.** B31 has no method for the link or for the grant record yet, and no
event for a pending consent, so nothing here can be built until B31's half is. This file exists so the interface half is recorded where it will be built.

## To be checked

- **What ends a wait nobody finishes.** Whether the machine expires a pending consent, and whether
  the interface offers to abandon it before that — to be read from B31 once it is built rather
  than decided here.
