# F49 — Log In With An Agent From The Interface

Opened on 2026-09-19 at the operator's request. Starting work told him the vault holds no
credential for Anthropic, and the only way offered was storing an API key. His agent, Claude Code,
also signs in with an OAuth subscription, and **that login has to work on a remote machine too**,
because the machine is usually not the computer in front of him. Each agent does it differently.

## What must be true

**Where a credential is missing, the person can log in with the agent's own login, on the machine
the work will run on, from the interface, local or remote alike. What that login produces ends up
in the vault without its value passing through this interface.**

## Acceptance

- **Both ways are offered where a credential is missing**: storing a key or token, and logging in
  with the agent. Each is said for what it is — a key is typed, a login opens a browser page.
- **The login is the agent's own, run in a terminal on the machine**, over ssh for a remote one.
  A login that prints a link and waits for a code works across that terminal: the link is opened
  here, and the code goes back into the terminal.
- **The command is the agent's, named by the machine.** It is never composed here: every agent
  logs in differently, and a table of them kept here would go stale with each agent's release.
- **After the login, the credential is taken into the vault by the machine** from the agent's own
  configuration there (`ImportCredential`). Nothing crosses the socket but a name, and the
  interface asks again whether work can start.
- **An agent that declares no login says so.** Storing a key stays offered.
- **No code is typed where it is not needed** (the operator, 2026-09-19). The way is: press the
  link in the terminal, sign in in the browser here, and the login's redirect to `localhost`
  lands on the agent on the remote machine. So **that port is forwarded here for as long as the
  login lasts**, on the same number the redirect names, and taken down after. A port that is
  already taken here is said, and nothing is opened. A link-and-code login stays the fallback
  for an agent that has no redirect.
- **The login's page is a link to open here** (the operator, 2026-09-19: *a clickable link in the
  terminal is enough*). A program marks it as an OSC 8 hyperlink; the interface offers each such
  web address beside the terminal, and opens it in this computer's browser only when it is
  pressed. Nothing is picked out of the terminal's text, and nothing opens by itself.
  Claude Code does exactly this with `BROWSER` unset (Agent Smith, measured 2026-09-19): a
  link-and-code login that needs nothing forwarded. **Built** for every terminal here.

## Built, 2026-09-19

- **Links**: every terminal offers the web links its program marks (OSC 8), opened here with a press.
- **The login's reply**: a terminal opened for a login honours `OSC 5379;forward;<port> ST` from the
  machine once. It raises `ssh -L <port>:localhost:<port>`, checked by connecting through it, holds
  it while the terminal is open, and takes it down when the login ends or the terminal is put away.
  A port already taken here is said. Unit-tested, and the port check measured against a real
  socket.
- **The button**: where starting finds a credential missing and the chosen agent declares a login
  (`Agent.canLogIn`), *Log in with …: this runs the agent's own login* runs `sokar vault login
  <agent>` in a login terminal on the machine, with the documentation link beside it; then starting
  is asked about again. Storing takes `Readiness.storeCommand` where the machine gives it.
  Built against Sokar's `4d20cef` format, which is not on the VM yet.

## What the backend is short of

Asked of Sokar on 2026-09-19:

- **The agent's login command, declared by the agent and passed on by the machine.** This is
  AGENTS.md's *"two strings an agent declares and Sokar only displays"*: a login command and a
  documentation link. It lands in the agent repositories' manifests as well as in Sokar.
- **Whether `ImportCredential` covers what such a login writes** for each agent, OAuth
  subscriptions included, with `--type oauth` where a token goes in another header.
- **`BROWSER` set in the login's environment, to a helper** that opens nothing on the machine and
  writes the address to the terminal as an OSC 8 link. Set, Claude Code redirects to a random
  `localhost` port (Agent Smith, measured 2026-09-19).
- **The port that login listens on, said to this end and published out of the throwaway container
  onto the machine's own `localhost`**, so the forward from here reaches it. How it is said is
  Sokar's choice — an escape sequence beside the link is one way. The interface only ever forwards
  a port the login terminal names, and only while that terminal is open.

## To be checked

- **An agent whose login cannot run headless**: one that insists on a local browser or a
  callback port. Whether a remote login is possible for it is the agent's answer, and the screen
  says what it is.
