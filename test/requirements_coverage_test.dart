import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Holds the feature files against the requirements they claim to cover.
///
/// Two directions, because only one of them is obvious. A feature naming a requirement that does
/// not exist is a typo or a deleted requirement, and would otherwise sit there looking like
/// coverage. A requirement no feature names is untested, and would otherwise be discovered by
/// somebody shipping it.
///
/// [pending] is a ratchet, not a suppression list: it must match the uncovered set exactly, so
/// covering a requirement fails until it is removed from here, and removing it early fails too.
void main() {
  /// Requirements no feature covers yet. Shrink this; never grow it without saying why.
  ///
  /// `F26` is expected to stay: it is about installing a package, which no widget test can
  /// exercise. It is proven by the packaging job instead.
  /// `F09` grew this list once, deliberately and only once. The feature naming it was the
  /// scaffold's placeholder scenario — `Given the app is running, Then the placeholder is
  /// shown` — which asserted the text F01 replaced. It read as coverage and was not: nothing in
  /// it exercised stopping, restarting or deleting work. It is back here until F09 is built.
  const pending = <String>{
    'F02', 'F03', 'F04', 'F05', 'F06', 'F07', 'F08', 'F10',
    'F12', 'F14', 'F15', 'F16', 'F17', 'F18', 'F19', 'F20', 'F21',
    'F22', 'F23', 'F24', 'F25', 'F26',
  };

  final requirements = Directory('requirements')
      .listSync()
      .whereType<File>()
      .map((file) => RegExp(r'^(F\d\d)-').firstMatch(file.uri.pathSegments.last)?.group(1))
      .whereType<String>()
      .toSet();

  final claimed = <String, String>{};
  for (final file in Directory('test/features').listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.feature')) continue;
    for (final line in file.readAsLinesSync()) {
      final match = RegExp(r'^\s*Feature:\s*(F\d\d)\b').firstMatch(line);
      if (match != null) claimed[match.group(1)!] = file.path;
    }
  }

  test('the requirements directory was found at all', () {
    // Without this the two tests below pass by comparing nothing to nothing.
    expect(requirements, isNotEmpty);
  });

  test('every feature names a requirement that exists', () {
    final unknown = {
      for (final entry in claimed.entries)
        if (!requirements.contains(entry.key)) entry.key: entry.value,
    };
    expect(unknown, isEmpty,
        reason: 'these features name requirements that are not in requirements/');
  });

  test('every requirement is named by a feature, except those still pending', () {
    final uncovered = requirements.difference(claimed.keys.toSet());
    expect(
      uncovered,
      equals(pending),
      reason: 'update `pending` in this file: it must list exactly the uncovered requirements.\n'
          'Covered since it was last edited: ${pending.difference(uncovered).toList()..sort()}\n'
          'Uncovered and not listed:        ${uncovered.difference(pending).toList()..sort()}',
    );
  });

  test('a feature line carries the requirement id and nothing else does', () {
    // The id in a scenario name would churn every time a criterion is reworded, and would split
    // one requirement across several JUnit groups.
    for (final file in Directory('test/features').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.feature')) continue;
      for (final line in file.readAsLinesSync()) {
        if (RegExp(r'^\s*Scenario').hasMatch(line)) {
          expect(RegExp(r'\bF\d\d\b').hasMatch(line), isFalse,
              reason: 'requirement id belongs on the Feature line, not in ${file.path}: $line');
        }
      }
    }
  });
}
