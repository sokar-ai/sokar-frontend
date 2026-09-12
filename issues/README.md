# Frontend Requirements

The interface people use to work with a Sokar backend, described as what must be true for a
person using it — not how it is built. One file per requirement, each carrying its own
acceptance criteria so it can be judged done or not done.

**Open question** means the file ends with a *To be checked* section: something
unresolved whose answer changes what the requirement can promise.

Files here are numbered with an `F` prefix; the number is identity, not order. The
order to build them in is the table below.

**This is the whole of the interface.** It lives in this repository rather than in
[sokar](https://github.com/sokar-ai/sokar) so it can be worked on independently; that repository's
index carries one row pointing here. A few of these files narrow a requirement that is still
central over there, because it constrains the daemon or the domain rather than the interface;
where they do, they link to it rather than restating it.

[Design](design.md) says what the interface is built out of, and why. Everything here is built
against one interface, `org.fuin.sokar.Tasks1`, over one unix socket.
Read [Backend API](../doc/Backend-API.md) before the first line of code: it covers how to
connect locally and remotely, how the framing works, and — the part that is easy to get wrong
later and impossible to retrofit — what a client must do to keep working against a backend older
than itself.

## Before picking one up

**[What the contract does not yet cover](../doc/Contract-Gaps.md)** is the short list of what the
backend has no method or field for yet. A convincing screen with no method behind it is the most
expensive kind of wasted work, because it looks finished.

## Work, in the order to do it

The first group is the frame. Nothing else can be judged until a person can find their
way around, so it comes first even though it delivers no capability on its own. The
second group is the daily loop — start work, watch it, get its output out — which is
what the interface is for. The third is the standing configuration people touch
weekly rather than hourly. The last is the safety surface, which is last only because
it is judged against the rest, not because it matters least.

**The last column says what the backend is short of**, not merely that something is. A row with
nothing in it can be built today. Anything named there is a method or a field that does not exist
yet, or exists and is not built here yet; [what the contract does not yet
cover](../doc/Contract-Gaps.md) has the reasoning behind each. **Open questions** is the count in
that file's *To be checked* section: a number, because a requirement with three unanswered
questions is a different thing from one with none, and the difference is invisible in prose.

**The top row is what to do next.** Writing this table is part of the change that adds or closes
an issue — the operator's rule, 2026-09-12 — so a row is as true as the work it names. `blocked`
says whose answer it waits for. **A finished issue is deleted, file and row together** — this
index holds what is still to do and nothing else, so there is no status for *met*. Three of these
four are built and carry only open questions; what each of them measured is written down before the
file goes, in [AGENTS.md](../AGENTS.md) or in one of the documents under `doc/`.

| # | Status | What must be true | Open questions | What the backend is short of |
|---|---|---|---|---|
| [F15](F15-Secret-Store-Control.md) | **blocked** — waits on Sokar | The protected store's state is visible and changeable, and its recovery secret is revealed once and acknowledged. | 0 | a bounded unlock and changing the passphrase, both **at the machine**. Revealing a recovery secret will **never** be possible here; whether unlocking could be is reopened by the 2026-09-08 rule change and is asked |
| [F30](F30-Start-The-Daemon-On-A-Machine-You-Can-Reach.md) | in progress — built, questions open | A machine reached over ssh with nothing serving is offered a start, and started only when asked. | 1 | nothing since Sokar's `8de32db`: there is a `sokard` user unit. Lingering stays the operator's own decision |
| [F28](F28-One-View-Of-What-Needs-A-Person.md) | in progress — built, questions open | Opening the window answers whether anything needs a person, for every connected machine at once. | 3 | |
| [F29](F29-Try-A-Machine-Before-Watching-It.md) | in progress — built, questions open | Adding a machine can try the connection first, and says what stood in the way when it fails. | 1 | |

## What was decided

Choices that shape this set rather than sit in it — including the two that removed a requirement
instead of building it — are in [doc/decisions.md](../doc/decisions.md), newest first.
