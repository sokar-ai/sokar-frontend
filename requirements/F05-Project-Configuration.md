# F05 — Project Configuration

**Status:** open

The settings a project carries that change what its work can do: which agents are
available inside it, what hardware it may reach, and which destinations it may talk
to.

## Acceptance

- The agent roster for a project is editable in the interface, and the choice between
  "everything, including agents added later" and an explicit frozen list is explicit,
  because they are different commitments.
- Selecting or clearing any individual item makes it plain that the selection is now
  an explicit list rather than an open-ended one.
- Hardware access is selectable from what the machine actually has, and the interface
  is usable before that detection finishes.
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
