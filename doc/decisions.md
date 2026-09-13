# Decisions

What was decided and what it costs, including the risks that were looked at and accepted. **A
decision here is not a rule** — rules live in [AGENTS.md](../AGENTS.md) — and it is not an open
question, which is an issue. What it records is a choice somebody would otherwise make again.

| Date | What was decided |
|---|---|
| 2026-09-12 | [The settings file is written atomically and owner-only, and a bad entry is dropped rather than fatal](#2026-09-12--the-settings-file-is-written-atomically-and-owner-only) |
| 2026-09-12 | [A socket that answers is refused rather than deleted; the remaining race is accepted](#2026-09-12--a-socket-that-answers-is-refused-rather-than-deleted) |
| 2026-09-12 | [`XDG_RUNTIME_DIR` is trusted, and that is not a hole worth closing](#2026-09-12--xdg_runtime_dir-is-trusted) |
| 2026-09-12 | [The licence is GPL-3.0-only, pending the operator's word on *or-later*](#2026-09-12--the-licence-is-gpl-30-only-pending-a-word-on-or-later) |
| 2026-09-11 | [Handing off work from another device needs no feature of its own](#2026-09-11--handing-off-from-another-device-needs-no-feature-of-its-own) |
| 2026-09-07 | [The interface raises and supervises its own ssh forward, and a cut stream is a disconnection](#2026-09-07--the-interface-raises-and-supervises-its-own-ssh-forward) |
| 2026-09-07 | [No browser: the interface is a desktop application over a unix socket](#2026-09-07--no-browser) |

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
