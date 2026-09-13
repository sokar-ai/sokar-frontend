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
says whose answer it waits for, and **Blocked by** names it — a Sokar number, or a decision when
the answer is nobody's work but the operator's — so a dependency reads the same from both ends as
Sokar's own *Blocks* column. **A finished issue is deleted, file and row together** — this
index holds what is still to do and nothing else, so there is no status for *met*. A row that is built and still carries open questions stays until
they are answered or moved into an issue of their own; what it measured is written down before the
file goes, in [AGENTS.md](../AGENTS.md) or in one of the documents under `doc/`.

| # | Status | Blocked by | What must be true | Open questions | What the backend is short of |
|---|---|---|---|---|---|
| [F33](F33-Stop-The-Daemon-On-A-Machine-You-Can-Reach.md) | **blocked** | Sokar B54 | A person can stop the daemon on a machine reached over ssh, told first exactly what stopping costs. | 1 | a stop that leaves the tasks it started running, and a way to know which running tasks a stop would affect |
| [F31](F31-A-Consent-Granted-Once-Outside-The-Interface.md) | **blocked** | Sokar B31 | When a machine needs a person to grant an authorization in a browser, the link is shown whole, opened on request, and waited for visibly. | 1 | the whole flow: no method or event for a pending consent |
| [F32](F32-The-Ranked-Review-Of-What-Got-Through.md) | **blocked** | Sokar B38 | What got through is shown most far-reaching first, each entry saying how far it can get. | 1 | the ranking itself |
| [F15](F15-Secret-Store-Control.md) | **blocked** | the operator's parked decision | The protected store's state is visible and changeable, and its recovery secret is revealed once and acknowledged. | 0 | nothing at the machine: `sokar vault unlock --for <duration>` and `sokar vault passphrase` both exist. What is parked is whether unlocking could ever be a daemon method; revealing a recovery secret will **never** be possible here |

## What was decided

Choices that shape this set rather than sit in it — including the two that removed a requirement
instead of building it — are in [doc/decisions.md](../doc/decisions.md), newest first.
