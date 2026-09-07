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
| F24 Agent Inventory | `Agents`, with its `failures` map |

## Partly ready — build the covered half, stop at the line

- **F02 Project Overview** — `Projects()` answers the name, the security class, how much work it
  has, how many pushes wait for review, and whether it can be acted on at all. Two of its criteria
  still have nothing behind them: **whether a project's environment is prepared and usable**, and
  **whether its copy of the upstream has fallen behind, and by how much**. Both would be fields on
  `Project`, which is the cheap kind of change. Ask.

Four of these were listed as *ready* until 2026-09-07, when they were walked against the IDL
method by method rather than by name. Starting is one call, so F08 read as covered; the call has
no parameter for two thirds of what the requirement asks for. **Checking that a method exists is
not checking that it answers the requirement.**

- **F08 Task Creation And Modes** — which project to start in is answerable now, from
  `Project.file`. What is still missing is what the requirement is named for: there is **no `mode`
  parameter**, so "driving it interactively, a richer session, or unattended" cannot be offered,
  and **no `prompt` parameter**, so an unattended run cannot collect one, nothing retains one, and
  finished work cannot be continued with a new one. Worth asking for.
- **F09 Task Control** — **built**, except that **renaming has no method at all**. Recreating is
  `Stop` then `Start`, which `Project.file` now makes possible; it is unbuilt rather than blocked.
- **F10 Task Inspection And Work Handover** — **unblocked and unbuilt.** `Project.file` is what
  `Pending`, `Review`, `Approve` and `Reject` want, and `Project.pending` already says how many
  are waiting. Nothing is missing from the contract here any more.
- ~~**F11 Live Log Viewing**~~ — **built.** `Logs` landed on 2026-09-07, the same day it was
  asked for, so a task's logs are listed rather than typed. Nothing here holds a set of log names:
  which files exist depends on what the task started, and a client that knew them would offer one
  that was never going to exist and would never show one a later release adds.
- **F25 Task Templates** — `Start` with fixed parameters. Nothing missing from the contract.

- **F01 Application Shell** — `List`, `Watch` and `Agents` carry the frame. The command finder
  cannot yet "name everything the product can do", because a third of it has no method.
- ~~**F13 Operation Feedback And History**~~ — **built.** The gap was read too widely: *"every
  operation started in a session"* is scoped to the window that started it, and the interface can
  hold what it was streamed for as long as that window is open, which is what `Operations` does.
  What genuinely has no method is reopening the output of an operation started *before* this
  window, or by something else — no requirement asks for that today. Nothing here needs the
  backend to persist anything.
- **F15 Secret Store Control** — `Credentials` reports the store's state, and `readable` already
  separates "locked" from "empty". Nothing can *change* it: the contract has no vault-mutating
  method at all. Sokar's CLI has `sokar vault lock`, which is **not** a way round this — shelling
  out is forbidden, and it is forbidden hardest here. A lock control needs a `Lock` method added
  on the Sokar side; confirmed 2026-09-07 that it will be, if asked for.
- **F17 Network Exposure Control** — `Prompts` and `Decide` do the live half completely, and
  `Egress`/`SetEgress` arrived on 2026-09-07 for the standing half. One line stays: **nothing here
  reaches a running task**, because a container's ruleset and resolver are built when it starts.
  Say *"applies to the next task"* wherever a successful change is shown; do not imply otherwise.
- **F05 Project Configuration** — egress is on the wire (`Egress`, `SetEgress`). Agents, hardware
  and deleting a project are not.

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

### What is still worth asking for

- **`Sets()`** — nothing lists the installed egress sets, so a chooser cannot be offered and a
  name has to be typed, refused with `NO_SUCH_SET` when the machine does not have it. The Sokar
  side has offered to add one; **it is wanted**, for the same reason `Logs` was: a client that
  held the names would offer a set this machine does not have.
- **`mode` and `prompt` on `Start`** — two thirds of F08 is unreachable without them.
- **`Project` fields for whether the environment is prepared and how far the upstream has drifted**
  — the last two facts F02 asks for.
- **Renaming a task**, which F09 asks for and nothing can do.
- **A method behind `sokar panic`**, which F18 needs and may not shell out for.

### F22 is a different kind of gap

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
