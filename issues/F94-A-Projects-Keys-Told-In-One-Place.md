# F94 — A Project's Keys Told In One Place

**Status:** soon.

**What must be true.** A person sees a project's keys in one place, whose each is and what it is for,
and learns whether their own signing key satisfies a branch rule that demands signed commits.

## Why

The forge's signing keys are already found for the person and all pinned at binding, so binding asks
for no key again; what each key is for is not yet told together.

## Acceptance

- One view lists every key of a project with its owner and its purpose. Seen to fail: a scenario
  whose project has keys of a machine and of the person and finds one missing, or without its owner
  or purpose.
- When a branch rule demands signed commits, the person's signing key is checked against it and the
  outcome shown. Seen to fail: a scenario with such a rule and a person's key the forge does not take
  for signing that shows no warning, or one that shows a warning for a key it does take.
