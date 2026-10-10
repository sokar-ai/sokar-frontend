# F103 — The Packages Promise The Systems Sokar Supports

**Status:** open; decided on 2026-10-10.

**What must be true.** The interface's `.deb` and `.rpm` are proven to install and start on exactly
the systems Sokar supports, and they declare the oldest C library they need. A build that would need
more fails before anything is published.

## Why

Sokar supports Ubuntu 26.04, Debian 13, Fedora 43 and Fedora 44, decided on 2026-10-09. Its packages
declare their glibc floor and a check holds it (`sokar-release check-linkage`, a ceiling of glibc
2.41, Debian 13's). The agents do the same.

The interface's packages do neither:
- **The install check** in `build.yml` ("Prove the packages install") runs in `debian:12` and
  `fedora:40`. Debian 12 has no podman 5, so Sokar does not run there, and Fedora 40 is out of
  maintenance. The four supported systems are not checked at all.
- **The floor is whatever the build machine gives.** The Flutter bundle links the system's GTK stack,
  and `dpkg-shlibdeps` writes the `.deb`'s dependencies from the machine it was built on. The
  workflow pins `ubuntu-22.04` for that reason, but nothing checks the result, and a change of runner
  would move the floor silently. Built on Ubuntu 26.04, the `.deb` needs `libc6 (>= 2.38)` and the
  `t64` libraries, and Debian 12 refuses it (measured on 2026-10-09).

## The shape

- **The install check runs in the supported systems:** `ubuntu:26.04`, `debian:13`, `fedora:43` and
  `fedora:44`, each image pinned by its digest. Each one installs the package and starts the binary
  far enough to prove it links, as the check does today with its file tests.
- **The floor is declared and held** with the shared `check-linkage`: `libc.so.6` at most at
  Debian 13's glibc 2.41, as Sokar's. The binaries are `sokar-frontend` and the bundle's own
  libraries under `lib/`.
- **The build runner is chosen for the floor** and named with the reason, as today. Whether it stays
  `ubuntu-22.04` or moves to `ubuntu-24.04` (glibc 2.39, still under 2.41) is decided by what the
  four systems accept.
- `doc/` names the supported systems, as Sokar's `getting-started.md` does.

## Acceptance

- **The install check covers exactly the four systems**, and none below them. Seen to fail: a
  package built on Ubuntu 26.04 is refused by the check in `debian:13`, or else installs. Either way
  the result is measured, not assumed.
- **`check-linkage` refuses a build that needs more than glibc 2.41.** Seen to fail: the check run
  with a ceiling below what the binary needs.
- **The whole workflow ran green on the VM** before the change is handed over: the install check
  runs in podman on this host as it runs on the runner.

## To be checked

- **Which GTK and other library versions** the four systems have, and whether a bundle built on
  `ubuntu-22.04` installs on all of them. The `t64` renaming of Debian 13 and Ubuntu 24.04 onward
  changes package names, not only versions.
