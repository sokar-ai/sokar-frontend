import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Holds the feature files to the one thing the build report reads off them.
///
/// **The `Feature:` line is the report row.** It used to carry a requirement id, and the ids are
/// gone: every requirement file this project had has been finished and deleted, so a row headed
/// `F11` named a document nobody could open. What the row says now is what the file tests, in one
/// short sentence — the only description of it that survives the requirement it came from.
void main() {
  final features = <File>[
    for (final root in <String>['test/features', 'integration_test'])
      if (Directory(root).existsSync())
        ...Directory(root)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.feature')),
  ];

  test('the feature directory was found at all', () {
    // Without this every test below passes by examining nothing.
    expect(features, isNotEmpty);
  });

  test('every feature is named by one short sentence', () {
    for (final file in features) {
      final named = file
          .readAsLinesSync()
          .where((line) => line.startsWith('Feature:'))
          .map((line) => line.substring('Feature:'.length).trim())
          .toList();

      expect(named, hasLength(1), reason: '${file.path} must have exactly one Feature line');
      expect(named.single, isNotEmpty, reason: '${file.path} names nothing');
      // Seventy, because the row is a table cell beside a path and a count. A title that wraps
      // makes the table unreadable at exactly the width somebody scans it.
      expect(named.single.length, lessThanOrEqualTo(70),
          reason: '${file.path}: "${named.single}" is ${named.single.length} characters');
    }
  });

  test('no two features are named the same thing', () {
    final named = <String, String>{};
    for (final file in features) {
      for (final line in file.readAsLinesSync()) {
        if (!line.startsWith('Feature:')) continue;
        final title = line.substring('Feature:'.length).trim();
        // The title is the group key in the summary, the JUnit file and the annotation. Two files
        // sharing one would silently merge into a row that is right about neither.
        expect(named, isNot(contains(title)),
            reason: '${file.path} and ${named[title]} are named the same');
        named[title] = file.path;
      }
    }
  });

  test('no requirement id survives anywhere in the code or the features', () {
    // Every requirement file is finished and deleted. An id left behind points at a document that
    // cannot be opened, which is worse than no reference: it reads as one that can.
    final id = RegExp(r'\bF\d\d\b');
    final offending = <String>[];
    for (final directory in <String>['lib', 'test', 'tool', 'integration_test']) {
      for (final file in Directory(directory).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart') && !file.path.endsWith('.feature')) continue;
        if (file.path == 'test/features_named_test.dart') continue;
        for (final line in file.readAsLinesSync()) {
          if (id.hasMatch(line)) offending.add('${file.path}: ${line.trim()}');
        }
      }
    }
    expect(offending, isEmpty,
        reason: 'requirement ids point at files that no longer exist:\n'
            '${offending.join('\n')}');
  });
}
