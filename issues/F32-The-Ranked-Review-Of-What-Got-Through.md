# F32 — The Ranked Review Of What Got Through

The interface half of Sokar's B38 (how far something that got through can get), handed to the
frontend on 2026-09-13. B38 itself says *"a ranked review is a screen more than it is a terminal
command"*. **Blocked by B38's buildable half**: the ranking has to exist first.

## What must be true

**A person can see what got through, most far-reaching first, and for each entry how far it can
get — on a screen, not by reading a command's output.**

## Acceptance

- The review is ordered by the machine's own ranking, never re-ranked here.
- Each entry says how far it can get in the machine's words, beside what it is.
- The ranking's absence is said rather than drawn as an empty review: *"nothing has been ranked"*
  and *"nothing got through"* are different sentences.

## What the backend is short of

The ranking itself: B38's buildable half has not produced one, and there is no method returning it.

## To be checked

- **Whether the screen acts or only shows.** Whether an entry offers anything to do about it — and
  if so which of B38's actions reach the wire — is decided once the ranking exists, not before.
