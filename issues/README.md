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
| [F38](F38-Enroll-This-Device-To-Open-The-Vault.md) | **blocked** | Sokar B60 | A person can make this interface a device that opens a machine's vault, with a share kept in the platform's keystore and sent once under a chosen name. **Built against the proposal**: "Enroll this device" beside the lock in the machine's title, the key in the platform's keystore. | 1 | a method to enroll a device with a share, a name and a declared storage class |
| [F39](F39-Unlock-The-Vault-With-An-Enrolled-Device.md) | **blocked** | Sokar B60 | Where a vault is locked and this device is enrolled, the interface opens it for a bounded time with one action, without anybody typing anything. **Built against the proposal**: the lock in the machine's title. | 0 | a method to unlock with a share for a bounded session |
| [F40](F40-See-And-Revoke-The-Devices-That-Open-The-Vault.md) | **blocked** | Sokar B60 | A person can see every device that can open a machine's vault, take one away, and is told what remains. **Built against the proposal.** | 1 | methods to list keyslots and to revoke one by id |
| [F41](F41-Say-What-A-Devices-Key-Storage-Is-Worth.md) | **blocked** | Sokar B60 | Everywhere a device is shown, the interface says what its share's storage protects against, from what the device declared. **Built against the proposal.** | 1 | the declared storage class, recorded with the keyslot and returned in the list |
| [F42](F42-Moderate-What-Work-Says-To-Other-Work.md) | **blocked** | Sokar B14 | A person sees every message waiting for them, reads it, and releases or refuses it; sees whom each task may talk to and how that is moderated; and can say something to a task. | 1 | B14's five methods on `Tasks1`, a held message's text (QS8), and a way to declare a peer (QF17) |
| [F43](F43-Set-Up-A-New-Machine-From-The-Interface.md) | **blocked** in part | Sokar B62 | A person adds a machine through a wizard starting from what they have — a forwarded socket, a host to forward to, or a machine just rented, which it prepares end to end with root used once and every command shown first. | 1 | a setup script per operating system, published beside the packages (QF18); the first two kinds need nothing |
| [F45](F45-A-Git-Credential-For-The-Machine.md) | **blocked** | Agent Sokar's answer to QF40 | A person gives a machine the credential its work uses for git — an assigned ssh key or a personal access token — from the machine wizard or its menu, sent over ssh and never kept here. | 1 | where a git credential for following lives, its name and the command that stores it; whether a follow fetches over https with a token |
| [F31](F31-A-Consent-Granted-Once-Outside-The-Interface.md) | **blocked** | Sokar B31 | When a machine needs a person to grant an authorization in a browser, the link is shown whole, opened on request, and waited for visibly. | 1 | the whole flow: no method or event for a pending consent |
| [F32](F32-The-Ranked-Review-Of-What-Got-Through.md) | **blocked** | Sokar B38 | What got through is shown most far-reaching first, each entry saying how far it can get. | 1 | the ranking itself |
| [F37](F37-Reach-A-Machine-Without-An-ssh-Binary.md) | open — not decided | the operator's decision on a mobile client | The interface reaches a machine through `ssh` where there is one and `dartssh2` where there is not, trusted and supervised to the same standard. | 4 | nothing: `direct-streamlocal` forwarding reaches the daemon's socket as it is |
| [F15](F15-Secret-Store-Control.md) | **blocked** | Sokar B60 | The protected store's state is visible and changeable, and its recovery secret is revealed once and acknowledged. | 0 | the unlock through an enrolled device (F39). Everything else is met, at the machine or here, or refused on purpose: revealing a recovery secret will **never** be possible here |

## What was decided

Choices that shape this set rather than sit in it — including the two that removed a requirement
instead of building it — are in [doc/decisions.md](../doc/decisions.md), newest first.
