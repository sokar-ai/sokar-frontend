# F37 — Reach A Machine Without An ssh Binary

Asked by the operator on 2026-09-14: could the interface use
[`dartssh2`](https://pub.dev/packages/dartssh2) instead of running `ssh`, so that it could also run
on a mobile client. Nothing is built; this records what was measured and what is recommended.

## How a machine is reached today

Every connection runs OpenSSH's own `ssh` as a process — see *The interface raises and supervises
its own ssh forward* in [decisions](../doc/decisions.md):

- the forward to the daemon, `ssh -L <local socket>:<remote socket> <host> -N`, supervised and
  raised again when it drops (`lib/src/app/tunnel.dart`);
- starting the daemon, and `id -u` for the connection trial (`tunnel.dart`);
- working in a task by hand, `ssh -t <host> sokar task attach <task>` (`lib/src/app/session.dart`).

That inherits the person's `~/.ssh/config`, ssh-agent, `known_hosts` and hardware keys, and nothing
in `lib/` holds a private key. **iOS and Android have no `ssh` binary**, so none of it runs there.

## What `dartssh2` 4.1.0 can do — measured in its source on 2026-09-14

Read from the published archive, its changelog, pub.dev and GitHub; nothing was run against a server.

**What it has:**

- **Forwarding to a Unix socket**: `SSHClient.forwardLocalUnix(remoteSocketPath)` over
  `direct-streamlocal@openssh.com`. It returns a byte stream (`SSHForwardChannel`), not a local socket
  file.
- **Exec, shell and a pty** (`execute`, `shell` with `SSHPtyConfig`, `runWithResult` with the exit
  code), local, remote and dynamic TCP forwarding, SFTP.
- **Jump hosts by hand**: `SSHForwardChannel` implements `SSHSocket`, so one connection can carry the
  next.
- **Host key verification as a callback**, `onVerifyHostKey(type, fingerprint)` with the SHA256
  fingerprint; a host key that changes on rekey ends the connection. **Without the callback, any host
  key is accepted.**
- **Custom signers**: `SSHIdentity.custom(signer:)` signs asynchronously, so an agent client or a
  platform keystore could be plugged in.
- Keys: Ed25519, RSA with SHA-2, ECDSA P-256/384/521; encrypted OpenSSH keys (bcrypt) read and written.
  Password, keyboard-interactive and hostbased authentication.
- Key exchange `curve25519-sha256`, ECDH and DH group exchange; ciphers AES-GCM,
  `chacha20-poly1305@openssh.com`, AES-CTR; ETM MACs; strict key exchange against Terrapin
  (CVE-2023-48795); keepalive, rekey.
- Android, iOS, Linux, macOS, Windows and web; pure Dart, MIT licence.

**What it does not have** (no occurrence in its source):

- no client for a running ssh-agent (`SSH_AUTH_SOCK`); its agent support only answers a server that
  forwards agent requests back;
- no reading of `~/.ssh/config` or `known_hosts`;
- no FIDO keys (`sk-ssh-ed25519`, `sk-ecdsa`) and no SSH certificates (`-cert-v01@openssh.com`);
- no post-quantum key exchange (`mlkem768x25519`, `sntrup761`). A current OpenSSH server still offers
  curve25519, so it connects, but not post-quantum.

**Maturity:** 160/160 on pub.dev, about 96,000 downloads in 30 days; the repository moved from
`TerminalStudio/dartssh2` to `vicajilau/dartssh2` (261 stars, one open issue or PR). Eight releases
between 2026-08-17 and 2026-09-04, two with breaking changes. **4.0.0 fixed real security defects**: a
host key changing on rekey was accepted, keyboard-interactive passwords reached the trace log, MACs
were compared in variable time, padding was fixed, and peer key exchange values were not validated.
Since 3.3.0 its tests run against a real OpenSSH server.

## Recommendation

**Beside `ssh`, never instead of it.** One transport interface with two implementations:

- **Desktop keeps running `ssh`.** Replacing it would lose the person's ssh configuration, agent,
  hardware keys, certificates and post-quantum key exchange, and put private keys into the interface.
- **A mobile client uses `dartssh2`**, with the interface owning what OpenSSH did for it: host key
  trust with its own known-hosts store and a first-contact question, key import or generation with a
  passphrase, and storage in the platform keychain.

`VarlinkConnection` is tied to `Socket.connect(socketPath)` today. It has to accept any byte stream,
which is the one change the desktop needs too, and on a phone it is simpler than now: no local socket
file and no process to supervise.

## What must be true

**The interface reaches a machine through a transport it chooses per platform: `ssh` where there is
one, and `dartssh2` where there is not — and a machine reached either way is trusted, authenticated and
supervised to the same standard.**

## Acceptance

- One transport interface covers the forward to the daemon, starting it, `id -u` and a pty session;
  the desktop behaves exactly as before, held by its existing scenarios and integration legs.
- `VarlinkConnection` speaks over a stream, and the socket path is only one way to get one.
- **No connection without a host key decision**: an unknown key is asked about with its fingerprint,
  a changed key refuses the connection, and a remembered key is stored owner-only. `onVerifyHostKey` is
  never null and `disableHostkeyVerification` is never set.
- A private key never leaves the platform keychain unencrypted, and nothing logs a secret.
- The `dartssh2` transport is exercised against a real machine in the integration legs, not only
  against a fake.

## To be checked

- **Whether there is to be a mobile client at all**, which is the operator's decision and more than a
  transport: a phone ends connections in the background, clearance questions have deadlines, and
  notifications would need another path. *Handing off from another device needs no feature of its own*
  assumed a desktop with `ssh`.
- **How keys reach a phone**: generated there and authorized on the machine, or imported — and whether
  hardware-backed keys (Secure Enclave, StrongBox) are required through `SSHIdentity.custom`.
- **Whether a connection without post-quantum key exchange is acceptable** for a mobile client.
- **How a pinned `dartssh2` is kept current**, given how fast it is changing and how recent its
  security fixes are.
