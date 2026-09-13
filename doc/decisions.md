# Decisions

What was decided and what it costs, including the risks that were looked at and accepted. **A
decision here is not a rule** — rules live in [AGENTS.md](../AGENTS.md) — and it is not an open
question, which is an issue. What it records is a choice somebody would otherwise make again.

| Date | What was decided |
|---|---|
| 2026-09-13 | [A unit that refuses is a failure, and a start without one is watched for two seconds](#2026-09-13--a-unit-that-refuses-is-a-failure-and-a-start-without-one-is-watched-for-two-seconds) |
| 2026-09-13 | [Needs you shows only what needs a person; everything else stays in its machine's area](#2026-09-13--needs-you-shows-only-what-needs-a-person) |
| 2026-09-13 | [Needs you has ranks, and a question with a deadline is always first](#2026-09-13--needs-you-has-ranks-and-a-question-with-a-deadline-is-always-first) |
| 2026-09-13 | [A tile keeps its actions, each offered only where it can be honoured](#2026-09-13--a-tile-keeps-its-actions-each-offered-only-where-it-can-be-honoured) |
| 2026-09-13 | [A connection trial may ask the machine `id -u` without a question, to name a wrong uid](#2026-09-13--a-connection-trial-may-ask-the-machine-id--u-without-a-question) |
| 2026-09-12 | [The settings file is written atomically and owner-only, and a bad entry is dropped rather than fatal](#2026-09-12--the-settings-file-is-written-atomically-and-owner-only) |
| 2026-09-12 | [A socket that answers is refused rather than deleted; the remaining race is accepted](#2026-09-12--a-socket-that-answers-is-refused-rather-than-deleted) |
| 2026-09-12 | [`XDG_RUNTIME_DIR` is trusted, and that is not a hole worth closing](#2026-09-12--xdg_runtime_dir-is-trusted) |
| 2026-09-12 | [The licence is GPL-3.0-only, pending the operator's word on *or-later*](#2026-09-12--the-licence-is-gpl-30-only-pending-a-word-on-or-later) |
| 2026-09-11 | [Needs you shows what a machine knows, not what a terminal seems to say](#2026-09-11--needs-you-shows-what-a-machine-knows-not-what-a-terminal-seems-to-say) |
| 2026-09-11 | [Handing off work from another device needs no feature of its own](#2026-09-11--handing-off-from-another-device-needs-no-feature-of-its-own) |
| 2026-09-07 | [The interface raises and supervises its own ssh forward, and a cut stream is a disconnection](#2026-09-07--the-interface-raises-and-supervises-its-own-ssh-forward) |
| 2026-09-07 | [No browser: the interface is a desktop application over a unix socket](#2026-09-07--no-browser) |

## 2026-09-13 — A unit that refuses is a failure, and a start without one is watched for two seconds

The operator's decision, answering Sokar's QB10 after a start from the machine menu failed and said
only that nothing answered. The start line used to throw systemd's words away and start the binary
itself whenever systemd refused.

- **A unit that is loaded and refuses is a failure**, reported with systemd's own words and exit
  code. Starting the binary behind it would run a daemon nobody supervises, next to a unit that
  says it is stopped.
- **Only with no unit loaded** — none installed, or no user manager to ask — is the binary started
  directly.
- **Such a start is looked at two seconds later**, and a daemon that has already ended is a failure
  with its exit code and the last lines it wrote. Two seconds is enough for one that cannot read
  its configuration and short enough not to hold every start. A daemon that dies later is found by
  the connection trial that follows every start, as before.

Measured on the Ubuntu VM on 2026-09-13: the line, run unchanged as `michi`, reported *"started by
systemd"* and the daemon came up in `app.slice/sokard.service`.

## 2026-09-13 — Needs you shows only what needs a person

The operator's decision, closing the question *what it does with many machines and much work*.
The view the window opens on lists open questions and work waiting at the gate, from every connected
machine, and says which machines are silent. **Working, quiet, unseen and stopped work is not in it**:
it stays in its machine's area — running work under *Running*, all of a project's work under the
project — where the same tile carries the same menu.

**Why:** the reason to open the window is a short list of things that need answering. At fifty tasks
a list of every tile is fifty tiles of which two need anybody, and a filter added later to fix that
would hide something without saying what. Nothing is hidden this way; it is placed.

**A question that was answered or ran out stays, with its outcome, until it is put away** with *Got
it* on its tile. The operator's decision the same day: a question that ran out while nobody looked
would otherwise leave the view without a trace, and the confirmation of an answer would vanish with
the click that gave it.

**An operation somebody started that failed waits there too, until it has been opened** — from its
card, from the session record, or by having been open while it failed. The operator's decision the
same day, after a failed start was found only by going to its machine. **No dialog reports an
outcome**: the question before something runs on another machine stays, and afterwards a failure
goes to Needs you and a success to the status line. A start from *Watch another machine* still
shows its outcome in that dialog, where somebody is waiting for the trial, and a failure there is
recorded as well, so closing the dialog does not lose it.

**What would change the answer:** a state that needs a person and is neither a question nor the
gate — an agent that ended with a question of its own, once the machine can say so (Sokar B47) —
joins this view rather than waiting in a machine's area.

## 2026-09-13 — Needs you has ranks, and a question with a deadline is always first

Closing the question *whether "needs a person" is one rank or several*: several, and it was
already built that way. Tiles order by what they are — an open question, then work at the gate, then
working, quiet, unseen and stopped — and within a rank by the nearest deadline, a question with none
sorting after every one that has one, then by the oldest question.

**So a week-old review can never sit above a question with two minutes left**, which was the worry.
The count the view shows is questions and silent machines only: work at the gate can wait for days
without anything being wrong, so it is listed and not counted.

## 2026-09-13 — A tile keeps its actions, each offered only where it can be honoured

Closing the question *whether the actions belong on the card when the view is used from
elsewhere*. They do. The interface runs where the person is and reaches every machine over ssh, so
attaching is `sokar task attach` over ssh in a terminal of the window's own and a diff is fetched
over the socket — see *Handing off from another device needs no feature of its own*. An action a
machine cannot honour from here is shown as unavailable with its reason rather than removed: working
in a task by hand, for one, is unavailable for a machine reached through a socket somebody else
forwarded, because there is no host to log into.

## 2026-09-13 — A connection trial may ask the machine `id -u` without a question

The operator's decision. When *Try the connection* finds the forward up and nothing serving, it runs
`ssh -n -o BatchMode=yes <host> id -u` and compares the uid with the one in the typed socket path, so
a socket in somebody else's runtime directory is named as that rather than as a missing daemon.

**Why without a question**, when starting a daemon asks first: `id -u` reports the caller's own uid,
needs no privilege, reads nothing of anybody else's and changes nothing — and it runs only inside a
trial the person asked for. The rule it relaxes exists for commands that change a machine.

**What would change the answer:** any second command added beside it, or one that reads more than
the caller's own identity. A trial that needs more than that asks, the way a start does.

## 2026-09-12 — The settings file is written atomically and owner-only

Written beside itself and renamed over it, and `0600` before the rename. A write in place is not
one step: a crash halfway leaves truncated JSON, which the reader cannot tell from a first run, so
*"why are my machines gone"* would have no answer in the file. The mode matters because the file
names the machines somebody watches and the accounts they log in as — not secrets, and not
everybody's business; it was `0664` in practice.

**A malformed entry is dropped and the rest kept.** The alternative was a throw during the load,
and that load runs where nobody awaits it: the window opened with the machine list silently reduced
to the local daemon, which is indistinguishable from having lost it. A machine with no name or no
socket cannot be watched or told apart from another, so it is not one.

## 2026-09-12 — A socket that answers is refused rather than deleted

The endpoint of a managed forward may belong to another program of this user that happens to sit at
that path. Taking it away to put ours there would break it silently, so the forward is refused and
says so; only a socket that answers nothing is removed as a leftover.

**Accepted risk:** the probe and the delete are not one operation, so a socket that comes alive in
between is still removed. What would change the answer: an ownership marker or a lock protocol,
which nothing else on either side of this implements, or a per-instance directory. It needs another
process to bind that exact path inside a millisecond-wide window, and a second instance of this
interface — the likeliest candidate — is already prevented by the single-instance socket.

## 2026-09-12 — `XDG_RUNTIME_DIR` is trusted

Both the local endpoint of a forward and the single-instance socket are placed under it, from the
environment. **Accepted risk, and deliberately not defended against:** anybody who can set that
variable for this process can already run code as this user, so a check here would buy nothing and
would break the legitimate use — a test or a sandbox pointing the interface at a directory of its
own, which is how `tool/e2e.sh` isolates a run.

## 2026-09-12 — The licence is GPL-3.0-only, pending a word on *or-later*

The rest of Sokar is GPL v3, and the packages, the POM and `LICENSE` here say `GPL-3.0-only`.
**What is not decided is *or-later*.** It was assumed rather than asked, and it is the operator's
to settle: `-only` cannot be relaxed later without every contributor's agreement, while
`-or-later` cannot be tightened at all. Nothing depends on the answer today.

## 2026-09-11 — Needs you shows what a machine knows, not what a terminal seems to say

Taken when the view was proposed, after the operator pointed at AI Beacon's fleet dashboard. **Taken
from it:** work first rather than navigation first, one pane for every machine, one tile per piece
of work with its state legible and its actions on it, and the machine as a property of the tile
rather than a mode of the window. **Not taken:** leading with model, context and cost, and detecting
*awaiting permission* by reading a session's terminal. Inside a task an agent's own permission
prompts are off by design — the container is the answer — so an agent stopping to ask is a defect
rather than a state to display. What a person is asked is a clearance question, which the machine
knows. A quiet task is drawn as a guess, and a guess is never drawn like a known state.

## 2026-09-11 — Handing off from another device needs no feature of its own

A session on a remote machine is `sokar task attach` over ssh in a terminal of this window's own,
and a diff is fetched over the socket and handed off here. Both were asked for as a separate
capability and both turned out to be what the interface already does, so nothing was built.

## 2026-09-07 — The interface raises and supervises its own ssh forward

Recorded here on 2026-09-13 because Sokar's B06 (remote access) waits on it; taken on 2026-09-07
in `fd52c9e`. Three decisions, each B06 asked the client to make:

- **Which tunnel shape: a unix socket forward**, `ssh -L <local socket>:<remote socket> <host> -N`.
  The daemon never binds a network interface, so local and remote are the same code over the same
  socket. A socket somebody else forwarded is also accepted, and is opened exactly as it always
  was — nothing raised, nothing supervised, nothing taken down.
- **The interface manages `ssh` itself** for a machine described by where it is: one process per
  machine, `BatchMode=yes` so it fails with ssh's own sentence rather than prompting, and
  `ExitOnForwardFailure=yes` so a forward that cannot bind does not read as connected. It owns only
  what it raised, and closing the window takes those down.
- **A cut stream is a disconnection, never an empty machine.** A forward that drops is raised again
  without being asked, and a machine that stops answering is tried again every two seconds; a
  `Watch` that ends without its final reply reports a lost connection. Nothing is re-derived from
  silence.

## 2026-09-07 — No browser

The interface is a Flutter application talking to a unix socket, and reaching a remote Sokar is an
SSH socket forward rather than a server. This was the only requirement in the set that would have
forced the daemon to bind a network interface, and dropping it is what keeps local and remote the
same code.
