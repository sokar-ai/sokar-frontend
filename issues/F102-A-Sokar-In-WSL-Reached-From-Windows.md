# F102 — A Sokar In WSL Reached From Windows

**Status:** later; decided on 2026-10-10, built in three stages (see *The stages*), the first in the
round after that day's.

**What must be true.** On a Windows machine with Sokar in a WSL2 distribution, the interface runs as
a Windows application on the same machine. It reaches that Sokar with no ssh and no open port, and
only the Windows user who owns the distribution reaches it.

## Why

`sokard` answers only on its unix socket, `$XDG_RUNTIME_DIR/sokar/sokard.sock`. A unix socket does
not cross the boundary of the WSL2 virtual machine: a Windows program cannot connect to it, not even
through `\\wsl$`, although WSL1 could. Today the interface reaches a machine in one of two ways, "this
computer" (the socket on the same Linux host) and "over ssh" (`ssh -L` to a local socket,
`lib/src/app/tunnel.dart`). Neither works from Windows into WSL without an ssh server in the
distribution.

**Not this:** `sokard` listening on TCP at localhost. WSL2 forwards such a port to Windows, where any
program of any user could drive the daemon: start tasks, approve at the gate, open the vault. Today
the socket's file permissions are the only guard, and an open port would remove it.

## The shape

- **A third way to a machine**, beside "this computer" and "over ssh": **a WSL distribution**,
  reached through `wsl.exe -d <distro> -- sokar daemon connect`. That command, which exists already
  for `ssh host sokar daemon connect`, joins standard input and output to the daemon's socket, so
  nothing else, `socat` included, has to be in the distribution.
  This is how Docker Desktop and Podman Desktop reach their WSL machines. No port
  is opened and no key is needed. `wsl.exe` runs as the Windows user, so only that user reaches the
  distribution.
- **`VarlinkConnection` speaks over any byte stream**: the relay's standard input and output here,
  and a socket file as today. This is the same seam [F37](F37-Reach-A-Machine-Without-An-ssh-Binary.md)
  needs; whichever is built first makes it.
- **The machine switcher and the connection wizard offer the WSL way**, listing the distributions
  with `wsl.exe -l -q`. A distribution without Sokar, or with its daemon down, is said in words.
- **A stopped distribution is never started by the interface.** `wsl.exe -d <distro> -- …` would
  start it, with its memory and CPU, so the interface reads each distribution's state with
  `wsl.exe -l -v`, which starts nothing, and calls into one only when it runs. A stopped one is
  shown as stopped, and the person starts it.
- **What the interface runs on a machine through ssh today runs through `wsl.exe` as well**: the
  terminal of a task, attaching to it, a sign-in (`sokar vault login`), and the checks the connection
  trial makes.
- **A Windows build of the interface.** Flutter supports Windows, but only the Linux runner exists
  today, and several parts are Linux-only:
  - **The terminal:** `lib/src/app/pty.dart` opens a pseudoterminal with `dart:ffi` against the libc.
    Windows needs ConPTY behind the same seam.
  - **External programs:** `chmod` (three places), `xdg-open` (two), `notify-send` (one), and `ssh`,
    `ssh-add` and `ssh-keyscan`. On Windows: file rights through ACLs, opening through the shell,
    Windows notifications, and the OpenSSH client Windows ships, for machines still reached over ssh.
  - **Local paths:** the settings, the operations record and temporary sockets take Windows places.
    The `/run/user/…` paths name the far side and stay.
  - **Dependencies:** `xterm`, `flutter_secure_storage` (the Credential Manager instead of libsecret)
    and `file_selector` support Windows. `guided_walk` is to be checked.
  - **The project and the build:** a `windows/` runner (`flutter create --platforms=windows`), and a
    profile per platform in `pom.xml`, whose `flutter.target` is `linux` today. `tool/package.sh` and
    `tool/e2e.sh` are Bash. In `build.yml`, a job on a Windows runner, which costs about twice a Linux
    minute.
  - **Two packages:**
    - **An MSIX**, signed with a self-signed certificate at first. Windows installs an MSIX only
      when its certificate is trusted on that machine, so the certificate is imported once on each
      machine that installs it. A certificate Windows trusts by itself comes before the package is
      offered to people outside the project. The version takes four numbers, so
      `0.4.2~snapshot.141` becomes, for example, `0.4.2.141`.
    - **A ZIP with the `.exe` and what it needs**, offered for download on GitHub, for a person
      who may not install anything on their computer: unpacked and started, with no installation.
    - Where the MSIX is published, beside `sokar-dist-deb` and `sokar-dist-rpm`.

## The stages

Decided on 2026-10-10: the ZIP first, the MSIX after it.

1. **On Linux, in the next round.** `VarlinkConnection` speaks over any byte stream, and the WSL
   entry in `frontend.json` (below) is read and kept, shown as not reachable on Linux. The relay,
   `sokar daemon connect`, exists already. Tested as the Linux build always is: the whole workflow green on
   the VM before the push.
2. **On Windows, in the round after.** The Windows build, the WSL way in the switcher and the wizard,
   and terminals, attach and sign-in through `wsl.exe`. The only package is **the ZIP** with the
   `.exe`, made by a Windows job on GitHub's runner. It is pushed on the operator's word, and then
   the operator tests it on a Windows machine with WSL2, against the published snapshots.
3. **The MSIX**, self-signed at first.

## The machine file, which `sokar-intellij` reads too

The interface keeps its machines in `$XDG_CONFIG_HOME/sokar/frontend.json`, and the IntelliJ plugin
reads the same file. So a new kind of entry is a contract between the two repositories, changed only
after agreement in the channel and in both. Today an entry has `name` and `socket`, and `host` and
`remoteSocket` for a machine behind ssh.

- **A WSL entry:** `{"name": "<label>", "kind": "wsl", "distribution": "<WSL distribution name>"}`.
- **It carries no `socket`.** Today's plugin drops an entry without `socket` silently, so it does not
  open a Linux path on Windows and show a machine that never answers. The socket inside the
  distribution is not stored: it is found on each connection, from the distribution's user id.
- **Entries without `kind`** stay what they are today: a plain socket, or a machine behind ssh when
  `host` and `remoteSocket` are set. An unknown `kind` is kept in the file and shown as not
  reachable by this version, never dropped from the file.
- The plugin's side is `sokar-intellij`'s IJ03, "A Sokar in WSL reached from IntelliJ on Windows",
  blocked by this one.

## Where it touches `sokar`

- **`sokar daemon connect`** is the relay, the one command for it: it joins standard input and
  output to the daemon's socket (`--socket` names another), passes bytes both ways unbuffered,
  exits when either end closes, and says a missing socket on standard error, never on the stream.
  The IntelliJ plugin uses it too. Nothing new for `sokar` to build.
- Nothing else: the interface speaks the same contract over the relay as over a socket.

## Acceptance

- **The interface lists the WSL distributions** of the Windows user and shows, for the one running
  Sokar, its projects and tasks, through `wsl.exe` alone. Seen to fail: on a Windows machine without
  the WSL way, that distribution is not reachable without ssh.
- **A task's terminal is attached and works** (typing, resizing, the way back), through `wsl.exe`.
- **A waiting push is approved at the gate** from the Windows interface, and arrives at the upstream.
- **No ssh and no open port:** while the interface works with the distribution, no `sshd` runs in it
  and `sokard` listens on no TCP port. Seen to fail: a check of the listening sockets during the run.
- **Only the owner reaches it:** a second Windows user on the same machine does not reach the
  distribution's daemon.
- **The machine file keeps every entry:** a WSL entry is written in the shape above, entries without
  `kind` read as before, and an entry of an unknown `kind` survives a load and a save. Seen to fail:
  tests that load and save a file holding all three.
- **Varlink over a byte stream** is proven without a socket file. Seen to fail: a test that speaks
  Varlink over an in-memory stream.
- **The Windows build is tested on GitHub's Windows runner**: unit, feature and documents tests, and
  the ZIP built (stage 2), then the MSIX built and installed (stage 3). This is decided as the one
  exception to "the whole workflow green on the VM before a push", since there is no Windows machine
  here; the Linux build keeps the rule. After stage 2's push, the operator tests the ZIP on a
  Windows machine with WSL2.
- **A stopped distribution stays stopped:** with the distribution stopped, the interface shows it
  as stopped and it is still stopped afterwards. Seen to fail: the same with a call that starts it.

## To be checked

- **How the socket is found** inside the distribution without a login shell, since
  `$XDG_RUNTIME_DIR` is set only in a user session: whether `sokar daemon connect` finds its
  account's socket by itself when `wsl.exe` starts it, or is given `--socket` from `id -u`.
- **Where the MSIX and the ZIP are published**, and which certificate replaces the self-signed one.
