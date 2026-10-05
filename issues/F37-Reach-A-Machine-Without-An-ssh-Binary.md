# F37 — Reach A Machine Without An ssh Binary

**Status:** later; blocked by the operator: a mobile client.

**What must be true.** A person reaches a machine from a device without an `ssh` binary, such as a
phone, and the machine is trusted, authenticated and supervised to the same standard as from the
desktop.

## Why

Every connection runs OpenSSH's `ssh` as a process (see *The interface raises and supervises its
own ssh forward* in [decisions](../doc/decisions.md)): the forward to the daemon
(`lib/src/app/tunnel.dart`), starting the daemon and `id -u` for the connection trial, and working
in a task by hand (`lib/src/app/session.dart`). That inherits the person's `~/.ssh/config`,
ssh-agent, `known_hosts` and hardware keys, and nothing in `lib/` holds a private key. iOS and
Android have no `ssh` binary.

[`dartssh2`](https://pub.dev/packages/dartssh2) 4.1.0, read in its source and not run against a
server, has forwarding to a Unix socket as a byte stream, exec, shell and pty, jump hosts by hand,
host key verification as a callback (any key is accepted without it), custom asynchronous signers,
current keys, ciphers and strict key exchange, on every platform, pure Dart, MIT. It has no client
for a running ssh-agent, no `~/.ssh/config` or `known_hosts`, no FIDO keys or certificates and no
post-quantum key exchange. It changes fast, with breaking releases, and 4.0.0 fixed real security
defects.

A mobile client is more than a transport: a phone ends connections in the background, clearance
questions have deadlines, and notifications need another path.

## The shape

- **`dartssh2` beside `ssh`, never instead of it.** One transport interface with two
  implementations: the desktop keeps `ssh`, a mobile client uses `dartssh2`.
- On a mobile client the interface owns what OpenSSH did: host key trust with its own known-hosts
  store and a first-contact question, key import or generation with a passphrase, storage in the
  platform keychain.
- `VarlinkConnection` accepts any byte stream instead of only `Socket.connect(socketPath)`.

## Acceptance

- **One transport interface** covers the forward to the daemon, starting it, `id -u` and a pty
  session, and the desktop behaves exactly as before. Seen to fail: the existing scenarios and
  integration legs of the desktop.
- **`VarlinkConnection` speaks over a stream**, and the socket path is only one way to get one.
  Seen to fail: a test that speaks Varlink over an in-memory stream without a socket file.
- **No connection without a host key decision**: an unknown key is asked about with its
  fingerprint, a changed key refuses the connection, a remembered key is stored owner-only;
  `onVerifyHostKey` is never null and `disableHostkeyVerification` is never set. Seen to fail: tests
  with an unknown and a changed host key, and a check of the store's file mode.
- **A private key never leaves the platform keychain unencrypted, and nothing logs a secret.** Seen
  to fail: a test that reads the log and the stored files after a connection and finds no key or
  passphrase.
- **The `dartssh2` transport is exercised against a real machine** in the integration legs, not
  only against a fake. Seen to fail: an integration leg over `dartssh2` that connects, forwards and
  opens a pty.

## To be checked

- **How keys reach a phone**: generated there and authorized on the machine, or imported, and
  whether hardware-backed keys (Secure Enclave, StrongBox) are required through
  `SSHIdentity.custom`.
- **Whether a connection without post-quantum key exchange is acceptable** for a mobile client.
- **How a pinned `dartssh2` is kept current**, given how fast it changes and how recent its
  security fixes are.
