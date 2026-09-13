# F32 — The Ranked Review Of What Got Through

The interface half of Sokar's B38 (how far something that got through can get), handed to the
frontend on 2026-09-13. B38 itself says *"a ranked review is a screen more than it is a terminal
command"*. **Blocked by B38's buildable half**: the ranking has to exist first.

## What must be true

**The person who is the last control is shown what matters before what is merely large.**

That is B38's own sentence, as Agent Sokar quoted it on 2026-09-13. The criteria below are the
review's, which is this screen's substance.

## Acceptance

- **Before the patch text, the review names what the push changes that is dangerous by kind** — from
  a fixed list, even when the change is one line: CI workflow definitions, build scripts, git hooks
  committed into the tree, dependency manifests and lockfiles, and anything that executes on
  checkout. The list is the machine's; the interface shows it and never extends it.
- **What the task was asked to do is kept apart from what else it touched**, and the second can be
  read without reading the first.
- **Volume that is almost never a finding — reformatting, generated files — is identified as such and
  is not what the reviewer meets first.** Shrinking what must be read is worth more than
  highlighting within it.
- **Content Sokar delivered into a task carries its origin**, and the review shows that origin.
- **Nothing claims to detect an injection.** The screen changes what a person reads first and how much
  they must read, and it says so rather than implying a verdict.
- The order and the kinds are the machine's; nothing is re-ranked or re-classified here.

## What the backend is short of

**The wire shape.** B38 has no ranked review on the contract yet — no method returning the
dangerous-by-kind list, the separation of asked from touched, or the identified volume.

## To be checked

- **Whether the screen acts or only shows.** Whether an entry offers anything to do about it — and
  if so which of B38's actions reach the wire — is decided once the review exists on the contract,
  not before.
