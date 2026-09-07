// Turns a test run into one self-contained HTML page: a requirements traceability matrix.
// ignore_for_file: avoid_print - this is a command-line tool; printing is its output.
//
// Usage:
//   flutter test --machine > build/test-results.json
//   dart tool/test_report.dart [build/test-results.json] [build/test-report.html]
//
// Reads `flutter test --machine` JSON rather than the JUnit XML, for two reasons: it is the
// source the XML is made from, so the two cannot disagree, and it carries the failure text and
// the timings that the XML flattens away. No dependencies, so it runs anywhere `dart` does.
//
// The page is deliberately one file with no external stylesheet, script or font: a build
// artifact is downloaded and opened from disk, where anything it had to fetch would be missing.
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final source = File(args.isNotEmpty ? args[0] : 'build/test-results.json');
  final target = File(args.length > 1 ? args[1] : 'build/test-report.html');

  if (!source.existsSync()) {
    stderr.writeln('No test output at ${source.path}.');
    stderr.writeln('Run: flutter test --machine > ${source.path}');
    exitCode = 1;
    return;
  }

  final run = _read(source);
  if (run.results.isEmpty) {
    stderr.writeln('${source.path} contains no test results.');
    exitCode = 1;
    return;
  }

  await target.parent.create(recursive: true);
  await target.writeAsString(_page(run, _requirementsOnDisk()));

  final failed = run.results.where((result) => !result.passed).length;
  print('${target.path}: ${run.results.length} tests, '
      '${failed == 0 ? 'all passed' : '$failed failed'}');
  if (failed > 0) exitCode = 1;
}

/// One scenario or test, as it ran.
class Result {
  Result({required this.name, required this.suite, required this.group});

  /// Full name, which for a scenario is the feature line followed by the scenario.
  final String name;

  /// The file it came from.
  final String suite;

  /// The group it was in, which for a feature file is the `Feature:` line.
  final String group;

  /// Whether it passed.
  bool passed = true;

  /// How long it took.
  Duration took = Duration.zero;

  /// Everything the run said about it going wrong.
  final List<String> problems = <String>[];

  /// The requirement it covers, or null when it covers none.
  ///
  /// Read off the group, which is the `Feature:` line — the whole reason the id lives there.
  String? get requirement => RegExp(r'^(F\d\d)\b').firstMatch(group)?.group(1);

  /// The scenario without the feature in front of it.
  String get scenario =>
      name.startsWith(group) ? name.substring(group.length).trim() : name;
}

/// Everything one run produced.
class Run {
  /// Results, in the order they finished.
  final List<Result> results = <Result>[];

  /// When it ran.
  DateTime at = DateTime.now();

  /// How long the whole run took.
  Duration took = Duration.zero;
}

Run _read(File source) {
  final run = Run();
  final suites = <int, String>{};
  final groups = <int, String>{};
  final open = <int, Result>{};

  for (final line in source.readAsLinesSync()) {
    if (!line.startsWith('{')) continue;
    final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      continue;
    }
    if (decoded is! Map<String, dynamic>) continue;

    switch (decoded['type']) {
      case 'suite':
        final suite = decoded['suite'] as Map<String, dynamic>;
        suites[suite['id'] as int] = '${suite['path']}';
      case 'group':
        final group = decoded['group'] as Map<String, dynamic>;
        groups[group['id'] as int] = '${group['name'] ?? ''}';
      case 'testStart':
        final test = decoded['test'] as Map<String, dynamic>;
        // Hidden tests are the harness's own loading and tear-down steps, not anybody's work.
        if (test['metadata'] is Map && (test['metadata'] as Map)['hidden'] == true) {
          continue;
        }
        final ids = (test['groupIDs'] as List?)?.cast<int>() ?? const <int>[];
        final named = ids
            .map((id) => groups[id] ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        open[test['id'] as int] = Result(
          name: '${test['name']}',
          suite: suites[test['suiteID'] as int] ?? '',
          group: named.isEmpty ? '' : named.last,
        );
      case 'testDone':
        final result = open[decoded['testID'] as int];
        if (result == null) continue;
        if (decoded['hidden'] == true) {
          open.remove(decoded['testID']);
          continue;
        }
        result.passed = decoded['result'] == 'success';
        result.took = Duration(milliseconds: (decoded['time'] as num? ?? 0).toInt());
        run.results.add(result);
      case 'error':
        final result = open[decoded['testID'] as int];
        result?.problems.add(
            '${decoded['error']}\n${decoded['stackTrace'] ?? ''}'.trimRight());
      case 'done':
        run.took = Duration(milliseconds: (decoded['time'] as num? ?? 0).toInt());
    }
  }
  return run;
}

/// Requirement ids that exist, so the report can name the ones nothing covers.
///
/// A matrix that only lists what was tested cannot tell anybody what was not, which is the
/// question somebody reads a traceability report to answer.
Map<String, String> _requirementsOnDisk() {
  final directory = Directory('requirements');
  if (!directory.existsSync()) return const <String, String>{};
  final found = <String, String>{};
  for (final file in directory.listSync().whereType<File>()) {
    final match =
        RegExp(r'^(F\d\d)-(.+)\.md$').firstMatch(file.uri.pathSegments.last);
    if (match == null) continue;
    found[match.group(1)!] = match.group(2)!.replaceAll('-', ' ');
  }
  return found;
}

String _page(Run run, Map<String, String> requirements) {
  final covered = <String, List<Result>>{};
  final others = <String, List<Result>>{};
  for (final result in run.results) {
    final requirement = result.requirement;
    if (requirement != null) {
      covered.putIfAbsent(requirement, () => <Result>[]).add(result);
    } else {
      others.putIfAbsent(result.suite, () => <Result>[]).add(result);
    }
  }

  final ids = covered.keys.toList()..sort();
  final uncovered = requirements.keys.where((id) => !covered.containsKey(id)).toList()
    ..sort();
  final failed = run.results.where((result) => !result.passed).length;

  final page = StringBuffer()
    ..writeln('<!doctype html>')
    ..writeln('<html lang="en"><head><meta charset="utf-8">')
    ..writeln('<meta name="viewport" content="width=device-width, initial-scale=1">')
    ..writeln('<title>Sokar frontend — test report</title>')
    ..writeln('<style>${_style()}</style>')
    ..writeln('</head><body>')
    ..writeln('<header>')
    ..writeln('<h1>Sokar frontend</h1>')
    ..writeln('<p class="run ${failed == 0 ? 'ok' : 'bad'}">'
        '${run.results.length} tests · '
        '${failed == 0 ? 'all passed' : '$failed failed'} · '
        '${_seconds(run.took)} · ${_when(run.at)}</p>')
    ..writeln('</header>');

  page
    ..writeln('<section>')
    ..writeln('<h2>Requirements</h2>')
    ..writeln('<p class="note">One row per requirement, from the <code>Feature:</code> line of '
        'each <code>.feature</code> file. Passing is not the same as covered: a requirement with '
        'one shallow scenario shows as green as one with twelve.</p>');

  for (final id in ids) {
    final scenarios = covered[id]!;
    final broken = scenarios.where((result) => !result.passed).length;
    page
      ..writeln('<article class="${broken == 0 ? 'ok' : 'bad'}">')
      ..writeln('<h3><span class="id">$id</span> ${_escape(_title(scenarios, id))}'
          '<span class="count">${scenarios.length} scenario'
          '${scenarios.length == 1 ? '' : 's'}'
          '${broken == 0 ? '' : ', $broken failed'}</span></h3>')
      ..writeln('<ul>');
    for (final scenario in scenarios) {
      page.writeln('<li class="${scenario.passed ? 'ok' : 'bad'}">'
          '<span class="mark">${scenario.passed ? '✓' : '✗'}</span>'
          '${_escape(scenario.scenario)}'
          '<span class="took">${_seconds(scenario.took)}</span></li>');
      for (final problem in scenario.problems) {
        page.writeln('<pre>${_escape(problem)}</pre>');
      }
    }
    page
      ..writeln('</ul>')
      ..writeln('</article>');
  }

  if (uncovered.isNotEmpty) {
    page
      ..writeln('<article class="none">')
      ..writeln('<h3>No scenario names these yet'
          '<span class="count">${uncovered.length}</span></h3>')
      ..writeln('<ul>');
    for (final id in uncovered) {
      page.writeln('<li class="none"><span class="mark">·</span>'
          '<span class="id">$id</span> ${_escape(requirements[id] ?? '')}</li>');
    }
    page
      ..writeln('</ul>')
      ..writeln('</article>');
  }
  page.writeln('</section>');

  if (others.isNotEmpty) {
    page
      ..writeln('<section>')
      ..writeln('<h2>Everything else</h2>')
      ..writeln('<p class="note">Tests that guard the client, the wire and the rules, rather '
          'than a requirement directly.</p>');
    final suites = others.keys.toList()..sort();
    for (final suite in suites) {
      final tests = others[suite]!;
      final broken = tests.where((result) => !result.passed).length;
      page
        ..writeln('<article class="${broken == 0 ? 'ok' : 'bad'}">')
        ..writeln('<h3>${_escape(_shorten(suite))}'
            '<span class="count">${tests.length} test'
            '${tests.length == 1 ? '' : 's'}'
            '${broken == 0 ? '' : ', $broken failed'}</span></h3>')
        ..writeln('<ul>');
      for (final test in tests) {
        page.writeln('<li class="${test.passed ? 'ok' : 'bad'}">'
            '<span class="mark">${test.passed ? '✓' : '✗'}</span>'
            '${_escape(test.name)}'
            '<span class="took">${_seconds(test.took)}</span></li>');
        for (final problem in test.problems) {
          page.writeln('<pre>${_escape(problem)}</pre>');
        }
      }
      page
        ..writeln('</ul>')
        ..writeln('</article>');
    }
    page.writeln('</section>');
  }

  page.writeln('</body></html>');
  return page.toString();
}

String _title(List<Result> scenarios, String id) {
  final group = scenarios.first.group;
  return group.startsWith(id) ? group.substring(id.length).trim() : group;
}

String _shorten(String path) {
  final index = path.indexOf('/test/');
  return index < 0 ? path : path.substring(index + 1);
}

String _seconds(Duration took) =>
    '${(took.inMilliseconds / 1000).toStringAsFixed(took.inMilliseconds < 1000 ? 2 : 1)} s';

String _when(DateTime at) =>
    '${at.year}-${_two(at.month)}-${_two(at.day)} ${_two(at.hour)}:${_two(at.minute)}';

String _two(int value) => value.toString().padLeft(2, '0');

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _style() => '''
:root {
  --ink: #16211f; --paper: #fbfaf7; --line: #ddd8cf; --quiet: #6b7370;
  --good: #1c6b52; --bad: #a3282a; --none: #8a8378;
}
@media (prefers-color-scheme: dark) {
  :root {
    --ink: #e6e3dc; --paper: #14181a; --line: #2c3335; --quiet: #98a09d;
    --good: #63c4a1; --bad: #e88a86; --none: #7e8683;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0; padding: 2rem 1.25rem 4rem; background: var(--paper); color: var(--ink);
  font: 15px/1.55 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
}
header, section { max-width: 60rem; margin: 0 auto; }
h1 { font-size: 1.5rem; margin: 0 0 .25rem; }
h2 { font-size: 1.1rem; margin: 2.5rem 0 .5rem; }
h3 {
  font-size: .95rem; margin: 0; padding: .6rem .85rem; display: flex;
  align-items: baseline; gap: .6rem; border-bottom: 1px solid var(--line);
}
.run { margin: 0; font-variant-numeric: tabular-nums; }
.run.ok { color: var(--good); } .run.bad { color: var(--bad); }
.note { color: var(--quiet); font-size: .875rem; margin: .25rem 0 1rem; }
article {
  border: 1px solid var(--line); border-radius: 8px; margin: 0 0 .85rem; overflow: hidden;
}
article.bad { border-color: var(--bad); }
.id {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-weight: 600;
  color: var(--quiet);
}
.count { margin-left: auto; color: var(--quiet); font-weight: 400; font-size: .8rem; }
ul { list-style: none; margin: 0; padding: .35rem 0; }
li {
  display: flex; align-items: baseline; gap: .6rem; padding: .25rem .85rem;
}
li.ok .mark { color: var(--good); } li.bad .mark { color: var(--bad); }
li.none { color: var(--quiet); } li.none .mark { color: var(--none); }
.mark { width: 1rem; flex: none; }
.took {
  margin-left: auto; color: var(--quiet); font-size: .8rem; font-variant-numeric: tabular-nums;
}
pre {
  margin: .25rem .85rem .75rem 2.5rem; padding: .7rem .85rem; overflow-x: auto;
  background: rgba(127,127,127,.1); border-left: 3px solid var(--bad); border-radius: 4px;
  font: 12px/1.5 ui-monospace, SFMono-Regular, Menlo, monospace; white-space: pre-wrap;
}
code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: .9em; }
''';
