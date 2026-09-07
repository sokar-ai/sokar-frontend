# F25 — Task Templates

**Status:** open — three of four criteria built. Templates are kept beside the interface rather
than with the project, because nothing in the contract writes one to a project file.

The same few jobs recur. A template names one, carries its prompt, and records the settings that
job needs.

Moved here from the central index, where it was 0019.

## Acceptance

- Templates are definable per project and shared with it.
- Starting from a template is a single action.
- The prompt is editable before it runs.
- A template cannot raise the project's security class.

## Notes

Lower priority than the rest of this set: valuable, but it automates something that already works.
The last criterion is the one with teeth - a template is a convenience, and a convenience that can
quietly widen what work may reach is not one.

## What is left, 2026-09-07

Built: a job is named from the start dialog once its choices have been made; each named job becomes
an action of its own, so it turns up in the finder, the menu bar and anywhere else the command list
is read; starting one is a single action; and what it asks for is in the box, editable, before it
runs. A job named in one project is not offered in another, and it outlives the run that named it.

**The criterion with teeth is met by what a template cannot carry.** `Start` takes `clearance` and
`noGate`, either of which would let a job set up last month be running today with the gate off.
Neither is a field on a template, reading one names its fields rather than copying a map — so a
hand-written `noGate` in the settings file is not honored — and a mode this build does not
recognize makes a job unstartable rather than starting something nobody can describe. The project's
security class itself is out of reach by the contract: `Start` has no parameter that sets it.

One criterion is not met:

- *"Templates are definable per project and **shared with it**."* They are definable per project.
  They are not shared with it: **nothing in the contract writes to a project file except
  `SetEgress`**, so a template lives beside this interface's own choices and follows the person
  rather than the project. Somebody else on the same machine does not see it, and neither does the
  same project on another machine. Asked for on the channel; until there is somewhere to put one,
  this is a real shortfall rather than a rendering decision.
