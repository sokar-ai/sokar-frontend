# F59 — A Project From A Repository, Measured Against GitHub

**Status:** soon; blocked by a GitHub token and the test repositories from the operator.

**What must be true.** What is left of making a project from a repository is shown to work against
GitHub itself, not only against stand-ins.

## Why

Already measured against GitHub with two test repositories on a rented machine: a token connected
and its refusals shown in GitHub's words, a `project.yml` written in the form, committed signed and
pushed, the machine bound with a deploy key per repository titled
`sokar <machine> <project>/<repository>`, a task started, and in `default` a task's approved work
forwarded to the repository's `main`.

The token needs *Contents* and *Administration: Read and write* for the test repositories. Neither
the token nor the repositories are ever kept in this repository or the channel.

## Acceptance

- **Removing a machine, or unbinding it, deletes its deploy keys at GitHub.** Seen to fail: the
  repository's deploy keys listed at GitHub after the removal still hold the machine's key.
- **A `project.yml` committed in the form is shown as verified by GitHub**, signed with the person's
  ssh key. Seen to fail: GitHub's commit page shows it unverified.
- **A push that branch protection refuses** is said in GitHub's words. Seen to fail: a push to a
  protected branch shows anything other than GitHub's refusal.
- **The repository list pages past 100 repositories**, with admin and push rights as GitHub reports
  them, for a fine-grained token and for a classic one. Seen to fail: an account with more than 100
  repositories where one is missing or its rights differ from GitHub's.
- **Approved work in a project**, not only in `default`, reaches the repository at GitHub. Seen to
  fail: the approved commit is not on the repository's branch at GitHub.
