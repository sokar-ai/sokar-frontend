# F14 — Authentication Flows

**Status:** open, and one criterion is settled as **never**, on 2026-09-08.

Getting agents and providers authenticated, from the interface, both for the machine
as a whole and for a single project.

**No secret crosses this socket, in either direction, ever.** Not the typing half only: storing one
over the wire is refused outright, on the same reasoning as `Unlock`. So `Credentials` answering
names, kinds and lengths and never a value is permanent, and *"where a credential must be typed"*
is answered here the way F15 answers unlocking — by saying **where** it happens, which is a
different sentence from *this cannot be done*.

**The reason is narrow, and the narrow one is what goes on screen.** It is *not* a claim about
transport: the socket is forwarded over ssh, so it is the same encrypted connection either way, and
anybody who can forward it can already run commands on that node. What the rule buys is that the
plaintext never enters a GUI process — no widget state, no clipboard, no crash dump — and never
enters the varlink layer, where JSON ends up in logs, traces and echoed errors. And that the
invariant stays absolute rather than becoming something every future code path has to remember.

**Where a person types it is not a server room.** The socket reaches this window *because* somebody
forwarded it over ssh, so they hold an authenticated connection to that node by definition: they
type it in the terminal half of the connection they already have. What this screen shows is
therefore **the command**, not a disabled field.

**And the key name is not this end's to guess.** It is the provider's name, falling back to the
agent's name for vaults written before that changed — so a client intersecting two lists would
report a credential missing from precisely the vault that has one. That is the third time this
shape has come up here, after the credential rule in F08 and the gate join in F10. The daemon
computes it and hands over the whole command.

**One real dead end, and it belongs on screen rather than in a surprise:** where ssh is locked to a
forced command that forwards the socket and gives no shell, a remote person cannot store a new
credential at all. They can only import one that is already on the node.

## Acceptance

- Authentication can be started without a project selected, for the machine as a
  whole, and from within a project for that project.
- The available providers are listed with what each one is, rather than as bare
  identifiers.
- Where a provider supports more than one way of authenticating, the choice is
  presented with the consequence of each.
- Where a credential must be typed, it is never displayed as it is typed, never shown
  back afterwards, and never appears in any log or output.
- Existing configuration held elsewhere on the machine can be imported rather than
  retyped.
- The interface states which providers are currently authenticated and which are not.

## Notes

Related: [Credential Management](https://github.com/fuinorg/sokar/blob/main/requirements/base/B03-Credential-Management.md), which governs how
values are stored. This file covers only the flows a person walks through.
