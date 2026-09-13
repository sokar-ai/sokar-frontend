# F35 — A Failed Operation Waits Until Seen

The operator's decision on 2026-09-13, answering Sokar's QB10. Reported by the operator: a start
failed, the view closed before he could read why, and he looked for the failure under **Needs you**,
where it never appears.

## What is wrong today

A failed operation reaches the list *"What this session ran on <machine>"* and the machine's status
line. **Needs you considers questions and work, never operations**, so a failure somebody started and
then looked away from is found only by going to that machine.

## What must be true

**An operation a person started that failed stays under Needs you until that person has opened it.**

## Acceptance

- A failed operation appears under Needs you as a tile headed by its machine, saying what was run and
  that it failed.
- **It stays until it is opened**, from the tile or from the machine's list of operations; opening
  it anywhere puts it away everywhere.
- An operation that succeeded never appears there, and one still running does not either.
- It ranks below an open question with a deadline, which can still be answered, and is counted with
  what needs somebody.
- This widens the decision *"Needs you shows only what needs a person"* in `doc/decisions.md`, and the
  decision says so.

## To be checked

- **Whether a failure from before a restart of the window waits too**, once operations outlive the
  window (F36). Without F36 there is nothing to show; with it, an unseen failure from yesterday is
  still unseen.
