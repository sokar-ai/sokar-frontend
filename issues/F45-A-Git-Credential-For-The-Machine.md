# F45 — A Git Credential For The Machine

Opened on 2026-09-19 at the operator's request, after a follow of a private repository failed on the
test machine. **Blocked by Agent Sokar's answer to QF40**: where the credential lives and how the
daemon names it.

## What is wrong today

A machine follows a project's repository, and a private one needs a credential to be fetched. Today
Sokar's follow fetches with the account's own ssh setup — nothing from the vault — so the only way to
follow a private repository is to put a key into that account's `~/.ssh` by hand, over a terminal
somewhere else. And the refusal said *"the account's store is shut"*, which sent the operator to a
vault that would not have helped.

## What must be true

**A person gives a machine the credential its work uses for git, from the interface — as a step of
setting a machine up and at any time later from the machine's menu — without the value ever passing
through Sokar's socket or being kept here.**

## Acceptance

- **Two kinds, because that is what company networks hand out**, and generating a key pair on the
  machine is usually not allowed:
  - **an ssh key that was assigned** — chosen from this computer's keys, or its private and public
    halves pasted — for `git@…` repositories;
  - **a personal access token** — pasted — for `https://…` repositories. The step says that a
    restricted, read-only token is enough to follow, because following only reads.
- **The value goes to the machine over ssh, never over Sokar's socket**, and is not written to disk
  here, not kept in a field after it is sent, and never shown again: what is shown afterwards is the
  kind, the name it is kept under, and a fingerprint for a key.
- **Where it lands is Sokar's to say**, not this interface's — the vault if the follow is wired to
  it, the account's own files if not — and wherever it lands, only that account can read it.
- **What it opens is said before it is sent**: a person's own key or a full-access token reaches
  every repository that person can, not only the one being followed.
- A step of the machine wizard, after the vault — and the same step from the machine's menu for a
  machine that exists.

## What the backend is short of

Where a git credential for following lives, under which name, and the command that puts one there
— asked as QF40. Whether a follow fetches over `https://` with a token at all.

## To be checked

- **Where the credential lands, and whether the follow uses it** — the vault's `ssh.default`, which
  a task already uses, once Sokar wires the follow to it; or the account's own ssh setup until then.
