# F14 — Authentication Flows

**Status:** open. A rule about it was settled and then **changed in this interface's favour** on
the same day — the second version is the one to build against.

Getting agents and providers authenticated, from the interface, both for the machine
as a whole and for a single project.

**A secret may be transferred and must never be stored.** The first answer was *no secret crosses
this socket at all*, and it was withdrawn the same day by the operator — for a reason worth keeping,
because this end would have inherited it. The argument against transferring was that plaintext
should not pass through a GUI; the alternative it recommended puts it through a browser, a
clipboard, a terminal emulator's paste buffer and its **scrollback**, which many terminals persist
to disk. Measured on the Sokar side: `vault put` read a typed credential through the *echoing*
stream while the vault passphrase had always been read without echo. **The advice pointed at the
path that wrote the secret down.** Fixed there; recorded here so the reasoning is not re-derived
badly.

**So `StoreCredential` will exist, and typing a key into this window is not forbidden.** What is
forbidden is keeping it, and that is an obligation on *this* side that no daemon can enforce —
written down as
[B18](https://github.com/fuinorg/sokar/blob/main/requirements/base/B18-Storing-A-Credential-From-Elsewhere.md):

> A client must not persist what it transfers: not in local storage, not in a form draft, not in a
> crash report, not in an undo buffer. It clears the field after sending and never re-displays the
> value.

**`Credentials` stays read-only in the other direction**: names, kinds and lengths, never a value.
Reading one back is a different act from putting one in, and only the second has a person present
who already knows it.

**What the rule does not buy, so nothing stronger goes on screen.** It is *not* a claim about
transport: the socket is forwarded over ssh, so it is the same encrypted connection either way, and
anybody who can forward it can already run commands on that node. And the strongest point in the
whole exchange was neither side's — **a long-lived API key is carried around whatever route it
takes, and the real mitigation is a short lifetime.** That is why a phantom token expires.

**Confirming a paste without becoming the place the secret appears**: `StoreCredential` answers the
key it went under, the kind, and the **length** — enough to show that something arrived, never
what.

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
