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
    for (final root in <String>['doc', 'requirements'])
      ...Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.md')),
  ];
  final live = <String>{
    for (final file in Directory('requirements').listSync().whereType<File>())
      if (RegExp(r'^F\d\d-').hasMatch(file.uri.pathSegments.last))
        file.uri.pathSegments.last.substring(0, 3),
  };

  test('the docs and the requirements were found at all', () {
    // Without this both tests below pass by examining nothing.
    expect(docs, isNotEmpty);
    expect(live, isNotEmpty);
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

  test('every relative link in the docs resolves', () {
    final dead = <String>[
      for (final doc in docs)
        for (final match in RegExp(r'\]\(([^)\s]+)\)').allMatches(doc.readAsStringSync()))
          if (_isDead(doc, match[1]!)) '${doc.path}: ${match[1]}',
    ];
    expect(dead, isEmpty, reason: 'these links point at nothing:\n${dead.join('\n')}');
  });
}

bool _isDead(File doc, String target) {
  if (target.startsWith('http') || target.startsWith('mailto:') || target.startsWith('#')) {
    return false;
  }
  final path = '${doc.parent.path}/${target.split('#').first}';
  return !File(path).existsSync() && !Directory(path).existsSync();
}
