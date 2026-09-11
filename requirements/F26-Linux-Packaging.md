# F26 — Linux Packaging

**Status:** open — built for `amd64`. `arm64` is out of scope by decision, not by difficulty, and
publishing into the shared repository is the backend's release process rather than this one.

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
no local backend at all, so pulling `sokar` in as a hard
dependency would be wrong for a real way people will use this.

**The build machine sets the floor.** The backend's rule - build on Ubuntu, never Fedora,
because a native image links glibc dynamically - applies here too, and Flutter adds a dimension
the CLI never had: the bundle links the GTK3 stack as well, so the GTK on the build machine is
the oldest GTK the package can run against.

What the running interface does about an update is a different subject; this is only how the
new version arrives.

## Settled, 2026-09-07

- **arm64 is out of scope for now.** Decided rather than deferred: Flutter has no cross-compile
  for Linux desktop, so it needs an arm64 builder, and there is not one. `nfpm.yaml.in` declares
  `amd64` and nothing else, held by a test — a package claiming an architecture nothing builds
  would install on a Pi and not run.
- **The `.desktop` file ships everywhere, headless included.** An entry on a server nobody logs
  into graphically is inert, not wrong, and a split package costs more than one inert file saves.
- **The vendored `libflutter_linux_gtk.so` is not a problem.** It would be refused by the official
  Debian and Fedora archives, and those are not a goal; Sokar's own repository is.

## What was measured while building it

- **A plain `src`/`dst` pair flattens the bundle.** `libapp.so` and `icudtl.dat` land beside the
  launcher instead of under `lib/` and `data/`. The package installs and the application opens no
  window — which is the failure this requirement names, produced by the packaging rather than by a
  missing library. `type: tree` is what avoids it, and a test holds it there.
- **`dpkg-shlibdeps` needs a staged package tree**, not the build directory: `libflutter_linux_gtk.so`
  carries an RPATH of `$ORIGIN`, which it can only resolve against a tree with a `DEBIAN/`
  directory in it. Run against the build directory it warns and analyses less than it should.
- **The derived dependencies carry version floors** — `libgtk-3-0t64 (>= 3.21.4)`,
  `libglib2.0-0t64 (>= 2.80.0)`, and thirteen more — which is what makes *"the build machine sets
  the floor"* a real constraint rather than a note.
- **rpm requires come out of the ELF as sonames**, because nfpm does not run rpm's scanner. Same
  source, same guarantee.
- **The packaged application was run from an extracted tree** and stayed up: the launcher resolves
  its own path through the `/usr/bin` symlink and finds `data/` beside it.
