# F27 — Managed Tunnels

**Status:** open

Reaching another machine's Sokar without having raised the tunnel first.

[F20](F20-Access-From-Elsewhere.md) settled the transport: a remote daemon is its unix socket,
forwarded over SSH, and the client opens a path. It deliberately stopped there — a host is a name
and a socket path, and somebody else brings the forward up. That is the right first half, because
it keeps the interface out of key handling entirely. This is the second half: the interface
raising the forward itself, and owning it for as long as it is needed.

The whole of it is convenience over something that already works. Nothing here may become the
only way to reach a machine — a socket somebody else forwarded must keep working exactly as it
does now, because that is the path with no credential handling in it at all.

## Acceptance

- A host can be described by where it is rather than by a socket path, and the interface raises
  the forward when it is needed.
- A host whose socket is already forwarded is used as it is, with nothing raised and nothing
  managed. Which of the two a host is, is visible.
- A tunnel that drops is re-raised without the person asking, and a tunnel that cannot be raised
  says why in the words the transport used, rather than as a machine that is simply not there.
- Closing the interface leaves no forward running and no socket file behind.
- A tunnel the interface did not raise is never torn down by it.
- The local endpoint it creates is readable by nobody else, which is what an unmanaged forward
  already guarantees.

## Notes

The forward is `ssh -L <local socket>:<remote socket> <host> -N`, which is the same line
[F20](F20-Access-From-Elsewhere.md) records as measured. Running it is not a breach of the rule
against shelling out: that rule is about never building a second implementation of the *domain*
by parsing the `sokar` CLI, and `ssh` is transport, not domain. Nothing about the contract, the
calls or the refusals goes near it.

## To be checked

- **What happens when the key needs a passphrase, or the host is unknown.** Both are interactive
  prompts on a terminal this has no terminal for. The honest options are to require a key that
  needs no interaction (an agent, a `ControlMaster`), or to surface the prompt in the interface —
  and surfacing it means handling a passphrase, which is the thing F20 stayed out of. Settle this
  before anything is built: it decides whether this requirement is small or large.
- Whether one `ssh` per host or a shared `ControlMaster` per host is what gets supervised. The
  second is cheaper and is what somebody with a working SSH setup already has.
- Whether a managed tunnel should survive the interface being closed, so that reopening it finds
  the machine already there. It is friendlier and it contradicts "leaves no forward running".
