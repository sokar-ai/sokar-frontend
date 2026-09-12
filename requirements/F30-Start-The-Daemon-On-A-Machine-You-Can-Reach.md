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
- **Never without being asked, and the question is put in front of the person.** Running a command
  on somebody else's machine is a step past forwarding a socket, and the interface takes that step
  only on a yes. The question names the host and the command it would run, and it is its own dialog
  — the first version put it at the end of a scrolling panel, where the operator found it only by
  scrolling for it.
- What was run and what came back is shown as it came, including a failure.
- After a start, the connection is tried again by itself, and says what it found.
- The offer is in both places the silence appears: the dialog that adds a machine, and a machine
  already watched that is not answering.
- A stale socket left by a daemon that died is not deleted from here. The interface says what
  refused, because a socket that cannot be connected to and one belonging to a daemon that is
  merely slow are told apart at the machine, not from here.

## What the backend is short of

**Nothing, as of 2026-09-12.** It was asked for in the channel the same day and answered within
hours, in Sokar's `8de32db`:

- **`/usr/lib/systemd/user/sokard.service`**, in the deb and the rpm, installed and not enabled —
  a package that enabled it would start a daemon for every account. So the line run from here is
  `systemctl --user start sokard`, supervised and restarted on failure, and `setsid sokard` is now
  only the fallback for a machine carrying an older package.
- **`sokard --help` no longer starts anything**, and an unknown option is refused rather than
  ignored.
- **A socket is unlinked on the way out**, through a shutdown hook rather than only through
  try-with-resources, so a signal cleans up too. A second daemon binding over the first is refused
  instead of silently stealing its name.

**`sokard.socket` is not coming, and the reason is written down** in Sokar's `doc/daemon.md`: the
JDK offers no way to adopt a listening descriptor systemd bound and passed in. So the first
connection through a forward will not start a daemon by itself, and this requirement stays.

**What is still short is lingering.** A user service lives as long as that user has a session on
the machine, and `loginctl enable-linger` is the operator's decision on their own machine, not
something to be made for them from here. The forward this interface holds is itself a session, so
a machine being watched keeps its daemon alive — and loses it when watching stops. The start says
so when lingering is off, and names the command, rather than turning it on.

## To be checked

- **Whether stopping should be offered too.** It is the same ssh and the same consent, but stopping
  a daemon can take running work with it, and what that costs belongs with the lifecycle rather
  than with a connection test.
