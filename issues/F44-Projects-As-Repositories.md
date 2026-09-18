# F44 — Projects As Repositories

Opened on 2026-09-19 from Sokar B65, B66 and B67, decided that day and not yet built. **Blocked by
Sokar B65–B67**: the fields and names of the new methods are not settled.

## What changes underneath

A **project** is a unit of work over one or more git repositories, with **its own repository** holding
`project.yml`, its planning and its issues. A machine **pulls that repository and reconciles itself
against it**, per project and per account, applying only what is signed by a key it was given out of
band. A team is a later, optional layer above it.

## What must be true

**The interface treats a project as what it now is — a repository a machine follows — and never
writes a project file onto a machine, never assumes a project is one repository, and shows how far a
machine's following has got and why it stopped.**

## Acceptance

- **Describing a project renders its file and gives it back**, to be committed to the project's
  repository where the person already commits. Nothing is written on the machine; the answer to QF22
  (the machine choosing a path for the file) is superseded, and the dialog's *"its file goes to …"*
  goes with it.
- **Starting work always names a repository**: a required choice, never preselected, even when a
  project has one. A start without one is refused with the list of what there is, and that list is
  what is offered.
- **The project list shows** a project's own repository, its work repositories and its follow state:
  which commit, how long ago, and why not when it is not following.
- **Following and unfollowing** a project by its git URL (not a secret, so over the socket).
  **`unfollow` refuses while a mirror holds unreviewed work or a task still exists**, and proceeds
  when a person says they mean it — the same *"are you sure, here is what is in the way"* as the other
  destructive actions.
- **"Not reconciling — this account's vault is locked"** is said as its own state, distinct from
  *"cannot reach the repository"*. After a restart a machine resumes per person, as each opens their
  vault; its projects are as they were meanwhile, not broken. Shown, never turned into a notification
  by anything here.
- **Whom a task may talk to follows from its project** (F42): agents of a project communicate by
  default, and nothing here maintains the members of a group.

## What the backend is short of

**Sokar B65–B67**: `CreateProject` returning rather than writing; a repository in every start call;
`Projects()` carrying repositories and follow state; `follow` and `unfollow`; the reconciliation
state per account.

## To be checked

- **How a repository is named in a start call**, and whether a refused signature needs anything on a
  screen beyond a line in `doctor` — both open on the Sokar side.
