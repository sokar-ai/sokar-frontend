# F106 — The Wizard Shows What `sokar doctor` Says

**Status:** blocked; decided on 2026-10-10. Blocked by `sokar doctor --json` in `sokar`, whose
number is to come.

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
- **Each finding is shown** with its words and its remedy, coloured as `sokar` colours it on a
  terminal: red a failure, yellow a warning, green fine.
- **Nothing is repaired from here.** The remedy is shown; running it stays the person's.
- **The machine is added either way.** A red finding is said, not a reason to refuse the machine.

## Acceptance

- **A machine with a fault shows it:** on the VM, a machine whose `sokar doctor` reports a missing
  part shows that finding in red, with its remedy. Seen to fail: the same machine added today, which
  shows only that the daemon answers.
- **A machine in order shows only green.**
- **The words are `sokar`'s:** the finding's text and remedy come from `--json` unchanged.

## To be checked

- **The shape of `sokar doctor --json`:** each finding's check, its state (`OK`, `DEGRADED`,
  `MISSING`, `UNKNOWN`), its words and its remedy, and how a state maps to the three colours.
