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

- ~~**F02 Project Overview**~~ — **met.** `Projects` answers the name, the security class, how
  much work, how many pushes wait for review, whether it can be acted on at all, and — since
  2026-09-08 — `prepared` and the four behind-upstream fields.
  - **`behind` is meaningless unless `behindReason` is `MEASURED`.** Every other reason reports
    zero, and zero would otherwise read as *up to date*. `NEVER_CHECKED`, `NO_UPSTREAM`, `OFFLINE`
    and `FAILED` are four different sentences and one number.
  - **There is no `VAULT_LOCKED`.** It was predicted and withdrawn: the gate fetches with the
    machine's own git credentials, so the vault is not in that path.
  - **`behindMeasured` is not optional to show.** It is measured on the daemon's own timer
    (`SOKAR_UPSTREAM_MINUTES`, `0` disables it), never on the listing path — so the number is as
    old as the last tick, and a reader who cannot see that has to assume it is current.
  - **`prepared` is one call for the whole list**, deliberately, because `Projects` is re-asked
    after every task start and every approval.

Four of these were listed as *ready* until 2026-09-07, when they were walked against the IDL
method by method rather than by name. Starting is one call, so F08 read as covered; the call has
no parameter for two thirds of what the requirement asks for. **Checking that a method exists is
not checking that it answers the requirement.**

**It happened again the same day, with F24.** It was in the *Ready* table on the strength of
`Agents` existing. Walked criterion by criterion against the `Agent` type, two of its four have
nothing behind them. Twice is a pattern, not an accident: the table above is written from method
names and the requirements are written from what a person sees.

- ~~**F24 Agent Inventory**~~ — **met.** `refusedDomains`, the artifact list and the shadowed
  list landed on 2026-09-07, the day they were asked for.
  - **`Agent.version` is the pin**, from the agent's own manifest. The IDL described it as what
    the binary reports, which is how this file recorded it as half missing. Corrected on both
    sides — **a wrong comment in the contract cost a wrong entry here.**
  - **A digest is per artifact and has two states**, not three: verified, or unverified with a
    stated reason. The daemon's own constructor refuses one with neither, so nothing renders a
    blank with no explanation. No artifacts at all is a third honest answer about the agent, not a
    fourth state of a digest.
  - **Shadowing comes back as a list, never a flag.** A shadowed binary is never started, so it
    has no `Agent` entry to mark — which is the concrete reason the duplicate-name view here could
    not have been fed by a real daemon.

- ~~**F08 Task Creation And Modes**~~ — **met.** `Start` gained `mode` and `prompt` on 2026-09-07,
  and `CanStart` landed on 2026-09-08 to answer the sixth criterion.
  - **The credential rule is asked, never assembled.** It turns on the agent's declaration, the
    installed providers, the run's own override and **what the vault already holds**; a client has
    one of the four. A field on `Agent` would have reported a credential missing from exactly the
    vaults that have one — shown by mutation on the Sokar side rather than argued.
  - **`credential` is the key that was looked for**, not the one that ought to apply.
  - Three of the eleven outcomes are three different actions — choose a provider, store a secret,
    unlock at the machine — and confusing them sends somebody to the wrong place.
  - `Task.mode` was sending lower case against an IDL that declared the `Mode` type, and was fixed
    on the Sokar side. Nothing here changed, because this build compares against the contract's
    spelling and not against what happened to arrive.
  - `Task.mode` stays a **string**, not the type: it has a fourth state, `""`, for a task started
    before the field existed. Render the absence; never default it to `SHELL`.
- ~~**F09 Task Control**~~ — **met.** `Label` landed on 2026-09-08 and answers what the
  *renamed* criterion actually wanted: a caption **beside** the identity. Renaming would have moved
  a gate ref with unreviewed pushes behind it.
  - **Recreating is `Stop` then `Start`**, and needed no method — `Project.file` made it possible
    on 2026-09-07. The stop can refuse with `HOLDS_WORK`, and nothing is started after a refused
    stop: that would leave two containers and lose the reason.
  - `Task.label` is `""` for every task until somebody types one, which is a normal state and not
    a gap.
- **F10 Task Inspection And Work Handover** — **the join is answered, and there is a field
  instead of it.** `Task.waiting` landed on 2026-09-08: `1` when this task's own ref is waiting
  for review, `0` otherwise. The last thing a task could not say about itself is said, and no
  string is matched against another.
  - **The join would have been wrong, and not only by a prefix.** `Task.name` is a *container*
    name — `sokar-<project>-<task>-<run>` — and `PendingPush.name` is a *task* name. Two runs of
    the same task push to one ref, so no field can name *the* task that pushed it: Sokar offered
    `PendingPush.task`, went to build it, and withdrew it for that reason. **Two levels, not two
    spellings of one.**
  - **An `online` task always answers `0`, and that is not a smaller number.** Its ref is
    `refs/heads/<task>` and nothing is ever reviewed — so the tail match this end would have had
    to make would have claimed work was waiting for a task whose name merely coincided.
  - **The mirror is read once per project, not once per task**, so the field costs a listing
    nothing. Both properties are held by tests that fail if either is dropped.
- ~~**F11 Live Log Viewing**~~ — **built.** `Logs` landed on 2026-09-07, the same day it was
  asked for, so a task's logs are listed rather than typed. Nothing here holds a set of log names:
  which files exist depends on what the task started, and a client that knew them would offer one
  that was never going to exist and would never show one a later release adds.
- **F25 Task Templates** — **three of four criteria are built, and the fourth is answered *no*
  rather than left pending.** Settled on 2026-09-08: a template does not belong to a project, so
  it follows the person. Reworded, on the same terms as the roster and the hardware below.
  - **The reason is not *"there is nowhere to put one"*.** `SetEgress` edits `project.yml` in
    place, comments and all — the mechanism plainly exists. This end proposed *"a template is not
    Sokar's to put in a project file"* as a reason it would accept, and it is false; a screen
    carrying it would have contradicted the egress editor it already draws.
  - **The reason is that a job kept with a project implies a scheduler, and there is none.** Work
    starting with nobody present is what everything else here is careful about: a locked vault
    would refuse the run rather than ask anybody, a clearance question would expire unseen, and a
    failure would be found by whoever did not start it.
  - The criterion with teeth needs nothing: a template carries no `clearance` and no `noGate`,
    and the security class is unreachable because `Start` cannot set it.

- **F01 Application Shell** — `List`, `Watch` and `Agents` carry the frame. The command finder
  cannot yet "name everything the product can do", because a third of it has no method.
- ~~**F13 Operation Feedback And History**~~ — **built.** The gap was read too widely: *"every
  operation started in a session"* is scoped to the window that started it, and the interface can
  hold what it was streamed for as long as that window is open, which is what `Operations` does.
  What genuinely has no method is reopening the output of an operation started *before* this
  window, or by something else — no requirement asks for that today. Nothing here needs the
  backend to persist anything.
- **F15 Secret Store Control** — **three criteria of seven are built, and none of the other four
  is work somebody forgot.** Settled on 2026-09-08: `Unlock` will **never** exist over the socket and
  neither will revealing a recovery secret — a daemon has no terminal, and `Credentials` returns
  names, kinds and lengths and never a value, on a socket that can be forwarded. A bounded unlock
  and changing the passphrase are **coming, at the machine only**; the second does not exist in
  the CLI either today, so the honest sentence is *"nothing can do this yet"* rather than *"the
  interface cannot"*. Everything the screen can do is say **where** it happens.
  `Credentials` reports the store's state. `readable` **was** wrong — an
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
  - ~~*"The agent roster for a project is editable"*~~ — **not a gap, and now settled as never.**
    A project does not restrict which agents may run in it and will not: the bound is its
    security class and its egress, not a list of names. The one thing installing an agent really
    widens is its `allowedDomains`, added to a task's egress on top of the project's own — and the
    answer to that is **visibility rather than a list**: the start report already names the origin
    of every host, so *"which of these did the agent bring"* is answerable today. It cannot be
    refused in advance, and that is the decision rather than an omission.
  - ~~*"Hardware access is selectable"*~~ — **not a gap, and now settled as never**, with a reason
    worth putting on screen: **a device node is a hole in the container of exactly the kind this
    product is built around not having.** Everything else that reaches into a task is a unix
    socket Sokar holds and decides over — the credential broker, the git gate, the clearance
    watcher. A GPU or `/dev/kvm` is a direct kernel surface with nothing to mediate, nothing to
    record and nothing to interrupt. Rootless bounds it anyway, and it is not an egress question
    at all, so the security class says nothing about it.
  - *"Deleting a project requires a confirmation naming what will be destroyed"* — **no method
    yet, and being built**, in the shape asked for and with one addition. `DeleteProject` takes
    `dryRun` and `force` and answers `DELETED`, `PREVIEWED`, `HOLDS_WORK`, `TASKS_RUNNING`,
    `NO_SUCH_PROJECT` or `FAILED`, with `removes`, `unreviewed`, `running` — and **`keeps`**.
    - **`keeps` exists because of a sentence written here.** This end said it would have listed
      `project.yml` among the casualties and believed it, so the contract now names what
      survives: the project file is still there, and a task run in that directory builds all of
      it again. That is what makes the action safe to offer at all — so the confirmation says
      *"this removes what Sokar built for this project"*, never *"this deletes the project"*.
    - **The two refusals are not the same weight and must not read as one.** A running task is
      work cut off mid-flight, and the operator still has their repository. **An unreviewed push
      exists only in the mirror** — nothing else has it, anywhere. That one is what the whole
      confirmation is for, and `force` is what destroys it.
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
| F14 Authentication Flows | authenticate an agent or a provider. `Credentials` is read-only |
| F16 Access Key Routing | create, remove and link keys |
| F19 Host Readiness And Remediation | run the readiness check and act on it |

- ~~**F12 Interactive Session Attach**~~ — **built, and not on the socket at all.** Settled on
  2026-09-08 as B16, after the Sokar side proposed a shape and withdrew it a few minutes later;
  what is built is the second one. `sokar task attach` is committed on their side as `cd639c5`,
  and this end runs it in a pty of its own.
  - **varlink cannot carry a session, and that is measured rather than assumed.** One call in,
    many replies out: `more` streams replies *from* the service, and there is no message a client
    sends into a call already in flight. A keystroke per call was considered and rejected — calls
    are independent, so nothing orders two of them.
  - **The session is a pty running `sokar task attach <task>`** — through `ssh -t` for a machine
    this interface reaches over one, and directly for a machine whose socket is here. This end
    already holds an ssh connection and it multiplexes: the same one carries the forwarded socket
    and an exec channel. **ssh is the byte pipe varlink is not** — window size, `SIGWINCH`,
    signals, escape sequences and `TERM` all arrive correct, which is exactly what would have been
    rebuilt subtly wrong through a daemon pipe.
  - **The pty is this end's own, written against libc with `dart:ffi`.** Not a plugin: a native
    plugin is another `.so` in the bundle and every `.so` becomes a derived package dependency,
    which is [F26](../requirements/F26-Linux-Packaging.md)'s chain and the most delicate part of
    shipping this. Nothing forks — `posix_spawn` with `POSIX_SPAWN_SETSID` does the fork and the
    exec inside libc, and the child acquires the terminal by opening it as a session leader, so no
    Dart code ever runs in a forked process.
  - **Sokar's own verb, never `podman exec`.** Running the runtime's command here would teach this
    end which runtime is underneath — which [B08](https://github.com/fuinorg/sokar) exists so it
    does not — and would leave Sokar unable to refuse or to record that somebody was inside.
  - **No privilege is added**, and the earlier claim that it *"opens a much bigger door"* was
    withdrawn as conditional stated absolutely. Whoever forwards the socket already has an account
    on the node. It only fails to hold for a key restricted with `restrict,permitopen=`, and the
    operator has decided that is not a shape this supports.
  - **Leaving does not end it, because the session is `tmux` inside the container** — a process in
    the container, not on the channel. `tmux` is installed and pinned by Sokar in the layer it
    already writes, so nothing depends on what a base image carried, and its `history-limit` is
    the number behind *"what may re-entering claim"*: **the last N lines**, said as a figure
    rather than as an apology.
  - **No class refusal.** An `offline` project may be attached to — the class governs egress, and
    a person typing is neither resolving nor leaving; offline is precisely where somebody has to
    work by hand. So the action is offered for every running `SHELL` task without checking the
    class, and the two refusals left — not running, and no shell in the container — are both
    predictable from `Task`.
  - **`AGENT` and `UNATTENDED` are a different action**, and the distinction has to survive onto
    the screen: their main process is the agent, not the multiplexer, so *"see what this task is
    doing"* is `Tail` on `task.log`. Offering a session for work that has no shell to attach to is
    the confusing half.
  - **It runs a `sokar` command, which is the thing this file forbids elsewhere — and the line
    has to be drawn out loud.** Shelling out is refused for the vault because it would be a
    *substitute for a missing method*: doing over the CLI what the contract deliberately does not
    offer. Here the contract **cannot** carry it — measured, not assumed — and the Sokar side has
    named the verb as the way in. That is the difference, and it is the only one: a method that
    exists and is not offered stays off limits.
  - **The consequence, so nobody meets it by surprise.** A pty on the node can run any command the
    operator can, `sokar vault unlock` among them. This end will not draw a control for that — see
    F15, where *"at the machine, with a person present"* is the decision — but a terminal drawn
    here is a place a person could type it, and *"the interface cannot do this"* stops being the
    accurate sentence the day a session opens. Raised on the channel.

- **F21 Continuity And Updates** — **built**, except the half of one criterion that is **F12's,
  not ours**: *"where the environment allows work **and sessions** to outlive the window, they
  do"*. Work does and is reconnected to; a session cannot outlive anything that cannot be attached
  to in the first place. Recorded here because this file briefly said it was half a criterion
  *"that belongs to us"*, which was the tidier sentence rather than the true one.
  - **It is answerable now, and the answer is yes.** B16 was designed on 2026-09-08: the session
    is `tmux new-session -A -s sokar` **inside the container**, not on the channel that reaches
    it, so closing this window leaves it running and the next attachment finds it as it was.
  - **The boundary is the container, not the window**, and the screen must say the first without
    implying the second: `task stop` takes a session with it and `task resume` brings back an
    empty one.

### What is still worth asking for

- **Running an unattended task over the socket.** `Start` takes `mode` and `prompt` since
  2026-09-07 and *records* both, but does not run the agent headlessly and stream its output — it
  starts the container and returns. That is the remaining half of F08, and the Sokar side has
  offered to build it. **It is wanted.**
- **`Project` fields for whether the environment is prepared and how far the upstream has drifted**
  — the last two facts F02 asks for.
- **Renaming a task**, which F09 asks for and nothing can do.
- ~~A method behind `sokar panic`~~ — **`Panic` landed 2026-09-07 and F18 is built on it.** It stops and never removes; `surviving` names the helpers that outlived their stop rather than counting them. The one thing not on the wire is the field shape of `PanickedTask`, so what is rendered is how many were stopped rather than which.
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
