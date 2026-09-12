# Rules for working in this repository

The short list. [AGENT.md](AGENT.md) is the long one — what this is made of, what it measured, and
what each mistake cost. Read that before changing anything; read this before doing anything.

## Shared with the other Sokar repositories

- **The operator pushes.** Agents commit. Never `git push`.
- **Nobody edits another agent's repository.** The operator has said Sokar may edit `issues/` and
  `doc/` here — available, never an obligation, and Sokar has asked to be asked first rather than
  act on a permission it learned from a document. Nothing else of this tree is anyone else's to
  change, and nothing of theirs is ours.
- **The channel is append-only.** `~/.sokar/agent-channel.md`, one heading per entry
  (`## <date -u> — Frontend agent`). A question is marked with the asker's prefix and a number —
  `QF<n>` from here, `QB<n>` from the backend — and an answer is `**A:** to <timestamp>`, so the
  file says who is owed an answer. Check `git status` before committing after reading it.
- **A secret never appears in a command line**, and reaches a process through its environment or
  its standard input — `/proc/<pid>/cmdline` is world-readable. Where one is stored, it is
  encrypted at rest and readable only by its owner; in CI it is never written to a filesystem at
  all. Nothing under `~/.claude/.ssh` is ever printed or copied. (Sokar's wording, 2026-09-12: the
  earlier *"never written to a file"* was false in a repository whose vault is a file, and a rule
  that is visibly broken on line one gets ignored whole.)
- **The test machine is shared.** Change nothing on it that was not asked for, name what you
  remove rather than sweeping what you do not recognise, and say in the channel before restarting
  it.
- **Say what a run does to a shared machine before starting it, not what you believe it does.**
  Sokar's acceptance suite was described as rebooting nothing while three of its scenarios existed
  to reboot the machine, and it took another agent's test run down with it on 2026-09-12.
- **Link to a requirement by number and to the index, not to its file.** A finished requirement's
  file is deleted — so a link to it breaks exactly when that requirement succeeds, which is the
  worst moment for a reader to meet a 404.
- **Dot files and directories are not checked in.** The exceptions are listed in `.gitignore`, and
  they are only what a build needs: `.github`, `.mvn` for the Maven wrapper, `.metadata` for
  Flutter. Anything that applies only to this machine goes in `.AGENTS.md`, which that rule
  ignores by itself.

## This repository

- **US English** in code, interface text, tests and documents. Replies to the operator are in
  German.
- **A commit message is one brief line.** Comments in code are brief and say *why*, never what the
  line already says.
- **Measure before you claim.** *"It works"* means it was run. *"That is not the cause"* means the
  counter-test was run too. (Agent Smith's wording, 2026-09-12, from a regression test of his that
  passed with and without the fix.)
- **A test that passes with and without the fix proves nothing.**
- **Every guard gets a scenario, and then the guard gets broken.** Mutation is the rule: change
  the condition, watch the *right* scenario fail, restore. A mutation that survives means the test
  names the wrong thing. A mutation that does not compile proves nothing — check for that.
- **GUI tests run headless only.** `tool/e2e.sh` under xvfb; never a window on the operator's
  screen.
- **`flutter analyze` and the whole suite pass before a commit.** Not the file you touched: the
  suite.
- **Never run `dart format` on a directory or on an existing file.** It reflows code around your
  change and every later anchor-based edit then fails on text nobody read.
- **The interface never parses the `sokar` CLI and never reads a task's log.** One varlink
  interface, `org.fuin.sokar.Tasks1`, over one socket. A second reader of the domain is a second
  implementation of it.
- **Requirements live in `issues/FNN-Name.md`.** The number is identity, not order;
  [issues/README.md](issues/README.md) is the order. A requirement says what must be true for a
  person, never how it is built.
- **What the backend cannot do yet is written down**, in `doc/Contract-Gaps.md`, rather than
  worked around in the interface.
