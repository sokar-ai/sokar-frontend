# F50 — The Login Page That Needs No Code Comes First

Opened on 2026-09-19. The operator logged in with Claude Code from the interface. His browser showed
a code to paste instead of redirecting back, twice, although Sokar's `BROWSER` helper was in place
and wrote the redirecting link. Agent Smith's reading, not measured: Claude Code also prints a link of
its own, which leads to the code flow. The login terminal offers every link, so two buttons stood
side by side, and the one pressed was Claude Code's.

## What must be true

**When a login offers more than one link, the one whose reply comes back to the machine by itself
is the obvious one to press, and any other stays offered below it.**

## Acceptance

- **The machine marks its link**, and this end reads the mark rather than taking any URL apart:
  OSC 8's parameter field, `ESC ]8;id=sokar-login;<url> BEL`, proposed to Sokar as QF53.
- **The marked link is offered first**, as *Sign in: the reply comes back here*. Every other link
  is offered below it as *another link the program printed*, because an agent without a redirect
  still needs its own.
- **An unmarked link is never guessed to be the right one.**

## Built, 2026-09-19

The machine's mark (`id=sokar-login`, Sokar `37dcf74`) is read from OSC 8's parameters. The marked
link is offered first as *Sign in: the reply comes back here*, and any other below it as *Another
link the program printed*. A scenario feeds the helper's bytes and an unmarked link of the agent's
own. Not yet run against a machine: `37dcf74` is not on the VM.

## What the backend is short of

Nothing: the mark is built (`37dcf74`), not yet published.

## To be checked

- **Whether it was two links at all.** If it was one, the cause is somewhere else and this
  requirement is withdrawn.
