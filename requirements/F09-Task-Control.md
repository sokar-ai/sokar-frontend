# F09 — Task Control

**Status:** open

Acting on work that already exists, from the same place it is listed.

## Acceptance

- Running work can be stopped, restarted, and recreated from scratch, each as a
  distinct action with its effect stated.
- Recreating is offered specifically so that work can pick up a newly built
  environment, and says so.
- Work carries a name a person can change after it has started, **beside** its identity
  rather than instead of it. A task's own name is what every call takes and what the
  gate ref, the workspace and the log files are built from; moving that is not what
  anybody wants when they rename something in a list of forty. Having none is a normal
  state, and work with none shows its real name.
- Work can be deleted, behind a confirmation naming what is destroyed with it —
  including anything created inside it that exists nowhere else.
- Every action reports its outcome; nothing silently appears to succeed.
- Work that cannot accept an action — because of the state it is in — shows that
  action as unavailable rather than failing when it is chosen.

## Notes

The difference between restart and recreate is invisible until it costs somebody an
afternoon. Both are offered by name and described by consequence.

## Reworded, 2026-09-07

This asked for work to be *renamed*. Sokar's answer to the request was the right
question back: a task's name is its identity in four places — the container, the gate
ref it pushes to, the workspace and the log files — so renaming would move a ref that
may have unreviewed pushes behind it.

Nobody wants that. What the criterion was reaching for is a **label**: a changeable
display name beside a fixed identity, which is a reply field and a small method. The
criterion now says so. Everything else here is built.
