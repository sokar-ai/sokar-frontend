# F44 — Projects As Repositories

Opened on 2026-09-19 from Sokar B65, B66 and B67. **Built for B67 and B68's repository fields**;
what is still to build is at the end.

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

- **A project comes to a machine only by being followed**, decided by the operator on 2026-09-19.
  *Describe a project* goes, with nothing in its place: a person writes `project.yml` in their own
  repository, and what is wrong with it comes back from `follow` as the named reasons. It goes when
  Sokar removes `CreateProject` (B72), not before.
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
- **A refused signature is a state of its own on the project**, decided by the operator on
  2026-09-18: *"not following: commit `def456` is not signed by a key this machine was given"* — not
  only a line in `doctor`, where it would be missed while the project runs on, on its old state. It
  is also **under *Needs you***, because it is either somebody trying to slip a project file past
  the machine or a legitimate commit signed with the wrong key, and both need a person.
- **Whom a task may talk to follows from its project** (F42): agents of a project communicate by
  default, and nothing here maintains the members of a group.

## What the backend is short of

Nothing that is not on the wire: Sokar reports B66, B67 and B68 built. What is left is this
interface's (see *Still to build*), and QF23.

## To be checked

- **Nothing open here.** What a refused signature needs on the wire is Sokar B69.

## Built, 2026-09-19: the repository a start names (B67)

B67 is built on the Sokar side. `Projects()` names a project's `repositories`, its own first; the
start dialog offers them with **none chosen**, even when there is one, and starting waits for a
choice. The choice goes with `Start` as `repository`, and **only when the machine named any** — a
Sokar older than B67 names none and is sent none, so nothing breaks before it is published. An empty
list is not taken for one repository.

**Asked of Agent Sokar, not built:** whether *Start again* on a stopped task and the *Check that work
can start here* dry run need a repository too, since a started task already knows its own.

## Where the interface still assumes one repository, 2026-09-19

Reviewed screen by screen at the operator's request. **Wrong or misleading once a project has more
than one repository:**

1. **The gate and its review** — `gate(project)` without a repository answers only the project's own
   repository, so work a task did in another one waits in a gate this interface never shows, and the
   *waiting for review* counts in the tree and under *Needs you* count one repository. **Done first**,
   because here work goes unseen — see below. The counts are Sokar's to fix, and it has (QF24).
2. **A task does not say which repository it works in** — no field on `Task` — so its tile cannot
   show it, and *Continue* and *Start again* cannot carry it over.
3. **"N behind" in the tree** is one number per project, while every repository has its own upstream.
4. **Backups and *Sync upstream*** are per project, while mirrors are per repository.
5. **Describing a project** asks for one upstream (and B66 changes it to rendering the file anyway).
6. **Templates** keep project, agent and mode, but no repository, which every start now needs.
7. ***Check that work can start here*** asks without a repository (QF23). `CanStart` in the start
   dialog is built: it is asked again with the repository chosen, and its `NO_REPOSITORY_CHOSEN`
   before one is chosen is the dialog's own required choice, never shown as a problem.

**Still right, because they are about a project or a task, not a repository:** the security class
and egress, a task's clearance, the vault, the console, held work, the emergency stop, preparing a
project's image, and deleting a project (the daemon reads every mirror).

## The shape decided, 2026-09-19

The operator agreed:

- **The project stays the unit of navigation**; repositories get **no level of their own in the
  tree**.
- **The project view gains a *Repositories* section**: per repository its distance from upstream,
  what waits for review, its backups and its sync — replacing the single values per project.
- **The gate is grouped per repository**, and the counts in the tree and under *Needs you* add up
  every repository.
- **A task's tile names its repository**; *Continue* and *Start again* carry it over.
- **A template keeps its repository.**

**Built, 2026-09-18: the gate per repository.** Opening a project's gate asks `Pending` once for
every repository it names, the project's own first, and lists what waits in all of them; each push
names its repository where there is more than one, and is reviewed, forwarded and dropped with
that repository. The same ref name waiting in two repositories is two pushes. A repository whose
gate cannot be read is named, and does not hide what the others hold. A machine that names no
repositories is asked about none, as before.

**QF24 answered and built on both sides, 2026-09-18.** `Projects().pending` counted only the
project's own repository since B67 — a defect on Sokar's side, fixed: it is the sum over every
repository. Sokar then built all of QF24 at once rather than as a B69, and this interface followed:

- **`Projects().repositories` is a list of objects** — `name`, `own`, `upstream`, `mirror`,
  `pending`, `behind*` — read here as well as the list of names B67 first answered, own first.
- **The project's header has a line per repository** once there is more than one: *its own* marked,
  what waits at its gate, how far behind its upstream in the project's words for it, and its own
  *sync* and *backups*. The backups are listed, restored and synced **with that repository**; a
  bundle is kept under the repository it was taken of, and restored into no other.
- **`Task.repository`**: the tile names it once a project has more than one, the detail always; an
  empty one is the project's own, never *unknown*. *Start again*, *Recreate* and *Continue* carry
  it over.
- **A template keeps its repository**, and one whose repository the project no longer has is chosen
  again rather than sent to be refused.

**What `SetEgress` means now (B68):** a repository's grants are **added** to the project's, and
`SetEgress` without a repository writes the project's block, which widens every repository. This
interface only calls it from the project's own egress view, so that is what it means there.
Allowing a blocked connection goes through `decide` and `WidenTask`, which name the task, and Sokar
remembers the grant in the task's repository.

## Still to build

- **A repository's limits** — replacing the project's key by key. **No method answers them**: they
  are only in the file, and nothing says which key came from the repository and which fell through
  to the project (QF33). Sokar builds it if the operator asks for it; until then nothing is shown.
- **Follow state against a published Sokar**: built against the contract Sokar pasted on
  2026-09-19, which no published snapshot carries yet; and `Followed.needsAPerson`, which the pasted
  block lacks (QF30).

**Built, 2026-09-19: what a repository may reach.** Each repository line in the project's header
opens the egress editor for that repository: what every repository of the project may reach and
what this one adds, its own hosts marked — `Egress(repository)`, each host naming its origin, so
nothing is subtracted here. A change is previewed and written into the repository's own block,
`SetEgress(repository)`; the project's own view names no repository.

**Built, 2026-09-19: an unverified follow is marked** on the project's header and its card in
the tree, because nothing checks what the machine is handed for it — and a verified one is not.

**Built, 2026-09-19: following and no longer following.** *Describe a project* is gone with
`CreateProject`; in its place, *Follow a repository* asks for the name, where the repository is, and
how its commits are checked — a pinned key or unverified, **chosen, never defaulted**, with what
unverified gives away said beside the choice. What came of it is said in the header's words, a
refused commit makes no project, and a rewritten history is taken only by a second, separate
press. Removing a project is *Stop following*, with the same preview and refusals the removal had.

**Built, 2026-09-19: a project is named.** Every call that acts on a project sends its name —
starting and checking, the gate, preparing, egress, backups — as Sokar's projects-by-name change
requires, and a project the machine does not follow is said to be exactly that. **This build
needs a Sokar that has that change**, and the one published before it needs the build before this:
Sokar is pushed and published first.

**Built, 2026-09-19: the follow state.** The project's header says where following has got — the
commit in force, what was turned away and why, in words per reason, and what still runs — and a
project that stopped and needs a person is under *Needs you*, counted, with the signer's
fingerprint whole and the daemon's detail. A shut store is never worded as an unreachable
repository. Absent and empty `following` both mean *not followed*.

**Built, 2026-09-18:** each repository line in the project's header shows what work in it would
open: the project's dry run with that `repository`, which is the project's plan and what the
repository adds to it.

**QF26 answered, 2026-09-18.** `Following()` already answers per project and account: `name`, `url`,
the applied `commit`, `at`, and an `outcome` carrying `REWRITTEN` and `UNREACHABLE` — built against
today. **Sokar B69, not built — nothing is built against it here**:

- the refused signature as four reasons, not one `REFUSED`: `NOT_SIGNED`, `UNKNOWN_KEY`,
  `NO_ANCHOR`, `UNREADABLE`. *Nobody signed this* and *somebody signed it with a key this machine was
  not given* are different events; **only the second is a possible attempt**, and that is the one
  under *Needs you*;
- a locked vault as a reason of its own — today it is a hint in the text of `UNREACHABLE`, so
  *cannot reach the repository* is shown for a network that is fine;
- the refused commit beside the one in force (two fields, two questions), and the signing key's
  fingerprint, which is not a secret and is what a person compares with the key they meant to pin;
- the follow state on `Projects()`, so the project view does not join two calls.

**Answered, 2026-09-18:** *Show what a project would open* — `Start` with `dryRun` and no
repository — streams the project's own plan, which every repository gets and may only add to; the
reply says so. `CanStart` with no repository answers everything else first and asks for the
repository last. *Start again* sends the task's repository and Sokar refuses one that is not the
task's own, so what is sent is checked rather than ignored.
