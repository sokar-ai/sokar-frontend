# F23 — Notifications

**Status:** open

Unattended means unattended. A decision waiting inside a window nobody has open is the same as no
decision at all.

Moved here from the central index, where it was 0010.

## Acceptance

- A waiting decision raises a notification within seconds.
- Finishing raises one, distinguishing success from failure.
- Acting on the notification opens the work it came from.
- Notifications can be turned off per project.

## Notes

Deliverable on the desktop. The daemon's `Prompts` call carries a waiting decision to whatever is
listening, so what is missing is the raising, not the knowing.

## Settled

**The open question is answered, and the answer narrows this rather than cutting it.** F20 is
built and it confirms the transport has no channel that survives the client being closed — so
*delivery to a closed application* is out, and nothing here pretends otherwise. What is delivered
is a **closed window**: the interface is running, watching every machine it is configured for, and
raises on the desktop it is running on. That covers the case this requirement is named for, an
unattended run reaching a decision while nobody is looking at it, and it covers a remote machine
exactly as well as a local one because the watching is the same.

What is left undone by that: nothing reaches somebody whose interface is not running. Nothing can,
without the daemon binding something, which is the one thing the product does not do.
