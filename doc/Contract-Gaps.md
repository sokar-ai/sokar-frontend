# What the contract does not yet cover

`org.fuin.sokar.Tasks1` has fourteen methods. The requirements need more than fourteen things.
This is the map of which is which, worked out by walking every acceptance criterion against the
contract, and it exists so the interface is not built twice: once against assumptions, then again
when a method turns out not to exist.

**Read this before picking up a requirement.** Roughly half the set cannot be finished today, and
which half is not obvious from reading the requirements alone.

## The rule that makes these real gaps

Two shortcuts suggest themselves and neither works.

**Shelling out to the `sokar` CLI is forbidden.** `sokar doctor` and `sokar panic` exist, so F18
and F19 look reachable. They are not: an interface that ran the CLI and parsed its output would
be a second implementation of every refusal the product makes, and those refusals are the
product. That rule is in [AGENT.md](../AGENT.md) and it is not softened by a method being
missing.

**Reading and writing files directly is worse.** F04–F07 are all "edit something that lives in a
file", and a client could open `project.yml` itself. That breaks the moment the daemon is
remote: over an SSH-forwarded socket the client has no filesystem on that machine at all. The
transport decision in [F20](../requirements/F20-Access-From-Elsewhere.md) quietly made *the API
is the only way in* a hard constraint rather than a preference.

So a gap here is a backend method that has to be added, not a workaround waiting to be found.

## A project used to be a name here and a path there

**Settled 2026-09-07.** `Projects()` answers a `Project` carrying `file` — the absolute path every
gate method and `Start` take — beside its name, security class, mirror, how many pushes wait for
review and how many tasks it has. Take `file` from there and **pass it through unchanged**: never
build one, and never offer a file picker, because over a forwarded socket there is no filesystem
on that machine to pick from.

Two things about it that are states rather than errors:

- **`file` can be empty**, meaning nothing recorded a path yet or the recorded file has moved. Such
  a project is listed and cannot be acted on; a call made with a stale path would fail in a way
  that looked like a fault in the daemon, which is why it is reported absent instead.
- **Nothing refreshes the list.** There is no `WatchProjects`, so it is asked for again after
  anything that would change it — a task started or removed, a push approved.

Asked for on the day it was needed and answered the same day, as `Logs` was. **When something is
missing, ask.**

## Ready — the contract covers these

| | Uses |
|---|---|
| F20 Access From Elsewhere | transport only — a socket path |
| F21 Continuity And Updates | `GetInfo`; reconnection is the client's own |
| F23 Notifications | `Prompts`, including the verdict that says one expired |

## Partly ready — build the covered half, stop at the line

- **F02 Project Overview** — `Projects()` answers the name, the security class, how much work it
  has, how many pushes wait for review, and whether it can be acted on at all. Two of its criteria
  still have nothing behind them: **whether a project's environment is prepared and usable**, and
  **whether its copy of the upstream has fallen behind, and by how much**. The first is being
  added as a field. The second is **not** the cheap change this file called it: the mirror is
  local and the upstream is on the network, so answering it live would make `Projects` perform a
  fetch — and `Projects` is asked again after anything that changes it. Asked for instead as a
  number *with the age of the measurement beside it*, fetched on the daemon's own schedule. A
  number with no age would have to be drawn as though it were current. Agreed on the Sokar side,
  and it comes with **a reason enumeration** rather than a bare timestamp: never checked, the
  vault was locked when the fetch was tried, or the project reaches nothing by design. The middle
  one is somebody's to fix and the other two are not, which is why they cannot be one value.

Four of these were listed as *ready* until 2026-09-07, when they were walked against the IDL
method by method rather than by name. Starting is one call, so F08 read as covered; the call has
no parameter for two thirds of what the requirement asks for. **Checking that a method exists is
not checking that it answers the requirement.**

**It happened again the same day, with F24.** It was in the *Ready* table on the strength of
`Agents` existing. Walked criterion by criterion against the `Agent` type, two of its four have
nothing behind them. Twice is a pattern, not an accident: the table above is written from method
names and the requirements are written from what a person sees.

- **F24 Agent Inventory** — every agent listed with the version it pins and where it was found,
  the hosts it needs, and the ones that could not describe themselves listed rather than left out.
  Three criteria wait on reply fields, all agreed on 2026-09-07 and all being added:
  `refusedDomains` (an agent has always declared them; they are not on the wire), the artifact list
  with per-artifact digests including the deliberately-unverified state, and which copy of a
  shadowed filename lost.
  - **`Agent.version` is the pin**, not what a binary says about itself: it comes from the agent's
    own manifest. This file said otherwise and was under-crediting the contract.
  - **`Agents` answers one entry per name.** An earlier version of the inventory detected
    duplicates and marked them; that state cannot arrive, and the fixtures had been altered to
    produce it. Removed. **A fixture that can describe what the contract cannot deliver will hide
    exactly this.**

- **F01 Application Shell** — `List`, `Watch` and `Agents` carry the frame. The command finder
  cannot yet "name everything the product can do", because a third of it has no method.
- ~~**F13 Operation Feedback And History**~~ — **built.** The gap was read too widely: *"every
  operation started in a session"* is scoped to the window that started it, and the interface can
  hold what it was streamed for as long as that window is open, which is what `Operations` does.
  What genuinely has no method is reopening the output of an operation started *before* this
  window, or by something else — no requirement asks for that today. Nothing here needs the
  backend to persist anything.
- **F15 Secret Store Control** — `Credentials` reports the store's state. `readable` **was** wrong — an
  unlocked but empty vault answered `false`, exactly as a locked one did — and was fixed the same
  day in `758969f`, before anything here consumed it. It can now be trusted: unlocked and empty is
  `true`, locked and undecryptable are `false`, and a vault that does not exist yet is readable
  and empty. `Lock` is being built. Nothing can *change* it: the contract has no vault-mutating
  method at all. Sokar's CLI has `sokar vault lock`, which is **not** a way round this — shelling
  out is forbidden, and it is forbidden hardest here. A lock control needs a `Lock` method added
  on the Sokar side; confirmed 2026-09-07 that it will be, if asked for.
- **F17 Network Exposure Control** — **five of its six criteria are built.** Blocked connections
  from every task in one view, allowed or denied from there, an expired question kept and marked,
  and — since `WidenTask` landed on 2026-09-07 — what a running task may reach changed from where
  that work is listed, without restarting it. What is left is one half of one criterion:
  - *"Turning enforcement off entirely is **possible**"* — the **marking** half is built:
    `Task.clearance` carries it and `off` is shown on the work. Turning it off is not. `Start`
    takes `clearance`, so it can be chosen when work is created — which is
    [F08](../requirements/F08-Task-Creation-And-Modes.md), still waiting on `mode` and `prompt` —
    and **nothing turns it off on a task that is already running**. `WidenTask` does not do it:
    widening grants names, and enforcement staying on is the point of it.
  - Everything `WidenTask` will not do, and deliberately: **no narrowing** (taking a grant back
    from a running container is the first thing of its kind in the product and is undecided), and
    **no sets** (a set is a name for several hosts; granting one is the same call repeated).
    Neither has a control, and neither should grow one before the backend decides.
  - `REFUSED_BY_CLASS` and `NOT_RUNNING` are both predictable from `Task`, so the action is
    offered as unavailable with the reason rather than offered and refused.
  - `NO_PROJECT_FILE` is **a partial success**: the run was widened and the file was not. It is
    shown as one. Reading it as a failure tells somebody the task still cannot reach a host it
    can, which is the wrong direction to be wrong in.

- **F05 Project Configuration** — **the destinations third is built**: what a project's work may
  reach and where each host came from, what is asked for and refused, the sets installed here, and
  changing them behind a preview. Three of its six criteria have nothing behind them, and one has
  half:
  - *"The agent roster for a project is editable"* — **no method**.
  - *"Hardware access is selectable from what the machine actually has"* — **no method**, and
    nothing lists the hardware either.
  - *"Deleting a project requires a confirmation naming what will be destroyed"* — **no method**.
  - *"…with the same 'all, including future additions' versus explicit-list distinction"* —
    **not a gap, and this file said otherwise for a while.** `SetEgress` takes an explicit list on
    purpose: an open-ended selection would let a set shipped in a later release widen a project
    nobody edited, when the operator approved *"everything that exists"* and what exists changed
    underneath them. The explicit list **is** the guarantee. The interface does not offer the
    open-ended form and now says why rather than only that it is unavailable.

## Blocked — no method at all

| | Needs |
|---|---|
| F03 Project Environment Preparation | rebuild, at distinguishable depths |
| F04 Guided Project Creation | create a project |
| F06 Upstream Synchronisation And Backups | sync, list snapshots, restore, delete |
| F07 Instruction Management | read and write instructions at both levels, and show the resolved result |
| F12 Interactive Session Attach | attach to a running task. `Start` has only the no-attach path |
| F14 Authentication Flows | authenticate an agent or a provider. `Credentials` is read-only |
| F16 Access Key Routing | create, remove and link keys |
| F18 Emergency Stop | cut every form of access at once. `sokar panic` exists **as a CLI command only** — stops every running task and its helpers, removes nothing. There is no daemon method, and shelling out for it is forbidden hardest here. Confirmed 2026-09-07 that a method would be small to add: it is the same `TaskControl.stop` the CLI already uses. Ask for it |
| F19 Host Readiness And Remediation | run the readiness check and act on it |

- **F21 Continuity And Updates** — **built**, except the half of one criterion that belongs to
  F12: *"where the environment allows work **and sessions** to outlive the window, they do"*. Work
  does and is reconnected to; a session cannot outlive anything that cannot be attached to in the
  first place.

### What is still worth asking for

- **Running an unattended task over the socket.** `Start` takes `mode` and `prompt` since
  2026-09-07 and *records* both, but does not run the agent headlessly and stream its output — it
  starts the container and returns. That is the remaining half of F08, and the Sokar side has
  offered to build it. **It is wanted.**
- **`Project` fields for whether the environment is prepared and how far the upstream has drifted**
  — the last two facts F02 asks for.
- **Renaming a task**, which F09 asks for and nothing can do.
- **A method behind `sokar panic`**, which F18 needs and may not shell out for.
- **Telling "waiting on a clearance decision" apart from "waiting on its own prompt"** — a
  per-agent capability, still open on both sides.

`Sets()` was on this list and arrived on 2026-09-07: `name`, `label`, the `domains` each grants,
and the directories searched in order. Show the domains or at least how many, because a set exists
so nobody authors host lists by hand and that only works if the name can be seen through. One
caveat came with it: `os-packages-fedora` reaches mirrors named by a mirrorlist, so hosts beyond
its list still arrive as clearance prompts — do not badge it as complete.

### F22 is built

Asked for as [B11](https://github.com/fuinorg/sokar/blob/main/requirements/base/B11-What-A-Task-Says-About-Itself.md)
and answered the same day: `Task` gained `agent`, `mode`, `prompt`, `branch`, `since`, `activity`
and `waitingFor`, and `Watch` redraws on all of them — so a task that starts waiting arrives as a
change, which it could not before, because the runtime's own words do not change when it does.

What is deliberately *not* settled, and must not be papered over: **`WAITING` covers clearance
questions only.** An agent asking its own question inside a session produces no signal Sokar can
see, so it reads `UNKNOWN` when attached and `IDLE` when quiet. Telling those apart needs a
per-agent capability and is still open.

### What was here before that

[F22](../requirements/F22-Task-State-Visibility.md) needs waiting detected from the work's own
signals, idle told apart from finished, and a timestamp so *"idle for 40 minutes"* is answerable.

`Task` carries `name`, `project`, `securityClass`, `state`, `running` and `helpers`. There is no
timestamp and no working/idle/waiting signal, and the contract explicitly says **do not parse
`state`** — it is the container runtime's own words and it is free text.

So F22 is not blocked on a missing *method*. It is blocked on missing *fields*, which under the
compatibility rules is the cheap kind of change: adding reply fields is allowed within `Tasks1`
and needs no `Tasks2`. It is the first thing to ask the backend for.

## What to do with this

- **Do not design around a gap.** A convincing screen for something with no method behind it is
  the most expensive kind of wasted work, because it looks finished.
- **Do not invent a local workaround.** See the rule above; it will not survive the first remote
  backend.
- **Raise it as a backend requirement.** These belong in the `sokar` repository's requirements,
  not here. Adding a method is additive and costs nothing under the compatibility promise, which
  is exactly why it is cheap to ask for now and expensive to ask for after several clients exist.
- **Keep this file honest.** When a method lands, move its row up. When this file is empty,
  delete it.
