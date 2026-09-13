# F34 — A Start That Says Why It Failed

The operator's decision on 2026-09-13, answering Sokar's QB10. Reported by the operator: a start
from the machine menu failed, and nothing said why.

## What is wrong today

The start line `Tunnels.startsIt` throws away the reason:

- **`systemctl --user start sokard >/dev/null 2>&1`** discards what systemd said when it refuses.
- **The fallback runs whenever systemd refuses**, not only when there is no unit, and it
  backgrounds `setsid sokard … &` and echoes *"started sokard itself"* whether or not the process
  lived.
- **The exit code is the linger line's**, so `went` is true unless `sokard` is missing or ssh
  fails. A refused start therefore ends with *"It was started, and still nothing answers."*

## What must be true

**When a start fails, the person reads why, in the words of whatever refused, and a start is never
reported as done when nothing was started.**

## Acceptance

- **systemd's own words reach the person** when it refuses, together with its exit code.
- **The fallback runs only when there is no unit** to start. A unit that exists and refuses is a
  failure, not a reason to start the binary behind systemd's back.
- **A start without a unit is checked before it is reported**: a process that died straight away is
  a failure, with whatever it wrote before it died.
- **The line is still one constant**, shown in full before the yes and run unchanged after it.
- The trial after a start still decides whether it worked; this changes what a failure says, not how
  success is established.
- Held by scenarios for each outcome: started by systemd, refused by systemd, started without a unit,
  died without a unit, no `sokard` installed.

## To be checked

- **How long a start without a unit is watched** before it counts as alive. Too short passes a
  daemon that dies after reading its configuration; too long makes every start wait.
