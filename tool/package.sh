#!/usr/bin/env bash
#
# Builds sokar-frontend as a .deb and a .rpm.
#
# Two things this script exists to get right, and they are the two acceptance criteria that are
# easy to fake:
#
#   * Dependencies are DERIVED FROM THE BINARY, never written down. A hand-written list goes stale
#     the first time Flutter changes what it links, and the failure is a package that installs and
#     then opens no window. `dpkg-shlibdeps` reads the ELF for the Debian side and gives version
#     floors with it; the RPM side takes the sonames straight out of the ELF, which is the same
#     thing rpm's own scanner would have produced.
#
#   * The build machine sets the floor. The bundle links the system GTK3 stack, so the GTK here is
#     the oldest GTK the package can run against. Build on the oldest distribution you intend to
#     support — for Sokar that means Ubuntu, never Fedora.
#
# Not Maven, deliberately: the backend stamps its packages with rpm-maven-plugin and jdeb, which
# would put a JDK back into a build that does not have one. What has to match the rest of Sokar is
# the package somebody installs, not the tool that wrote it.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$here"

base="${1:-$(grep -m1 '^version:' pubspec.yaml | sed 's/version: *//' | tr -d '[:space:]')}"

# Every build of `main` replaces the packages in a repository called `snapshots`, so each one has
# to supersede the last or `apt upgrade` has nothing to do and nobody ever moves off the build
# they first installed. The run number does that; `~` keeps the whole series below the eventual
# release.
#
# Matching the backend's `0.1.0~snapshot.<run>` exactly, so both sets of packages sort the same
# way in one repository. The counters are separate on purpose — a package only ever has to
# supersede its own predecessor.
run="${SNAPSHOT_RUN:-0}"
version="$base~snapshot.$run"
out="${OUT_DIR:-build/packages}"
bundle="build/linux/x64/release/bundle"
nfpm="${NFPM:-nfpm}"

say() { printf '\n== %s\n' "$*"; }

command -v "$nfpm" >/dev/null || {
  echo "nfpm is not on PATH. It is one static binary:" >&2
  echo "  https://github.com/goreleaser/nfpm/releases" >&2
  exit 1
}

# Asked of dpkg on the version actually built, rather than reasoned about. The trap is lexical
# comparison: if `10` did not beat `9` the scheme would keep working for nine builds and then
# quietly stop.
say "Checking the version supersedes the last one: $version"
case "$version" in
  *~SNAPSHOT|*-SNAPSHOT)
    echo "a flat snapshot never supersedes the last one: $version" >&2; exit 1 ;;
esac
dpkg --compare-versions "$version" lt "$base" \
  || { echo "$version should sort below the release $base" >&2; exit 1; }
dpkg --compare-versions "$version" lt "$base~snapshot.$((run + 1))" \
  || { echo "$version should sort below the next build" >&2; exit 1; }
dpkg --compare-versions "$base~snapshot.9" lt "$base~snapshot.10" \
  || { echo "digit runs are being compared lexically; build 10 would not beat build 9" >&2; exit 1; }

say "Building the release bundle"
flutter build linux --release

test -x "$bundle/sokar_frontend" || { echo "no bundle at $bundle" >&2; exit 1; }

# The ELF objects that decide what this package needs: the launcher and everything shipped beside
# it. libapp.so is our own AOT-compiled Dart and libflutter_linux_gtk.so is vendored, so neither is
# a dependency — but both are scanned, because what *they* link is.
mapfile -t objects < <(
  printf '%s\n' "$bundle/sokar_frontend"
  find "$bundle/lib" -name '*.so' | sort
)

say "Deriving Debian dependencies from ${#objects[@]} ELF objects"
# Staged into a package tree first, and not out of tidiness: libflutter_linux_gtk.so has an RPATH
# of $ORIGIN, which dpkg-shlibdeps can only resolve against a real tree with a DEBIAN/ directory
# in it. Run against the build directory it warns and analyses less than it should.
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
installed="$staging/debian/sokar-frontend/usr/lib/sokar-frontend"
mkdir -p "$installed" "$staging/debian/sokar-frontend/DEBIAN"
printf 'Source: sokar-frontend\n\nPackage: sokar-frontend\nArchitecture: amd64\n' \
  > "$staging/debian/control"
cp -r "$bundle/." "$installed/"

# -O prints to stdout instead of writing debian/substvars; --ignore-missing-info keeps a vendored
# .so with no shlibs entry from failing the run rather than being skipped.
depends="$(
  cd "$staging" && dpkg-shlibdeps -O --ignore-missing-info \
    debian/sokar-frontend/usr/lib/sokar-frontend/sokar_frontend \
    debian/sokar-frontend/usr/lib/sokar-frontend/lib/*.so 2>/dev/null |
    sed -n 's/^shlibs:Depends=//p'
)"
test -n "$depends" || { echo "dpkg-shlibdeps derived nothing; refusing to ship a deb with no dependencies" >&2; exit 1; }
echo "$depends"

say "Deriving RPM requires from the same objects"
# rpm's own scanner would emit soname requires; nfpm does not run it, so they come straight out of
# the ELF. Anything shipped inside this package is dropped: a package must not require itself.
mapfile -t shipped < <(find "$bundle/lib" -name '*.so' -printf '%f\n')
requires="$(
  for object in "${objects[@]}"; do
    objdump -p "$object" | awk '/NEEDED/ {print $2}'
  done | sort -u | while read -r soname; do
    for own in "${shipped[@]}"; do
      [ "$soname" = "$own" ] && continue 2
    done
    echo "${soname}()(64bit)"
  done
)"
test -n "$requires" || { echo "no sonames found; refusing to ship an rpm with no dependencies" >&2; exit 1; }
echo "$requires"

say "Writing the nfpm configuration"
mkdir -p "$out"
config="$out/nfpm.yaml"
{
  sed -e "s|@VERSION@|$version|g" packaging/nfpm.yaml.in
  echo "depends:"
  # One entry per constraint. `dpkg-shlibdeps` answers them comma-separated on one line.
  echo "$depends" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | while read -r one; do
    [ -n "$one" ] && printf '  - %s\n' "\"$one\""
  done
  echo "overrides:"
  echo "  rpm:"
  echo "    depends:"
  echo "$requires" | while read -r one; do
    [ -n "$one" ] && printf '      - %s\n' "\"$one\""
  done
} > "$config"

say "Packaging"
"$nfpm" package --config "$config" --packager deb --target "$out"
"$nfpm" package --config "$config" --packager rpm --target "$out"

say "What was built"
ls -1 "$out"/*.deb "$out"/*.rpm
