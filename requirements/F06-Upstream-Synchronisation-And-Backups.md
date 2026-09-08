# F06 — Upstream Synchronisation And Backups

**Status:** open, and no longer undecided in shape. Answered on 2026-09-08:

- **A fetch can be triggered, so this gets a button rather than an explanation.**
  `UpstreamDistance.measure(…)` is already a plain callable unit and the fifteen-minute watch is
  only a loop around it. Syncing is therefore the requirement's main action, and everything else
  hangs off it.
- **A listing must never fetch as a side effect**, and that is enforced on the Sokar side rather
  than left to manners: a listing that reached the network would make the queue cost what a
  listing must not. So *triggering* and *listing* are two operations here as well, and the screen
  must not quietly refresh by asking.
- **The listing half is built**, as of 2026-09-08. `Backups` and `DeleteBackup` landed, and the
  reason the listing was missing turned out not to be a missing listing: `gate backup` writes a
  bundle wherever an operator names it and forgets it, so *"what has been taken"* was **a question
  with no data behind it**. The record was the missing part.
  - **That bounds what this screen may promise.** A bundle written by hand, or before the record
    existed, is invisible and always will be — so an empty list says *nothing recorded*, never
    *nothing exists*.
  - **A record is not the bundle.** When it was taken and how much it held are what was true then;
    whether the file is there and how big it is are read from disk now. A bundle somebody moved is
    shown as missing rather than dropped: dropping it would say the backup was never taken, which
    is a different and worse statement.
  - **Deleting takes the path, not an index** — a list that shifted between somebody reading it
    and acting on it would otherwise delete a different backup than the one they chose — and a
    cleared record for a bundle already gone is called a tidy-up rather than a loss.
- **What is left is the syncing half**: triggering a fetch, and a restore that refuses when it
  would discard unreviewed work. The refusal shape exists twice already, in `DeleteProject` and
  `Stop`, so it should be a third use of it rather than a fourth invention. See
  [B22](https://github.com/fuinorg/sokar/blob/main/requirements/base/B22-Backups-That-Can-Be-Told-Apart.md).

Bringing a project's working copy back in line with its upstream, and recovering when
that goes wrong.

## Acceptance

- Synchronising with the upstream is one action, with progress and outcome visible.
- Staleness is reported before the person asks — a project behind its upstream says so
  in the overview.
- Snapshots taken before a synchronisation are listed, with enough information to tell
  them apart: when each was taken and what it holds.
- Any listed snapshot can be restored, and any can be deleted, both behind a
  confirmation that names what is affected.
- A synchronisation that would discard work says so before running, not after.

## Notes

This is the one place where a wrong action loses work that exists nowhere else. Every
destructive path here is confirmed, and every confirmation names the specific thing.
