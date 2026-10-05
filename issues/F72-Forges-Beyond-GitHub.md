# F72 — Forges Beyond GitHub

**Status:** later; blocked by the operator: which forge next.

**What must be true.** A person whose repositories are at another forge gets the same way from a
repository to work as at GitHub, or is told what that forge does not allow.

## Why

A project from a repository and work in `default` are built and measured against GitHub alone. Each
forge's own API is the interface's; the backend is short of nothing known.

## Acceptance

- Each forge offered is measured against the forge itself before the interface names it: a project
  from a repository there, and work in `default` pushed back. Seen to fail: the forge's leg of
  `project_from_repository.feature`, run against the forge, goes red.
- Where the forge forbids a step, the interface says so in words instead of failing silently.
  Seen to fail: a scenario where the forge refuses the step and the words are missing.

## To be checked

- Bitbucket Cloud's access keys are read-only: what a machine's push goes through there.
