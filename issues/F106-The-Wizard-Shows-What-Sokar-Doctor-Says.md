# F106 — The Wizard Shows What `sokar doctor` Says

**Status:** blocked; decided on 2026-10-10. Blocked by `sokar`'s B161, "Doctor As Data"
(`sokar doctor --json`).

**What must be true.** When a Linux machine is added, this computer or one over ssh, the interface
shows what `sokar doctor` says about it, finding by finding, with its colour. The checks live in one
place, in `sokar`, and the interface repeats none of them.

## Why

The connection wizard today tries the socket and says whether the daemon answers. Whether podman,
systemd, SELinux, the hooks and the agents are in order on that machine, `sokar doctor` says on a
terminal, and the interface says nothing of it. A person who adds a machine that cannot run a task
finds out only when the first start fails.

## The shape

- **When a machine is added, and on demand later** from the machine's view, the interface runs
  `sokar doctor --json` there: on this computer directly, over ssh as the other `sokar` commands
  are run there.
- **Each finding is shown** with its words and its remedy, coloured by its state as `sokar` colours
  it on a terminal: `MISSING` red, `DEGRADED` and `UNKNOWN` yellow, `OK` green.
- **In `sokar`'s order:** `--json` lists the findings in the order of the text, from the same
  checks, so the interface and the terminal cannot disagree. Its `notes` (what was not used, not
  taken, or failed) are shown below the findings.
- **Nothing is repaired from here.** The remedy is shown; running it stays the person's.
- **The machine is added either way.** A red finding is said, not a reason to refuse the machine.

## Acceptance

- **A machine with a fault shows it:** on the VM, a machine whose `sokar doctor` reports a missing
  part shows that finding in red, with its remedy. Seen to fail: the same machine added today, which
  shows only that the daemon answers.
- **A machine in order shows only green.**
- **The words are `sokar`'s:** the finding's text and remedy come from `--json` unchanged.

## To be checked

- **A daemon method beside the command**, open in B161: if `sokar` adds one, a machine already
  connected is read through it instead of through `sokar doctor --json` run there.
