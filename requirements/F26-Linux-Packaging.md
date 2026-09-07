# F26 — Linux Packaging

**Status:** open

The interface installs the way the rest of Sokar installs: `apt install sokar-frontend`,
`dnf install sokar-frontend`. No archive to unpack, no SDK on the machine, no instructions
that begin "first clone".

## What already exists

Measured on 2026-09-07, so the shape of the work is known rather than guessed:

- **A release build is a directory.** `flutter build linux --release` produced a 22 MB bundle
  in 11 s: one ELF binary, `lib/libapp.so` (the AOT-compiled Dart), `lib/libflutter_linux_gtk.so`
  and `data/`. Packaging it is installing a directory, not assembling one.
- **It is self-contained apart from GTK.** The shipped `.so` resolves the system GTK3 stack -
  `libgtk-3.so.0`, `libepoxy`, `libcairo`, `libatk`, and the rest of it. Both `dpkg-shlibdeps`
  and rpm's ELF scanner work that list out on their own; it does not have to be maintained
  by hand.
- **The backend already publishes deb and rpm** from `sokar-dist-deb` and `sokar-dist-rpm`, and
  every shipped agent publishes its own alongside them. This follows that pattern rather than
  inventing one.

## Acceptance

- `apt install sokar-frontend` and `dnf install sokar-frontend` both install a working
  application from the same repository the `sokar` package comes from.
- The application appears in the desktop's application menu, with an icon and a name, and starts
  from it.
- Package dependencies are derived from the binary rather than written down, so a missing
  library is a refused install and never a window that fails to open.
- Upgrading and removing are clean: an upgrade replaces the application and leaves the person's
  own settings, a removal leaves nothing behind but them.
- The package declares which Sokar it works with, and installing it does not force a backend
  onto a machine that only ever talks to a remote one.
- Nothing in the packaging step needs a JDK, and nothing in the backend's build needs a Flutter
  SDK. The two repositories stay independently buildable.

## Notes

**Built with [nfpm](https://nfpm.goreleaser.com/), not Maven.** The backend stamps its packages
with `rpm-maven-plugin` and jdeb, which is right there and wrong here: it would put a JDK back
into a build that deliberately does not have one, and `rpmbuild` on a Debian runner is its own
problem. nfpm is a single static binary that reads one YAML and emits both formats. What has to
match the rest of Sokar is the package a person installs, not the tool that wrote it.

**It goes into the same repository as `sokar`.** This is recorded in the backend's `AGENT.md`
for the agent packages and applies unchanged: a dependency between packages does not resolve
when they are split across configured sources.

**`Recommends`, not `Depends`.** An interface pointed at a remote daemon over SSH is useful with
no local backend at all ([F20](F20-Access-From-Elsewhere.md)), so pulling `sokar` in as a hard
dependency would be wrong for a real way people will use this.

**The build machine sets the floor.** The backend's rule - build on Ubuntu, never Fedora,
because a native image links glibc dynamically - applies here too, and Flutter adds a dimension
the CLI never had: the bundle links the GTK3 stack as well, so the GTK on the build machine is
the oldest GTK the package can run against.

Updating is [F21](F21-Continuity-And-Updates.md)'s subject; this is only how the new version
arrives.

## To be checked

- **Whether arm64 is in scope, and what builds it.** Flutter has no cross-compile for Linux
  desktop, so an arm64 package needs an arm64 builder. This matters more than it looks: Sokar
  runs on a Pi, and a person with one will expect the interface to install there too.
- **Whether the vendored `libflutter_linux_gtk.so` ever becomes a problem.** It is fine in
  Sokar's own repository and would be refused by the official Fedora and Debian archives. Only
  worth solving if getting there is ever a goal.
- **What the package should do about the desktop file on a headless machine.** Installing a
  `.desktop` entry on a server nobody logs into graphically is harmless but pointless, and
  whether that argues for a split package is not obvious enough to decide in advance.
