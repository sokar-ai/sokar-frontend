# F14 — Authentication Flows

**Status:** open, and **most of its screen is built** as of 2026-09-08. `Providers` and
`ImportCredential` landed and are on the wire; `StoreCredential` is parked and `Login` is designed
and not built.

Four of six criteria are met: the providers are listed with what each one is, which are
authenticated and which are not is stated, existing configuration on the machine is imported rather
than retyped, and nothing displays a secret because nothing here takes one.

**Two are not.** *"Where a provider supports more than one way of authenticating, the choice is
presented with the consequence of each"* waits on `Login` — the dialects are shown, but choosing
between them is what `Login` does. And *"authentication can be started from within a project for
that project"* **describes a relation that may not exist**: `Providers()` takes no project, and
nothing scopes a credential to one. That is asked rather than assumed, the way the agent roster and
key routing were — and both of those turned out to be reworded rather than built.

Getting agents and providers authenticated, from the interface, both for the machine
as a whole and for a single project.

**Nothing here asks for a secret, and that is where it stands rather than where it ends.** The
rule went through three states on 2026-09-08, and the sequence is the point:

1. **Refused, both halves** — a secret should pass through neither a GUI nor the varlink layer.
2. **The credential half was challenged and the rule refined to *transfer yes, storage never*.**
   The argument against transferring was that plaintext should not pass through a GUI; the
   alternative it recommended routes the key through a browser, a clipboard, a paste buffer and
   **scrollback**, which many terminals write to disk. Measured there: `vault put` read a typed
   credential through the *echoing* stream while the vault passphrase never did. **The advice
   pointed at the path that wrote the secret down.**
3. **Parked.** The passphrase was then examined and *its* argument — that a remote client cannot
   open the store — did not survive either: anybody with a shell can already unlock, and
   `--passphrase-command` and `--systemd-credential` have always existed. **Two of three original
   arguments failed under examination**, so the operator holds the passphrase and the credential
   together and decides them together rather than settling one on what is left of the other's
   reasoning.

**Only `StoreCredential` is parked.** `Providers` is a read with no secret in it; `ImportCredential`
moves no secret at all, because the daemon reads the agent's own config on its own disk and only a
name crosses; and an OAuth token in `Login` is minted by the provider and delivered straight into
the node's process. **Most of this requirement's screen is unaffected.**

**The storage obligation stands whichever way it is decided**, and it is the thing that will be
depended on if the answer is yes — an obligation on *this* side that no daemon can enforce, written
down as
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
