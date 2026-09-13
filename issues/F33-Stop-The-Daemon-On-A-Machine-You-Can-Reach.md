# F33 — Stop The Daemon On A Machine You Can Reach

The other half of starting one, split off on 2026-09-13 when starting was met and retired. **Blocked
by Sokar B54**, "Stopping The Daemon Stops The Tasks It Started".

## Why it waits

Asked of the backend as QF4 and **measured by it on 2026-09-13** on the Ubuntu VM, with one task
started through the daemon's socket:

- **Stopping the daemon stops every task it started, container included.** The daemon starts a task
  from inside itself, so the container's keeper, its network, its resolver, its gate, its credential
  proxy and its watcher all sit in the daemon unit's control group, and systemd's default stops them
  all with it.
- **Nothing on disk is lost.** Afterwards the task lists as not running with *resume* as its start
  action, and its workspace is intact. What is lost is the running task, **every clearance question
  its watcher held**, and every open `Watch` and `Tail`.
- **The daemon has no opinion**: nothing refuses or warns, so asking is entirely the interface's.
- **A client cannot tell which running tasks the daemon started** — `List` counts running tasks and
  says nothing about their parent. So an honest dialog today could not name what it would stop.

A stop that silently takes running work and pending questions with it is not a thing to offer behind
a connection dialog. When B54 makes a daemon stop leave its tasks running, this becomes the small
requirement it looks like.

## What must be true

**A person can stop the daemon on a machine this interface reaches over ssh, is told before it
happens exactly what stopping costs, and it happens only when asked.**

## Acceptance

- Only for a machine this interface forwards itself, and only while it answers.
- **The question states the cost as the machine gives it** — which running work, if any, stops with
  it, and which open questions would be left unanswered — and never promises *"nothing running is
  touched"* unless the machine says so.
- Run the same way a start is: the line shown before the yes and run unchanged after it
  (`systemctl --user stop sokard`), what came back shown as it came.
- Afterwards the machine reads as not answering, and the offer to start it is there again.

## What the backend is short of

**Sokar B54**: a stopped daemon must leave the tasks it started running. And, to state the cost
honestly until then or at all, a way to know which running tasks a stop would affect.

## To be checked

- **Whether stopping belongs in the interface at all once B54 lands.** If stopping costs nothing but
  the connection, the only reason to offer it is freeing the machine; that may be the machine's
  business rather than a watching window's.
