# F30 — Start The Daemon On A Machine You Can Reach

Asked for by the operator on 2026-09-12, after the connection test told him the truth and left him
to act on it by hand.

## What is wrong today

[F29](F29-Try-A-Machine-Before-Watching-It.md) made the one failure that used to be invisible
legible: the forward comes up, ssh authenticates, the host is there — and nothing answers at the
socket, because no daemon runs. The trial says exactly that, and names what to look at.

Then it stops. The person opens a terminal, logs into the same machine the interface just logged
into, and runs the binary. Everything needed to do that was in the interface's hands a second
earlier: the host it just reached, the user it logged in as, and the knowledge that the far end is
empty.

The same silence happens to a machine already being watched. A machine that answered yesterday and
does not today is usually this: the daemon is not running, and nothing else is wrong.

## What must be true

**When the interface can reach a machine over ssh and finds no daemon serving there, it offers to
start one — and starts it only when asked.**

## Acceptance

- Only when ssh worked and nothing served. A forward that could not be raised is a different
  problem and is never answered with an offer to start something.
- Only for a machine this interface forwards itself. A socket somebody else forwarded carries no
  host to log into, and nothing is offered for it.
- **Never without being asked.** Running a command on somebody else's machine is a step past
  forwarding a socket, and the interface takes that step only on a yes. The question names the host
  and the command it would run.
- What was run and what came back is shown as it came, including a failure.
- After a start, the connection is tried again by itself, and says what it found.
- The offer is in both places the silence appears: the dialog that adds a machine, and a machine
  already watched that is not answering.
- A stale socket left by a daemon that died is not deleted from here. The interface says what
  refused, because a socket that cannot be connected to and one belonging to a daemon that is
  merely slow are told apart at the machine, not from here.

## What the backend is short of

**A supported way to be started.** The package ships `/usr/bin/sokard` and nothing else — no
systemd unit, system or user. So the only thing that can be run from here is the binary itself,
detached with `setsid`, which nothing supervises and which does not come back after a reboot.

Asked of Sokar in the channel on 2026-09-12: `sokard.socket` and `sokard.service` as **user** units,
socket-activated. With those, the first connection through the forward starts the daemon by itself
and this requirement shrinks to almost nothing. The interface prefers a unit wherever it finds one
and falls back to the binary.

Two defects were reported with it, both of which this requirement has to work around until they are
fixed: `sokard --help` starts the daemon rather than answering, and a killed `sokard` leaves its
socket behind.

## To be checked

- **Whether stopping should be offered too.** It is the same ssh and the same consent, but stopping
  a daemon can take running work with it, and what that costs belongs with the lifecycle rather
  than with a connection test.
