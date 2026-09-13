# F36 — Operations Outlive The Window

The operator's decision on 2026-09-13, answering Sokar's QB10. Asked by the operator: whether the
interface has a log he can open.

## What is wrong today

`Operations` keeps what this session ran in memory. **Closing the window loses every command, what
it printed and how it ended**, including the failure somebody came back to read. There is no log
of the interface to open.

## What must be true

**Every operation — what was run, on which machine, what it printed and how it ended — is kept in a
file readable only by its owner, and the interface shows it again after a restart and opens it on
request.**

## Acceptance

- Each operation is written as it happens, so a window that is killed keeps what it had.
- **The file is owner-only (mode 600)** in the user's state directory, written the way the settings
  are, so a half-written entry never reads as a whole one.
- After a restart, the list of what was run on a machine shows earlier operations beside this
  session's, and says which are from before.
- The interface opens the file itself from its menu, and names where it is.
- **Nothing secret is written.** What an operation runs is shown before it is run and carries no
  credential; the file holds no more than the screen already did.
- It does not grow without bound, and says what it drops.

## To be checked

- **Whether a failure from before a restart still waits under Needs you.** A failed operation
  nobody has opened waits there until it is opened, within one run of the window. Once operations
  outlive the window, an unseen failure from yesterday is still unseen, and whether it waits or only
  shows in the record is a decision about what the window opens on.

- **How much is kept**: a count, an age or a size, and whether the output of a long operation is kept
  whole or cut.
- **One file or one per machine**, which decides whether forgetting a machine forgets its history.
