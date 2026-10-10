# F103 — The Packages Promise The Systems Sokar Supports

**Status:** mostly built on 2026-10-10; the switch to `check-linkage --declared-only` waits for
`sokar-buildtools`' next push.

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
- **The floor is declared and held:** the `.deb` declares it as `libc6 (>= …)` from
  `dpkg-shlibdeps`, the `.rpm` as `libc.so.6(GLIBC_…)(64bit)`, the newest `GLIBC_` symbol version
  any object needs. A floor above Debian 13's glibc 2.41 is refused before anything is published.
  `tool/package.sh` holds it with `objdump -T` for now. Once `sokar-buildtools` publishes
  `check-linkage --declared-only`, the shared command holds it instead:
  `check-linkage --declared-only --declare libc.so.6=GLIBC:<floor> --ceiling GLIBC=2.41`, over
  `sokar_frontend` and `lib/*.so`. `--declared-only` leaves GTK and the bundle's own libraries to the
  dependencies derived from the binary.
- **The build runner stays `ubuntu-22.04`.** Measured on 2026-10-10: the `0.4.2~snapshot.141`
  built there needs `GLIBC_2.34`, and its `.deb` and `.rpm` install in clean `ubuntu:26.04`,
  `debian:13`, `fedora:43` and `fedora:44` with no library missing. The old library names resolve
  on the `t64` systems.
- `doc/` names the supported systems, as Sokar's `getting-started.md` does.

## Acceptance

- **The install check covers exactly the four systems**, and none below them. Seen to fail: a
  package built on Ubuntu 26.04 is refused by the check in `debian:13`, or else installs. Either way
  the result is measured, not assumed.
- **A build that needs more than glibc 2.41 is refused.** Seen to fail: `GLIBC_CEILING=2.30
  tool/package.sh` refuses a bundle that needs 2.38. The same with `check-linkage` once it is
  used.
- **The whole workflow ran green on the VM** before the change is handed over: the install check
  runs in podman on this host as it runs on the runner.

## To be checked

Nothing open.
