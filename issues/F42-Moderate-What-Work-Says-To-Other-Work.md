# F42 — Moderate What Work Says To Other Work

Opened on 2026-09-18 from Sokar B14, *messaging between tasks*, whose five methods Agent Sokar
described that day (`dbacd00`, not yet pushed). **Blocked by Sokar B14** reaching `Tasks1`, and by
two things the contract does not carry yet: a held message's text, and a way to declare a peer.

## What B14 changes

A task can write a message to another task's peer. Every message goes through the sluice's filter,
is signed, and is sent or held. **`prompt` is the default moderation**, so by default nothing
leaves the machine until a person has released it: a fresh mailbox holds every outgoing message,
and the sender is told in its own inbox that it waits. **An empty hold list is the unusual state.**

## What must be true

**A person sees every message that is waiting for them, reads it, and releases or refuses it; sees
whom each task may talk to and how that is moderated; and can say something to a task the same way
an agent would.**

## Acceptance

- **What is held is where "Needs you" is**, counted and never buried: each held message names its
  task, its peer and why it is held (moderation, the day's budget with that peer, the filter).
  **Both directions**: a message *from* an `external` peer is filtered on the way in and held there
  when refused, before any agent sees it (Agent Sokar, 2026-09-18) — so the list says which way each
  one was going.
- A held message is **read before it is decided**: its text is shown, and releasing or refusing it
  is a separate, deliberate act. A held message is released or refused, **never edited**. `AMBIGUOUS`
  and `NO_SUCH_MESSAGE` are said in words.
- **A message the filter refused is never shown by its text**, only by the filter's answer: the
  rules it broke, where, and a masked excerpt. Its original may hold a secret, and reading it through
  a forwarded socket would be it leaving the machine after all (Agent Sluice, 2026-09-18). Only a
  message that passed the filter and waits is read in full.
- Per task, its peers: name, trust, the day's budget used in both directions (`perDay`), the
  moderation mode, and whether anything to that peer is held right now. **A peer is never shown as
  available while every message to it waits.**
- The mode is changed per peer (`prompt`, `allow`, `deny`, `off`). **`off` is described as what it is**:
  nothing is asked, and the filter still runs; nothing in this interface turns the filter off. A
  refusal for `allow` or `off` outside an `online` project shows the daemon's message, which names
  `unread_work_may_leave`.
- A person can write to a task (`Say`); the answer says **written**, never *sent*, because it goes
  through the same filter and moderation as an agent's message.
- What happened to messages is followed live from `Talk` (`taken`, `queued`, `sent`, `deferred`,
  `held`, `delivered`, `duplicate`), filtered here per task and project. The stream carries no text,
  so nothing refused is ever copied onto the screen by it.

## What the backend is short of

- **Sokar B14** on `Tasks1`: `Peers`, `Talk`, `Say`, `Release`, `Moderate`.
- **A held message's text over the socket** (QS8, answered yes): the interface usually reaches a
  machine through a forwarded socket, where the mailbox directory is on the other side and out of
  reach. Without it a person would release a message unread.
- **Declaring a peer, and `unread_work_may_leave`, through the socket** (QF17): a project's peers
  (`mail.peers.<name>` with address, trust and `per_day`) live in its project file, and neither
  `CreateProject` nor `Moderate` can write them. Until there is a way, peers are declared at the
  machine and this interface shows and moderates them.

## To be checked

- **Where peers are declared from here**, once QF17 is answered: at project creation, in the
  project's configuration, or both. Creating a project asks what it needs to start; a peer can be
  added later, so the configuration is the likelier home.
