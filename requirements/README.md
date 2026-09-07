# Frontend Requirements

The interface people use to work with a Sokar backend, described as what must be true for a
person using it — not how it is built. One file per requirement, each carrying its own
acceptance criteria so it can be judged done or not done.

**Open question** means the file ends with a *To be checked* section: something
unresolved whose answer changes what the requirement can promise.

Files here are numbered with an `F` prefix; the number is identity, not order. The
order to build them in is the table below.

**This is the whole of the interface.** It lives in this repository rather than in
[sokar](https://github.com/fuinorg/sokar) so it can be worked on independently; that repository's
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

**[What the contract does not yet cover](../doc/Contract-Gaps.md).** Roughly half of this set
cannot be finished today, because the backend has no method behind it — and which half is not
obvious from reading a requirement. The **Backend** column below is the summary; that file is the
detail and the reasoning. A convincing screen with no method behind it is the most expensive kind
of wasted work, because it looks finished.

## Work, in the order to do it

The first group is the frame. Nothing else can be judged until a person can find their
way around, so it comes first even though it delivers no capability on its own. The
second group is the daily loop — start work, watch it, get its output out — which is
what the interface is for. The third is the standing configuration people touch
weekly rather than hourly. The last is the safety surface, which is last only because
it is judged against the rest, not because it matters least.

| # | Requirement | What must be true | Backend | Open question |
|---|---|---|---|---|
| F01 | [Application Shell](F01-Application-Shell.md) | Projects and their work are two selections apart, every action is reachable by keyboard, and one command finder names everything the product can do. | **partial** | |
| F02 | [Project Overview](F02-Project-Overview.md) | Every project on the machine is listed with enough state to decide whether it needs attention, without opening it. | **partial** | |
| F13 | [Operation Feedback And History](F13-Operation-Feedback-And-History.md) | Long operations never block or disturb the interface, and every one started in a session can be reopened with its output. | **partial** | |
| F08 | [Task Creation And Modes](F08-Task-Creation-And-Modes.md) | Work is started with a project, an agent and a mode, and finished unattended work can be continued with a new prompt. | ready | |
| F09 | [Task Control](F09-Task-Control.md) | Running work can be stopped, restarted, recreated, renamed and deleted, each named by its consequence. | ready | |
| F11 | [Live Log Viewing](F11-Live-Log-Viewing.md) | Everything work produces is readable inside the interface, live, with structure visible. | ready | |
| F10 | [Task Inspection And Work Handover](F10-Task-Inspection-And-Work-Handover.md) | What a piece of work is and what it did to the repository is visible, and its changes leave the interface in one action. | **partial** | |
| F12 | [Interactive Session Attach](F12-Interactive-Session-Attach.md) | An interactive session is one action away, and the way back is reliable. | **blocked** | |
| F03 | [Project Environment Preparation](F03-Project-Environment-Preparation.md) | A project is made runnable from the interface, with rebuild depths distinguished by what each replaces and what it costs. | **blocked** | |
| F04 | [Guided Project Creation](F04-Guided-Project-Creation.md) | A new project is described, checked, reviewed and created without leaving the interface. | **blocked** | |
| F05 | [Project Configuration](F05-Project-Configuration.md) | Agents, hardware and reachable destinations are set per project, with open-ended and explicit selections never confused. | **partial** | |
| F07 | [Instruction Management](F07-Instruction-Management.md) | Standing instructions are editable at both levels, and the combined result is viewable before anything runs. | **blocked** | |
| F06 | [Upstream Synchronisation And Backups](F06-Upstream-Synchronisation-And-Backups.md) | Falling behind the upstream is visible, syncing is one action, and snapshots can be listed, restored and deleted. | **blocked** | |
| F14 | [Authentication Flows](F14-Authentication-Flows.md) | Agents and providers are authenticated from the interface without a secret ever being displayed or logged. | **blocked** | |
| F15 | [Secret Store Control](F15-Secret-Store-Control.md) | The protected store's state is visible and changeable, and its recovery secret is revealed once and acknowledged. | **partial** | |
| F16 | [Access Key Routing](F16-Access-Key-Routing.md) | Which keys reach which projects is answerable in both directions from one view, and editable there. | **blocked** | |
| F17 | [Network Exposure Control](F17-Network-Exposure-Control.md) | What running work may reach is changeable while it runs, and refusals are watchable and answerable live. | **partial** | |
| F19 | [Host Readiness And Remediation](F19-Host-Readiness-And-Remediation.md) | The interface establishes whether the machine can run anything and offers the fix in place. | **blocked** | |
| F18 | [Emergency Stop](F18-Emergency-Stop.md) | One always-visible action cuts every form of access at once and says what state it left behind. | **blocked** | |
| F21 | [Continuity And Updates](F21-Continuity-And-Updates.md) | Closing, reopening or updating the interface never disturbs running work. | ready | |
| F26 | [Linux Packaging](F26-Linux-Packaging.md) | The interface installs from apt and dnf out of the same repository as the backend, and appears in the application menu. | yes| n/a | |
| F20 | [Access From Elsewhere](F20-Access-From-Elsewhere.md) | Another machine's Sokar is reached over a forwarded socket, and which host an action will act on is never ambiguous. | yes| ready | |
| F27 | [Managed Tunnels](F27-Managed-Tunnels.md) | A host is described by where it is, and the interface raises the forward itself — without becoming the only way to reach a machine. | ready | **open question** |
| F22 | [Task State Visibility](F22-Task-State-Visibility.md) | Working, idle and waiting are told apart, with a timestamp, for every piece of work at once. | yes| **blocked** | |
| F23 | [Notifications](F23-Notifications.md) | A decision waiting inside a closed window still reaches the person. | yes| ready | |
| F24 | [Agent Inventory](F24-Agent-Inventory.md) | What is installed, what it may reach and which build it pins are all visible, and nothing names a specific agent. | ready | |
| F25 | [Task Templates](F25-Task-Templates.md) | A recurring job is startable by name, and a template can never widen what work may reach. | ready | |

## To be checked

One open question, and it is about scope rather than detail: whether the actions that
hand off to something local — attaching to a session, opening an editor, putting
changes on the clipboard — can be honoured from another device at all
([F20](F20-Access-From-Elsewhere.md)). If they cannot, the remote view is a monitoring
and decision surface rather than a full one, and that is worth deciding before it is
built rather than discovering afterwards.

## What was settled

**No browser.** The interface is a Flutter application talking to a unix socket, and reaching a
remote Sokar is an SSH socket forward rather than a server. This was the only requirement in the
set that would have forced the daemon to bind a network interface, and dropping it is what keeps
local and remote the same code. [F20](F20-Access-From-Elsewhere.md) records the measurement.
