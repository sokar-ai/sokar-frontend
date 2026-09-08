# F05 — Project Configuration

**Status:** open

The settings a project carries that change what its work can do: which agents are
available inside it, what hardware it may reach, and which destinations it may talk
to.

## Acceptance

- **A project does not restrict which agents may run in it, and the interface says so
  rather than offering an editor for a list that does not exist.** There is no roster
  in a project file and nothing enforces one: any installed agent may run in any
  project, bounded by the project's own security class, its egress and its gate.
- **A project cannot ask for hardware**, and the interface says that too. There is no
  device access of any kind in a project file, and nothing lists a machine's hardware
  to choose from.
- The curated sets of destinations a project may reach are selectable. **The
  open-ended half of this does not apply to them**, and that is a decision rather than
  a shortfall: `SetEgress` takes an explicit list on purpose, because "all sets,
  including ones installed later" would let a set shipped in a later release widen a
  project nobody edited. The interface says that where somebody might look for it,
  rather than only leaving it out.
- Any change states what it will affect and when it takes effect — immediately, or at
  the next rebuild.
- Deleting a project requires a confirmation that names what will be destroyed.

## Notes

Related: [what the egress editor settled](https://github.com/fuinorg/sokar/blob/main/requirements/base/README.md#what-was-here-and-is-finished) covers editing the
destination sets themselves; this covers choosing which of them a project uses.

## Settled, 2026-09-07

The destinations third of this requirement was listed as short of a method for the
open-ended selection. It is not: the Sokar side confirmed the explicit list **is** the
guarantee. An operator who chose "everything that exists" would find that what exists
had changed underneath them, which is exactly what an egress list is meant to prevent.
The requirement no longer asks for it, and the interface says why.

The other three criteria are still short of a method: editing the agent roster, listing
and selecting hardware, and deleting a project.

## Reworded, 2026-09-08

Two criteria asked for editors over things a project does not have. Confirmed against the `Project`
record rather than assumed: **a project file declares a name, a description, a security class, a
base image, an optional image snippet, an optional upstream, limits and egress.** That is the whole
vocabulary.

- **No agent roster.** `--agent` picks per run and any installed agent may run in any project.
- **No hardware.** No device flag of any kind, and `Limits` holds memory, cpus and pids and nothing
  else. Nothing lists a machine's hardware either, so there is no list to choose from.

**The open-versus-frozen argument does not carry over from egress, and the reason is worth
keeping.** For sets it was refused because a later release could widen a project nobody edited.
Choosing an agent is not that: an agent added later still runs under the project's class, egress
and gate. **Except in one place** — an agent declares `allowedDomains`, which are added to a task's
egress on top of the project's own. So a new agent running in a project *does* widen what that
task reaches, by its own declaration. If a roster is ever built, that is the reason it would have
to be an explicit list. Put to the operator; not asked for here.

The interface already says the consequential half of this where it matters: the agent inventory
shows each agent's hosts with the sentence *"added to a task's egress on top of the project's
own"*.

## What deleting a project would destroy, 2026-09-08

The method does not exist yet and is being built in the shape asked for: a `dryRun` that says what
would go, a named outcome, and a **refusal** rather than a warning when something holds work.

What Sokar owns and would remove: the gate mirror **including the unreviewed pushes in
`refs/sokar/incoming/`**, the task image, the build directory, the registry entry, the upstream
record, and every task of it — container, state directory, logs, token and the workspace inside
the container.

**And the distinction that changes what the confirmation says: `project.yml` is not Sokar's.** It
belongs to the operator, in their own directory, usually beside their own repository. A delete must
not touch it, and a confirmation listing it among the casualties would claim ownership of something
Sokar merely reads. So the sentence is *"this removes what Sokar built for this project"*, never
*"this deletes the project"* — afterwards the file is still there and running a task in that
directory builds all of it again.

**The unreviewed pushes are the one thing that must refuse rather than warn.** A workspace is
recoverable in principle, because the operator still has their repository. A branch that reached
the mirror and was never approved exists **only** there.
