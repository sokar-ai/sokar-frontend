# F08 — Task Creation And Modes

**Status:** open — five of six criteria built. What is left is reporting a missing credential
before anything is built, which has no method behind it.

Starting work against a project, choosing how a person intends to be involved in it.

## Acceptance

- Work can be started from the interface with a name, an agent and a mode, without
  typing a command.
- The modes on offer are distinguished by the person's role in each: driving it
  interactively, working with it through a richer session, or leaving it to run
  unattended against a written prompt.
- An unattended run collects its prompt before starting, and the prompt is retained
  with the work afterwards.
- Choices that cannot work together are refused at the point of choosing, with the
  reason named.
- A missing credential is reported before anything is built or started.
- Completed or failed unattended work can be continued with a new prompt without
  recreating it from scratch.

## Notes

This absorbed the central requirement for starting work and adds the follow-up path, which is
what turns a finished unattended run into a conversation rather than a one-shot. Starting is a
single daemon call, so the interface and the CLI cannot offer different things.

## What is left, 2026-09-07

`Start` gained `mode` and `prompt`, and with a prompt the call **runs the agent** rather than only
bringing the container up. So work is started with a name, an agent and a mode; the three modes are
named by the person's part in each; an unattended run collects its prompt and keeps it; the one
combination that cannot work — a prompt with a mode nobody is unattended in — is refused where it
is chosen; and a finished unattended run is continued with what it was asked to do last time,
edited.

One criterion has nothing behind it:

- *"A missing credential is reported before anything is built or started."* `Credentials` reports
  the store's state and what is in it by name. **Nothing says which credential a given project and
  agent need**, so an interface can list what is there and cannot say what is missing. Guessing
  from an agent's name would be a second implementation of the daemon's own rule, and wrong the
  first time an agent changed what it uses.
