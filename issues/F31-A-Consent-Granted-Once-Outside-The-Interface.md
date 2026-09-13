# F31 — A Consent Granted Once, Outside The Interface

The interface half of Sokar's B31 (an authorization a person grants once), handed to the frontend
on 2026-09-13. **Blocked by Sokar B31**, which itself waits on B28 and B30.

## What must be true

**When a machine needs a person to grant an authorization in a browser, the interface shows the
link whole, opens it on request, and waits visibly for something that finishes outside it.**

## Acceptance

- The consent link is shown **whole** — never shortened, wrapped into something unselectable or
  elided in the middle — and can be selected and copied as it came. A link that was truncated is a
  grant that cannot be made.
- It can be opened in the person's browser with one action, and is still shown after opening, for
  a person whose browser is on another device.
- The wait says what it is waiting for and that it ends **outside the interface**. It is never a
  spinner that implies the interface is doing the work.
- The wait ends when the machine says the grant is complete, and says so; it also ends, in words,
  when the machine says it failed or expired.

## What the backend is short of

The whole of it: Sokar B31 has not built the flow yet, and there is no method or event on the wire
for a pending consent. This file exists so the interface half is recorded where it will be built.

## To be checked

- **What ends a wait nobody finishes.** Whether the machine expires a pending consent, and whether
  the interface offers to abandon it before that — to be read from B31 once it is built rather
  than decided here.
