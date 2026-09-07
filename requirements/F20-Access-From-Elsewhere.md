# F20 — Access From Elsewhere

**Status:** open

Reaching the interface from a device that is not sitting in front of the machine,
without weakening the machine.

## What was decided

**No browser.** An earlier version of this required the interface to be reachable from a browser
on another device, and that requirement is gone. It was the only thing in the product that would
have forced the daemon to speak something other than its unix socket — a listener, a port, a
certificate, an authentication scheme of its own — and every one of those is a way in that does
not exist today.

What replaces it is not a compromise. Measured against a real daemon on another machine:

```
ssh -L /tmp/sokard-remote.sock:/run/user/1001/sokar/sokard.sock user@host -N
```

The client then opens `/tmp/sokard-remote.sock` instead of `$XDG_RUNTIME_DIR/sokar/sokard.sock`
and everything else is identical — same calls, same replies, same code. Streaming survives it:
watching the task list through the forward, a task stopped on the far machine was reported
0.4 s later. So **local and remote differ by one string, the socket path**, and there is no
second transport, no second authentication story and no second set of bugs.

The cost is stated rather than hidden: this needs a shell on the far machine. A device that
cannot open an SSH connection cannot reach a Sokar. That is the trade this requirement makes,
and it buys the daemon never binding a network interface in any configuration.

## Acceptance

- The interface can be reached from another machine over a forwarded socket, with no
  configuration on the Sokar host beyond the SSH access that is already there.
- Which host is being shown is always visible; a client that can reach several never leaves it
  ambiguous which one an action will act on.
- A lost tunnel is shown as a disconnection, never as a machine with no tasks on it.
- Reconnection recovers without restarting the interface, and a stream that was cut is resumed
  rather than silently left dead.
- The forwarded socket is not readable by other users on the client machine.
- The remote view offers the same actions as the local one, or names precisely what it does not
  offer.

## Notes

Related: [Remote Access](https://github.com/fuinorg/sokar/blob/main/requirements/base/B06-Remote-Access.md),
which is the transport this rests on and stays a central requirement because it constrains the
daemon rather than the interface. Its central question — whether the tunnel can carry the
daemon's socket directly — is answered: it can.

The connection recipe, in full, with a working client, is in
[Backend API](../doc/Backend-API.md).

## To be checked

Whether the actions that hand off to a local session — attaching interactively, opening an
editor, taking changes out to the clipboard — can be honoured remotely at all, or whether the
remote view must declare them unavailable. This changes what the acceptance criteria above can
promise, and it is sharper now than it was: attaching to a session over a forwarded socket means
a terminal, and a terminal is the one thing this transport does not obviously carry.

Whether an interface should manage the tunnel itself — spawning `ssh` and owning its lifetime —
or require one that is already up. Managing it is friendlier and puts key handling and process
supervision inside the interface; requiring one keeps the interface out of the credential
business entirely.
