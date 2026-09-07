# F17 — Network Exposure Control

**Status:** open — five of six criteria built. What is left is naming a level: enforcement can be
seen, and cannot be turned off on work that is already running.

What running work is allowed to reach, changeable while it runs, plus the live view of
what it is being refused.

## Acceptance

- The exposure level of running work can be changed from where that work is listed,
  without restarting it.
- The available levels are named by what they permit, not by internal terms, and the
  current level is always visible on the work itself.
- Turning enforcement off entirely is possible, distinct from every other level, and
  visibly marked wherever that work appears.
- Refused connections can be watched live, with enough context to tell what was being
  attempted and by which piece of work.
- A refusal awaiting a person's decision can be allowed or denied from the interface,
  and the answer reaches the work that is waiting.
- Several pieces of work can be watched at once in one view rather than one view each.

## Notes

Related: [Clearance Prompts](https://github.com/fuinorg/sokar/blob/main/requirements/base/B02-Clearance-Prompts.md) for the decisions
themselves, and [what the egress editor settled](https://github.com/fuinorg/sokar/blob/main/requirements/base/README.md#what-was-here-and-is-finished) for the standing
rules. This file covers the live controls attached to running work.

## What is left, 2026-09-07

`WidenTask` landed and with it the criterion this file is named for: what a **running** task may
reach is changed from where that work is listed, previewed first, with the scope — this run, or
this run and the project file — chosen rather than defaulted.

One half of one criterion is not built, and it is not blocked on this repository:

- *"Turning enforcement off entirely is **possible**"*. It is visible — `Task.clearance` says
  `off` and the work is marked wherever it appears — and it is choosable when work is created,
  because `Start` takes `clearance`. That is [F08](F08-Task-Creation-And-Modes.md), which is still
  short of `mode` and `prompt`. **Nothing turns enforcement off on a task that is already
  running**, and `WidenTask` is not that: it grants names while enforcement stays on, which is
  the point of it.

Two things this requirement will not grow a control for until the backend settles them: taking a
grant back from a running container, and granting a set to one. Both are named in
[B12](https://github.com/fuinorg/sokar/blob/main/requirements/base/B12-Changing-What-Running-Work-May-Reach.md)
as undecided.
