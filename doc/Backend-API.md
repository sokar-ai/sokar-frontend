# The backend API

Everything this interface does, it does by calling Sokar's daemon, `sokard`, over one unix
socket. There is no HTTP, no port and no client library — the whole protocol is JSON objects
separated by NUL bytes, and Dart speaks it out of the box.

## The contract

The interface is `org.fuin.sokar.Tasks1`, defined in
[varlink](https://varlink.org/Interface-Definition) IDL. The definition lives in the backend
repository at `daemon/src/main/resources/varlink/org.fuin.sokar.Tasks1.varlink`, and a build
there fails if a method is registered without appearing in it, or appears in it without being
registered, or reads a parameter it does not describe.

**Do not keep a copy of it here.** A running daemon serves its own contract:

```
varlinkctl introspect $XDG_RUNTIME_DIR/sokar/sokard.sock org.fuin.sokar.Tasks1
```

or, without `varlinkctl`, `dart tool/contract.dart` in this repository, which prints the same
thing and works against a forwarded socket too. A copy checked in here would be a second source
of truth that nothing keeps honest.

## Connecting

Locally, the socket is at `$XDG_RUNTIME_DIR/sokar/sokard.sock` — normally
`/run/user/<uid>/sokar/sokard.sock`. It is owner-only, so the filesystem is the access control;
there is nothing to authenticate against.

Remotely, forward it:

```
ssh -L /tmp/sokard-remote.sock:/run/user/1001/sokar/sokard.sock user@host -N
```

and open `/tmp/sokard-remote.sock` instead. **That is the entire difference between a local and
a remote Sokar** — one string. Do not build two transports. Streaming works through the forward
unchanged; measured, an event raised on the far machine arrived 0.4 s later.

`ssh` creates the local endpoint owner-only, so the forwarded socket is no more exposed than the
original.

## Speaking it

```dart
import 'dart:convert';
import 'dart:io';

final socket = await Socket.connect(
    InternetAddress(path, type: InternetAddressType.unix), 0);

socket.add(utf8.encode(jsonEncode({
  'method': 'org.fuin.sokar.Tasks1.List',
  'parameters': <String, dynamic>{},
})));
socket.add([0]);          // NUL terminates the call
```

Replies come back the same way: one JSON object per NUL. Three things to know.

- **Streaming.** Add `'more': true` to the call. Every reply but the last then carries
  `"continues": true`. `Watch`, `Tail`, `Start` and `Prompts` stream; `Prompts` *only* streams
  and refuses a call without `more`.
- **Errors** arrive as an object with `error` (the fully-qualified name) and `parameters`,
  instead of `parameters` alone. They are answers, not faults — `HOLDS_WORK` from `Stop` is the
  gate working.
- **One call at a time per connection.** The framing has no request ids. Open a connection per
  stream; that is what it is for, and it costs nothing.

## Staying compatible with older backends

A fleet is not upgraded at once, so this interface will meet daemons older than itself. The
contract commits to three things, and the IDL states them in full at the top of the file:

1. **The `1` in `Tasks1` is the promise.** Within it the interface only grows — new methods, new
   optional parameters, new reply fields. Nothing is removed, renamed, retyped, or given a new
   meaning. A change that cannot be made that way becomes `Tasks2`, served *beside* `Tasks1` for
   at least one release. So: call `org.varlink.service.GetInfo`, read its `interfaces` list, and
   use the highest one you understand. Do not compare version numbers to decide this.

2. **Degrade per feature, not per connection.** A method an older daemon lacks answers
   `org.varlink.service.MethodNotFound`. Catch it, disable that one feature, keep the rest. An
   optional parameter an older daemon does not know is ignored, and it behaves as its documented
   default says.

3. **Unknown values must not be fatal.** Ignore reply fields you do not recognise, and render an
   unrecognised enum value rather than throwing on it. `Outcome` in particular will gain entries,
   and adding one is explicitly *not* a breaking change — so a client that cannot survive one
   will break on a routine release. This is the rule most likely to be broken by a generated
   Dart enum with no fallback case.

`GetInfo` also reports the daemon's build version. Show it and put it in bug reports; do not
gate features on it.

## What is there

Read the IDL for the detail — it carries a comment per method and per field. The shape of it:

| | |
|---|---|
| **What exists** | `List`, `Watch` (streams), `Agents`, `Credentials` |
| **Running tasks** | `Start` (streams the build), `Stop`, `Resume`, `Tail` (follows a log) |
| **The gate** | `Pending`, `Review`, `Approve`, `Reject` |
| **Clearance** | `Prompts` (streams, and only streams), `Decide` |

Two things worth knowing before designing around them:

- **`Stop` refuses.** A task holding commits that never reached the gate comes back as
  `HOLDS_WORK` and is left exactly as it was. That refusal is a feature and needs a real place in
  the interface, not an error toast.
- **`Prompts` has a deadline.** A task is *blocked* while a clearance prompt is unanswered and
  the watcher gives up after its own timeout. This is the one place where interface latency costs
  something real, which is why it is a stream and not a poll.
