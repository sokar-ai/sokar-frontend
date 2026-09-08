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

**The last column says what the backend is short of**, not merely that something is. A row with
nothing in it can be built today. Anything named there is a method or a field that does not exist
yet, or exists and is not built here yet; [what the contract does not yet
cover](../doc/Contract-Gaps.md) has the reasoning behind each.

| # | Requirement | What must be true | What is still missing | Open question |
|---|---|---|---|---|
| F10 | [Task Inspection And Work Handover](F10-Task-Inspection-And-Work-Handover.md) | What a piece of work is and what it did to the repository is visible, and its changes leave the interface in one action. | | |
| F03 | [Project Environment Preparation](F03-Project-Environment-Preparation.md) | A project is made runnable from the interface, with rebuild depths distinguished by what each replaces and what it costs. | rebuild, at depths distinguishable by what each replaces | |
| F04 | [Guided Project Creation](F04-Guided-Project-Creation.md) | A new project is described, checked, reviewed and created without leaving the interface. | create a project | |
| F07 | [Instruction Management](F07-Instruction-Management.md) | Standing instructions are editable at both levels, and the combined result is viewable before anything runs. | read and write instructions at both levels, and show the resolved result | |
| F06 | [Upstream Synchronisation And Backups](F06-Upstream-Synchronisation-And-Backups.md) | Falling behind the upstream is visible, syncing is one action, and snapshots can be listed, restored and deleted. | sync, list snapshots, restore, delete | |
| F14 | [Authentication Flows](F14-Authentication-Flows.md) | Agents and providers are authenticated from the interface without a secret ever being displayed or logged. | authenticate an agent or a provider. `Credentials` is read-only | |
| F15 | [Secret Store Control](F15-Secret-Store-Control.md) | The protected store's state is visible and changeable, and its recovery secret is revealed once and acknowledged. | a bounded unlock and changing the passphrase, both **at the machine**. Unlocking and revealing a recovery secret will **never** be possible here, by design — the requirement says which is which | |
| F16 | [Access Key Routing](F16-Access-Key-Routing.md) | Which keys reach which projects is answerable in both directions from one view, and editable there. | create, remove and link keys | |
| F17 | [Network Exposure Control](F17-Network-Exposure-Control.md) | What running work may reach is changeable while it runs, and refusals are watchable and answerable live. | turn enforcement off on a task that is already running | |
| F19 | [Host Readiness And Remediation](F19-Host-Readiness-And-Remediation.md) | The interface establishes whether the machine can run anything and offers the fix in place. | run the readiness check and act on it | |
| F21 | [Continuity And Updates](F21-Continuity-And-Updates.md) | Closing, reopening or updating the interface never disturbs running work. | | |
| F26 | [Linux Packaging](F26-Linux-Packaging.md) | The interface installs from apt and dnf out of the same repository as the backend, and appears in the application menu. | | |


## What was here and is finished

These requirements have been met and retired. Their files are gone; the scenarios that guard them
are still in `test/features`, and what each measured is in [AGENT.md](../AGENT.md), where it will
be read again.

- **F01 Application Shell.** One window: a rail saying where you are, a menu bar saying what can be
  done, and a command finder for finding one quickly — three surfaces reading one list of actions,
  so an action added once turns up in all three. The frame taught two things it did not have to:
  that *"a pointer is optional everywhere"* is a requirement on the pointer and not only on the
  keyboard, and that every widget test was silently sized as a narrow window until the view was
  set in logical pixels.
- **F27 Managed Tunnels.** A machine described by where it is, with the forward raised here,
  supervised, and taken down when the window closes — beside the older kind, a socket somebody
  else forwarded, which is opened exactly as it always was and never touched. Its three open
  questions were settled by one decision: `BatchMode=yes`, so `ssh` fails rather than prompting
  for anything this window has no terminal to take, and its sentence is what gets shown. Two
  things it measured: `ssh` can exit before a stderr subscription has delivered the one sentence
  worth having, and waiting for the endpoint to *exist* makes any leftover file read as a working
  tunnel.
- **F09 Task Control.** Work stopped, restarted, recreated and deleted, each named by its
  consequence, each reporting its outcome, and an action the state does not allow shown as
  unavailable rather than failing when it is chosen. Two things it settled. *Renamed* was the
  wrong word: a task's name is its identity in four places — the container, the gate ref, the
  workspace, the log files — so what the criterion wanted was a **caption beside the identity**,
  and Sokar proved the difference by mutating the code to write one into the branch field, a
  rename by the back door. And **recreating is two calls where the first can refuse**: `Stop`
  answers `HOLDS_WORK` for commits that never reached the gate, and starting after a refused stop
  would leave two containers and lose the reason.
- **F08 Task Creation And Modes.** Work started with a name, an agent and one of three modes
  with nothing preselected; a prompt belongs to `UNATTENDED` alone and is never sent with another
  mode even if it was typed first; a finished unattended run continued with its old prompt in the
  box. Its last criterion was the one that taught the most: **which credential a run needs cannot
  be assembled by a client** — it turns on what the vault already holds, and a field on `Agent`
  would have reported a credential missing from precisely the vaults that have one. Asked as a
  method instead, and the three outcomes that mean different actions are kept apart on screen.
- **F18 Emergency Stop.** One action on the status line that stops every piece of work at once,
  reachable by name and by key, previewed before it acts, with leaving as the default. What it
  reports is **what survived** — Panic stops and never removes — and a helper that outlived its
  stop is named rather than counted, because somebody has to kill it by hand. Its narrow-window
  behaviour was found by a scenario, not by looking: adding the button overflowed the status line
  on a compact window, where an emergency stop falling off the edge is missing exactly when
  somebody reaches for it. A task already stopped is absent from the answer, so it says *"the 3
  that were running"* and never *"3 of 7"* — a total this call never saw.
- **F02 Project Overview.** Every project on the machine with enough on the row to decide whether
  it needs attention: what it is, whether its environment is prepared, how much work it has, how
  much is waiting at the gate, and how far behind its upstream it has fallen — **with the age of
  that measurement in the same sentence**, because a number without one has to be drawn as though
  it were current. It taught two things. *"The list reflects what changed elsewhere"* was not true:
  the work pane updated on a `Watch` push and the row above it kept stale counts, because there is
  no `WatchProjects` and nothing re-asked. And `behind` is meaningless unless `behindReason` says
  `MEASURED` — every other reason reports zero, and zero would otherwise read as *up to date*.
- **F24 Agent Inventory.** What a machine has to run agents with, in three lists — what it can
  use, what is installed and unusable, and what is installed and permanently hidden by another
  copy. It taught two things. `Agent.version` is the build an agent *pins*, from its own manifest,
  and the contract described it as what the binary reports, which is how it was recorded as a gap
  when it was the answer. And a digest is per artifact, not per agent, with exactly two states —
  verified, or unverified with a stated reason — because the daemon refuses to build one with
  neither. Its worst moment was ours: a view was built to mark two agents sharing a name, the
  fixtures were edited so it had something to show, and six scenarios passed on a state the
  contract cannot produce.
- **F05 Project Configuration.** What a project's work may reach, where each host came from, what
  is asked for and refused, and the sets installed here — changed behind a preview, with the
  **open-ended half deliberately absent**: `SetEgress` takes an explicit list so a set shipped in
  a later release cannot widen a project nobody edited, and the interface says that where somebody
  would look for it rather than only leaving it out.

  Two of its criteria were **reworded rather than met**, and both are settled as *never*: a
  project has no agent roster — the bound is its class and its egress, not a list of names, and
  what installing an agent really widens is answered by visibility, since the start report names
  the origin of every host — and a project cannot ask for hardware, because **a device node is a
  hole in the container of exactly the kind this product is built around not having**, with
  nothing to mediate, nothing to record and nothing to interrupt.

  Deleting came last, as `DeleteProject` on 2026-09-08, and its shape is the lesson: **it removes
  what Sokar built and says so, never *"deletes the project"***. The `keeps` field exists because
  this end said it would have listed `project.yml` among the casualties and believed it — so the
  contract names what survives, and afterwards a task run in that directory builds all of it
  again. It **refuses rather than decides**, on two things that are not the same weight: a running
  task is work cut off mid-flight, and an unreviewed push is in the mirror and nowhere else.

- **F25 Task Templates.** A job named from the start dialog once its choices are made, which
  becomes an action of its own — in the finder, the menu bar and anywhere else the command list is
  read — and starts in one action with its prompt editable before it runs. The criterion with
  teeth is met by **what a template cannot carry**: `clearance` and `noGate` are not fields on
  one, so a job named last month cannot be running today with the gate off, and reading one names
  its fields rather than copying a map.

  Its fourth criterion — *shared with the project* — was answered **no** by the operator, and the
  reason is worth keeping: **a project file describes constraints, not instructions.** Everything
  in it is a bound; a prompt is what a model is *told to do*, and an instruction in a committed
  file arrives with the repository, where whoever can commit could put words in front of an agent
  somebody else starts. Sharing is not this product's problem: a team that wants the same named
  jobs keeps them in a repository of their own. The word *"recurring job"* was ours and it was
  wrong — it reads as recurring on its own, and it sent the backend answering a question about
  schedulers that nobody had asked.

- **F12 Interactive Session Attach.** A shell inside running work, drawn in this window, one
  action from where the work is listed — several at once, each named by its task and its machine,
  and the way back is the frame's own: leaving returns to the same place with the same selection.
  Asked for as
  [B16](https://github.com/fuinorg/sokar/blob/main/requirements/base/B16-Working-Inside-A-Running-Container.md)
  and designed there: **varlink cannot carry a session** — one call in, many replies out — so the
  session is a **pty running `sokar task attach`**, over ssh for a machine that needs one and here
  for a machine that does not. Sokar's own verb rather than the runtime's, so this end never
  learns which runtime is underneath and the daemon can still refuse and record.

  Three things it taught. **`Escape` was being taken from the far end**: the frame holds the
  keyboard for whatever is open, which costs a view that is only read nothing and would have made
  `vim` unusable in a session — the terminal now holds that focus node itself. **The frame
  branches on the width under the rail, not the window's**, so a 1400-pixel window is not a wide
  one. And a scenario about work that is not running **passed with the running check deleted**,
  because the task it used was agent-driven as well; the check is now measured against work whose
  mode nothing recorded, where nothing else can take the action away.

- **F11 Live Log Viewing.** A task's logs are asked for rather than guessed, followed as they are
  written, and suspended without losing what arrives meanwhile. ANSI color is honored by meaning
  rather than by value, so red is the theme's red and stays legible on both appearances.
- **F13 Operation Feedback And History.** A long operation is owned by the session, never by the
  view showing it, so leaving a build does not stop it and arriving late does not mean having
  missed the output. Failure is reported where success would have been.
- **F20 Access From Elsewhere.** Every configured machine is connected at once and one is acted
  on, because a clearance question has a deadline and a machine nobody watches is one whose work
  expires unseen. Which machine an action lands on is pinned above the rail rather than nested in
  a tree, where it could scroll out of view. Raising the tunnel is [F27](F27-Managed-Tunnels.md).
- **F22 Task State Visibility.** Working, idle, waiting and dead, beside the runtime's own words
  and never instead of them, with *"idle for forty minutes"* as arithmetic on a timestamp. Asked
  for as [B11](https://github.com/fuinorg/sokar/blob/main/requirements/base/B11-What-A-Task-Says-About-Itself.md)
  and answered the same day. One thing it deliberately does **not** do: `WAITING` covers clearance
  questions only, so an agent asking its own question reads as `UNKNOWN` or `IDLE`, and labeling
  either as *probably waiting* is the guess the field exists to avoid.

- **F23 Notifications.** A decision waiting inside a window nobody has open reaches the person
  anyway, and finishing does too — told apart from failing for whatever the session started, which
  is as far as it can honestly go, because `activity` says `DEAD` for stopped, finished and killed
  alike. Its open question is answered rather than dropped: the transport has no channel that
  survives the *application* closing, so what is delivered is a closed **window**, on the desktop
  the interface is running on, for every machine it watches. A desktop that cannot notify says so.

## To be checked

One open question, and it is about scope rather than detail: whether the actions that
hand off to something local — attaching to a session, opening an editor, putting
changes on the clipboard — can be honored from another device at all
([F20](F20-Access-From-Elsewhere.md)). If they cannot, the remote view is a monitoring
and decision surface rather than a full one, and that is worth deciding before it is
built rather than discovering afterwards.

## What was settled

**No browser.** The interface is a Flutter application talking to a unix socket, and reaching a
remote Sokar is an SSH socket forward rather than a server. This was the only requirement in the
set that would have forced the daemon to bind a network interface, and dropping it is what keeps
local and remote the same code. [F20](F20-Access-From-Elsewhere.md) records the measurement.
