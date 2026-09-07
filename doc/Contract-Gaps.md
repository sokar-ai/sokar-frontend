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

## A project is a name here and a path there

**Read this before the table.** It is the single largest gap and it does not look like one,
because every method involved exists.

`Task.project` is a **name** — the string a task recorded for itself. Every method that takes a
project takes a **path to its file**: `Start(project:)` is *"path to the project file, as the CLI
takes it"*, and `Pending`, `Review`, `Approve` and `Reject` all say the same. **Nothing maps one
to the other, and nothing lists the projects on the machine.**

So an interface knows that a task belongs to `checkout` and has no way to name `checkout` to any
method that would act on it. Everything below marked *needs a project path* is blocked on this one
thing, and one method — list the projects with their paths — unblocks all of it at once. It is the
first thing to ask for, ahead of everything in the blocked table.

## Ready — the contract covers these

| | Uses |
|---|---|
| F20 Access From Elsewhere | transport only — a socket path |
| F21 Continuity And Updates | `GetInfo`; reconnection is the client's own |
| F23 Notifications | `Prompts`, including the verdict that says one expired |
| F24 Agent Inventory | `Agents`, with its `failures` map |

## Partly ready — build the covered half, stop at the line

Four of these were listed as *ready* until 2026-09-07, when they were walked against the IDL
method by method rather than by name. Starting is one call, so F08 read as covered; the call has
no parameter for two thirds of what the requirement asks for. **Checking that a method exists is
not checking that it answers the requirement.**

- **F08 Task Creation And Modes** — `Start` takes a name and an agent, and streams the build.
  Everything else it asks for is missing: there is **no `mode` parameter**, so "driving it
  interactively, a richer session, or unattended" cannot be offered; **no `prompt` parameter**, so
  an unattended run cannot collect one, nothing retains one, and finished work cannot be continued
  with a new one; and it *needs a project path*, so which project to start in is unanswerable.
  What is left is: start a task, in whatever project the daemon defaults to, with a name and an
  agent.
- **F09 Task Control** — `Stop` and `Resume` are complete, take a container name rather than a
  path, and the full `Outcome` set is there including the `HOLDS_WORK` refusal. **Renaming has no
  method at all.** Recreating is `Stop` then `Start`, so it *needs a project path*.
- **F10 Task Inspection And Work Handover** — every gate method *needs a project path*. The
  inspection half reads off `Task`; the handover half — the part the requirement is named for —
  cannot be reached from a task at all.
- **F11 Live Log Viewing** — `Tail` follows a log, and the name *"is checked against the files
  that are there rather than resolved as a path"* — but **nothing lists what those files are**. An
  interface can follow a log it can already name and cannot show a person what work produced.
- **F25 Task Templates** — `Start` with fixed parameters, and *needs a project path* for the same
  reason F08 does.

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
- **F17 Network Exposure Control** — `Prompts` and `Decide` do the live half completely.
  *"Changeable while it runs"* has no method.

## Blocked — no method at all

| | Needs |
|---|---|
| F02 Project Overview | list the projects on the machine. Projects only exist today as a *field on a task*, so a project with no tasks is invisible |
| F03 Project Environment Preparation | rebuild, at distinguishable depths |
| F04 Guided Project Creation | create a project |
| F05 Project Configuration | read and write agents, hardware, egress; delete a project |
| F06 Upstream Synchronisation And Backups | sync, list snapshots, restore, delete |
| F07 Instruction Management | read and write instructions at both levels, and show the resolved result |
| F12 Interactive Session Attach | attach to a running task. `Start` has only the no-attach path |
| F14 Authentication Flows | authenticate an agent or a provider. `Credentials` is read-only |
| F16 Access Key Routing | create, remove and link keys |
| F18 Emergency Stop | cut every form of access at once |
| F19 Host Readiness And Remediation | run the readiness check and act on it |

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
