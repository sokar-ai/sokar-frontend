@Tags(<String>['documents'])
library;

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
      if (RegExp(r'^F\d{2,3}(?=-)').firstMatch(file.uri.pathSegments.last) case final number?)
        number[0]!,
  };

  test('the docs and the issues were found at all', () {
    // Without this both tests below pass by examining nothing.
    expect(docs, isNotEmpty);
    expect(live, isNotEmpty);
  });

  /// The decisions document's own index.
  ///
  /// **An index maintained by hand is a second copy of the truth**, and two copies is how one
  /// becomes wrong. Rather than generating the table, this holds it to the sections.
  group('the decisions index', () {
    final decisions = File('doc/decisions.md').readAsLinesSync();
    final sections = <String>[
      for (final line in decisions)
        if (line.startsWith('## ')) line.substring(3).trim(),
    ];
    final rows = <String>[
      for (final line in decisions)
        if (line.startsWith('| [')) line,
    ];

    test('every decision has a row and every row a decision, in the same order', () {
      expect(sections, isNotEmpty);
      expect(rows, hasLength(sections.length),
          reason: 'the table and the document disagree on how many decisions there are');
      for (final (index, section) in sections.indexed) {
        final anchor = section
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9 _-]'), '')
            .replaceAll(' ', '-');
        expect(rows[index], contains('(#$anchor)'),
            reason: 'the link in row ${index + 1} does not reach section ${index + 1}, "$section"');
      }
    });

    test('no decision carries a date', () {
      // When a decision was taken is in git; a date in a description is stale the day after.
      final dated = [
        for (final line in decisions)
          if (RegExp(r'\b\d{4}-\d\d-\d\d\b').hasMatch(line)) line,
      ];
      expect(dated, isEmpty, reason: 'these lines carry a date:\n${dated.join('\n')}');
    });
  });

  test('every requirement id in the docs has a file', () {
    final stale = <String>[
      for (final doc in docs)
        for (final line in doc.readAsLinesSync())
          for (final id in RegExp(r'\bF\d{2,3}\b').allMatches(line).map((match) => match[0]!))
            if (!live.contains(id)) '${doc.path}: $id',
    ];
    expect(stale, isEmpty, reason: 'these name a requirement whose file is gone:\n${stale.join('\n')}');
  });

  test('the published pages name no issue of any Sokar repository', () {
    // doc/ is published on the documentation site, and an issue is deleted once it is built, so a
    // number there points a reader at nothing. The page names the thing instead.
    final cited = <String>[
      for (final doc in docs)
        if (doc.path.startsWith('doc/'))
          for (final (index, line) in doc.readAsLinesSync().indexed)
            for (final id in _issueNumber.allMatches(line)) '${doc.path}:${index + 1}: ${id[0]}',
    ];
    expect(cited, isEmpty, reason: 'these pages cite an issue number:\n${cited.join('\n')}');
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

/// An issue number of any repository: one or two capitals and two or three digits, with no list of
/// prefixes to keep.
final _issueNumber = RegExp(r'\b[A-Z]{1,2}\d{2,3}\b');

/// A link to a requirement's own file, which the index alone may write.
final _byFile = RegExp(r'\]\(([^)\s]*F\d{2,3}-[^)\s]*\.md)\)');

bool _isDead(File doc, String target) {
  if (target.startsWith('http') || target.startsWith('mailto:') || target.startsWith('#')) {
    return false;
  }
  final path = '${doc.parent.path}/${target.split('#').first}';
  return !File(path).existsSync() && !Directory(path).existsSync();
}
