import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Holds the documentation to what exists.
///
/// **A finished requirement's file is deleted**, and a pointer to it still reads as one that can be
/// followed. The index once linked five files it said two paragraphs earlier were gone, and the
/// document every newcomer was told to read first described a contract that no longer existed.
void main() {
  // The channel transcript is history and is never edited, so it is not read here.
  final docs = <File>[
    for (final file in Directory('.').listSync().whereType<File>())
      if (file.path.endsWith('.md') && !file.uri.pathSegments.last.startsWith('.')) file,
    for (final root in <String>['doc', 'issues'])
      ...Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.md')),
  ];
  final live = <String>{
    for (final file in Directory('issues').listSync().whereType<File>())
      if (RegExp(r'^F\d\d-').hasMatch(file.uri.pathSegments.last))
        file.uri.pathSegments.last.substring(0, 3),
  };

  test('the docs and the issues were found at all', () {
    // Without this both tests below pass by examining nothing.
    expect(docs, isNotEmpty);
    expect(live, isNotEmpty);
  });

  /// The decisions document's own index.
  ///
  /// **An index maintained by hand is a second copy of the truth**, and two copies is how one
  /// becomes wrong: both agents on this channel found an index lying about its own document within
  /// the same hour on 2026-09-12. Rather than generating the table, this holds it to the sections.
  group('the decisions index', () {
    final decisions = File('doc/decisions.md').readAsLinesSync();
    final sections = <String>[
      for (final line in decisions)
        if (line.startsWith('## ')) line.substring(3).trim(),
    ];
    final rows = <String>[
      for (final line in decisions)
        if (RegExp(r'^\| \d{4}-\d\d-\d\d \|').hasMatch(line)) line,
    ];

    test('every decision has a row and every row a decision', () {
      expect(sections, isNotEmpty);
      expect(rows, hasLength(sections.length),
          reason: 'the table and the document disagree on how many decisions there are');
      for (final (index, section) in sections.indexed) {
        // The row's date is the section's date, and its link is the section's anchor.
        final date = section.split(' — ').first;
        expect(rows[index], contains(date),
            reason: 'row ${index + 1} is not the decision it sits above');
        final anchor = section
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9 _-]'), '')
            .replaceAll(' ', '-');
        expect(rows[index], contains('(#$anchor'),
            reason: 'the link in row ${index + 1} does not reach its own section');
      }
    });

    test('newest first, so the top row is what changed last', () {
      final dates = <String>[
        for (final row in rows) row.split('|')[1].trim(),
      ];
      final sorted = <String>[...dates]..sort((a, b) => b.compareTo(a));
      expect(dates, sorted);
    });
  });

  test('every requirement id in the docs has a file', () {
    final stale = <String>[
      for (final doc in docs)
        for (final line in doc.readAsLinesSync())
          for (final id in RegExp(r'\bF\d\d\b').allMatches(line).map((match) => match[0]!))
            if (!live.contains(id)) '${doc.path}: $id',
    ];
    expect(stale, isEmpty, reason: 'these name a requirement whose file is gone:\n${stale.join('\n')}');
  });

  test('nothing but the index links a requirement by its file', () {
    // A finished requirement's file is deleted, so a link to it breaks exactly when that
    // requirement succeeds. The index links the numbers; everywhere else names the index.
    final byFile = <String>[
      for (final doc in docs)
        if (doc.path != 'issues/README.md')
          for (final match in _byFile.allMatches(doc.readAsStringSync()))
            '${doc.path}: ${match[1]}',
    ];
    expect(byFile, isEmpty,
        reason: 'these name a requirement by its file:\n${byFile.join('\n')}');
  });

  test('every relative link in the docs resolves', () {
    final dead = <String>[
      for (final doc in docs)
        for (final match in RegExp(r'\]\(([^)\s]+)\)').allMatches(doc.readAsStringSync()))
          if (_isDead(doc, match[1]!)) '${doc.path}: ${match[1]}',
    ];
    expect(dead, isEmpty, reason: 'these links point at nothing:\n${dead.join('\n')}');
  });
}

/// A link to a requirement's own file, which the index alone may write.
final _byFile = RegExp(r'\]\(([^)\s]*F\d\d-[^)\s]*\.md)\)');

bool _isDead(File doc, String target) {
  if (target.startsWith('http') || target.startsWith('mailto:') || target.startsWith('#')) {
    return false;
  }
  final path = '${doc.parent.path}/${target.split('#').first}';
  return !File(path).existsSync() && !Directory(path).existsSync();
}
