# F78 — A Waiting Push Is Reviewed As At A Forge

**Status:** soon.

**What must be true.** A person reads a waiting push the way they read a pull request at a forge,
not as git's change format.

## Why

The review shows git's diff, which is correct but made for a machine. The backend is short of
nothing.

## Acceptance

- Files on the left, in the machine's order (what is dangerous by kind first, as now). Seen to fail:
  a scenario in `work_handover.feature` where the list is in another order.
- On the right, the file old and new side by side, or one under the other at a switch, with syntax
  colors, and the unchanged lines around a change expandable to the whole file. Seen to fail: a
  widget test where the switch, the colors or the expansion is missing.
- Each file can be ticked as read, and the review remembers it until the push is decided. Seen to
  fail: a scenario where a tick is lost on leaving and coming back to the review.
- Copying the diff and the fetch into one's own clone stay, for what an IDE does better. Seen to
  fail: the existing scenarios for both go red.
