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
- **A snapshot listing, deletion, and a sync that refuses when it would discard unreviewed work**
  are what is still missing on the wire, as
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
