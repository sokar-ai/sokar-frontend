import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the packaging promises, held to without building a package.
///
/// Building one takes a release build and two external tools, so it belongs in `tool/package.sh`
/// and on a build machine. What belongs here is everything that can go wrong quietly: a desktop
/// entry pointing at a binary by a name the package does not install, a dependency list that
/// somebody started writing down, an architecture claimed that nothing builds.
void main() {
  final commented = File('packaging/nfpm.yaml.in').readAsStringSync();

  // Comments stripped before anything is asserted. Every rule below is also *explained* in that
  // file, so a plain `contains` matches the sentence describing a directive as readily as the
  // directive — which is how the first version of this passed with the bundle flattened.
  final template = commented
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('#'))
      .join('\n');
  final desktop = File('packaging/sokar-frontend.desktop').readAsStringSync();

  String desktopField(String key) => desktop
      .split('\n')
      .firstWhere((line) => line.startsWith('$key='), orElse: () => '$key=')
      .substring(key.length + 1)
      .trim();

  test('the desktop entry starts the binary the package actually installs', () {
    // The entry in /usr/bin is a symlink named sokar-frontend; the bundle's own launcher is
    // sokar_frontend, with an underscore. Pointing Exec at the wrong one gives a menu entry that
    // does nothing, and nothing about installing the package would say so.
    expect(desktopField('Exec'), 'sokar-frontend');
    expect(template, contains('dst: /usr/bin/sokar-frontend'));
    expect(template, contains('type: symlink'));
  });

  test('the desktop entry names an icon the package installs', () {
    final icon = desktopField('Icon');

    expect(icon, isNotEmpty);
    expect(template, contains('$icon.svg'));
    expect(File('packaging/$icon.svg').existsSync(), isTrue);
  });

  test('the desktop entry has what a menu needs to draw it', () {
    for (final key in <String>['Type', 'Name', 'Comment', 'Categories']) {
      expect(desktopField(key), isNotEmpty, reason: '$key is what a menu draws');
    }
    expect(desktopField('Type'), 'Application');
  });

  test('dependencies are not written down anywhere', () {
    // The criterion is that they are derived from the binary. A hand-written list goes stale the
    // first time Flutter changes what it links, and the failure is a package that installs and
    // then opens no window — so the template must carry none at all.
    expect(template.contains('\ndepends:'), isFalse,
        reason: 'dependencies belong to dpkg-shlibdeps and the ELF, not to this file');
    expect(template.contains('\nrequires:'), isFalse);
  });

  test('the backend is recommended, never required', () {
    // An interface pointed at a remote daemon over a forwarded socket is useful with no local
    // backend at all, so a hard dependency would put one on a laptop that never needed it.
    expect(template, contains('recommends:'));
    expect(template, contains('- sokar'));
  });

  test('the bundle is installed as a tree, not flattened into one directory', () {
    // A plain src/dst pair puts libapp.so and icudtl.dat beside the launcher instead of under
    // lib/ and data/. The package installs; the application then finds nothing and opens no
    // window. This shipped once in this repository before it was caught.
    expect(template, contains('type: tree'));
  });

  test('nothing claims an architecture nothing builds', () {
    // Flutter has no cross-compile for Linux desktop, so an arm64 package needs an arm64 builder
    // and there is not one. Claiming the architecture would produce a package that installs on a
    // Pi and cannot run.
    expect(template, contains('arch: amd64'));
    expect(template.contains('arm64'), isFalse);
  });

  test('the version comes from pubspec rather than being kept in two places', () {
    expect(template, contains('@VERSION@'));
    final script = File('tool/package.sh').readAsStringSync();
    expect(script, contains('pubspec.yaml'));
  });

  test('the packaging script refuses to ship either format with no dependencies', () {
    // The derivation failing silently is the dangerous outcome: an empty list is a package that
    // installs anywhere and runs nowhere. Both formats derive separately, so both are named
    // separately — one message covering both would let either guard be removed unnoticed.
    final script = File('tool/package.sh').readAsStringSync();
    expect(script, contains('refusing to ship a deb with no dependencies'));
    expect(script, contains('refusing to ship an rpm with no dependencies'));
  });
}
