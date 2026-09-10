import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the build reports, held to the shape GitHub reads rather than to what looks right.
///
/// **The happy path proves nothing about a failure report.** Every escaping rule here only ever
/// matters when something is red, which is the one state a green suite never exercises — so the
/// fixture below is a failure, with the characters that break each rule in it: a percent sign, a
/// newline, a colon and a comma.
void main() {
  late Directory scratch;

  /// One run of one feature with one failing scenario, in `flutter test --machine` shape.
  String machineJson({required String message}) {
    final suite = '${Directory.current.path}/test/features/live_logs_test.dart';
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'type': 'suite',
        'suite': <String, dynamic>{'id': 0, 'path': suite},
      },
      <String, dynamic>{
        'type': 'group',
        'group': <String, dynamic>{'id': 1, 'name': 'F11 Live Log Viewing'},
      },
      <String, dynamic>{
        'type': 'testStart',
        'test': <String, dynamic>{
          'id': 2,
          'name': 'F11 Live Log Viewing only the logs the work actually has are offered',
          'suiteID': 0,
          'groupIDs': <int>[1],
        },
      },
      <String, dynamic>{'type': 'print', 'testID': 2, 'message': message},
      <String, dynamic>{
        'type': 'error',
        'testID': 2,
        'error': 'Test failed. See exception logs above.',
        'stackTrace': '',
      },
      <String, dynamic>{'type': 'testDone', 'testID': 2, 'result': 'failure', 'time': 12},
      <String, dynamic>{'type': 'done', 'time': 12},
    ].map(jsonEncode).join('\n');
  }

  ({String out, String summary, String junit}) report(String json) {
    final source = File('${scratch.path}/results.json')..writeAsStringSync(json);
    final summary = File('${scratch.path}/summary.md');
    final junit = File('${scratch.path}/results.xml');
    final ran = Process.runSync(
      'dart',
      <String>[
        'tool/test_report.dart',
        source.path,
        '${scratch.path}/report.html',
        junit.path,
      ],
      environment: <String, String>{
        'GITHUB_ACTIONS': 'true',
        'GITHUB_STEP_SUMMARY': summary.path,
      },
    );
    return (
      out: '${ran.stdout}',
      summary: summary.existsSync() ? summary.readAsStringSync() : '',
      junit: junit.readAsStringSync(),
    );
  }

  setUp(() => scratch = Directory.systemTemp.createTempSync('report'));
  tearDown(() => scratch.deleteSync(recursive: true));

  test('an annotation is one line, whatever the message contains', () {
    final said = report(machineJson(
      message: 'Expected: one\nActual: none\n100% of it, with a colon: here, and a comma, too',
    ));
    final annotations =
        said.out.split('\n').where((line) => line.startsWith('::error')).toList();

    expect(annotations, hasLength(1));
    // **A workflow command is one line.** A newline would end it and print the rest as ordinary
    // output — visible only in the failure case, which is the case the report exists for.
    expect(annotations.single, contains('%0A'));
    expect(annotations.single, contains('100%25'));
    expect(annotations.single, isNot(contains('\n')));
  });

  test('an annotation lands on the scenario in the feature file, not on generated code', () {
    final said = report(machineJson(message: 'Expected: one\nActual: none'));
    final annotation =
        said.out.split('\n').firstWhere((line) => line.startsWith('::error'));

    // The `.feature` is what a person has to change; the generated test is regenerated, and an
    // edit there is the one edit that gets lost.
    expect(annotation, contains('file=test/features/live_logs.feature'));
    final line = int.parse(
        RegExp(r'line=(\d+)').firstMatch(annotation)!.group(1)!);
    final source = File('test/features/live_logs.feature').readAsLinesSync();
    expect(source[line - 1].trim(),
        'Scenario: only the logs the work actually has are offered');
  });

  test('what the framework printed is the failure, not its own generic sentence', () {
    final said = report(machineJson(message: 'Expected: one\nActual: none'));

    // A widget test's `error` says only "Test failed. See exception logs above." — the whole of
    // what went wrong is in the printed dump. A report built on `error` alone says nothing at
    // exactly the moment somebody needs it.
    expect(said.summary, contains('Actual: none'));
    expect(said.summary, isNot(contains('See exception logs above')));
  });

  test('the requirement is the group in the JUnit file, not the file path', () {
    final said = report(machineJson(message: 'Expected: one\nActual: none'));

    // The id on the `Feature:` line is the whole reason it is there. Grouping by path leaves it
    // an unread prefix inside a test name, which is what a generic converter does.
    expect(said.junit, contains('classname="F11"'));
    expect(said.junit, isNot(contains('sokar_frontend.test.features')));
    expect(said.junit, contains('<failure'));
  });

  test('a requirement is red when any scenario under it is', () {
    final said = report(machineJson(message: 'Expected: one\nActual: none'));

    expect(said.summary, contains('| ❌ | `F11`'));
    expect(said.summary, contains('1 failed'));
  });

  test('a run that produced nothing says so, rather than falling silent', () {
    final summary = File('${scratch.path}/summary.md');
    final ran = Process.runSync(
      'dart',
      <String>[
        'tool/test_report.dart',
        '${scratch.path}/never-written.json',
        '${scratch.path}/report.html',
        '${scratch.path}/results.xml',
      ],
      environment: <String, String>{
        'GITHUB_ACTIONS': 'true',
        'GITHUB_STEP_SUMMARY': summary.path,
      },
    );

    // **Silence covers three states**: no test step, a step that matched nothing, and a step whose
    // run never produced output. A page that says nothing about a run that proved nothing reads
    // exactly like a build that has no test step at all.
    expect(ran.exitCode, isNot(0));
    expect(summary.readAsStringSync(), contains('**No tests ran.**'));
  });

  test('an empty result set is reported, not skipped', () {
    final source = File('${scratch.path}/results.json')..writeAsStringSync('');
    final summary = File('${scratch.path}/summary.md');
    final ran = Process.runSync(
      'dart',
      <String>[
        'tool/test_report.dart',
        source.path,
        '${scratch.path}/report.html',
        '${scratch.path}/results.xml',
      ],
      environment: <String, String>{
        'GITHUB_ACTIONS': 'true',
        'GITHUB_STEP_SUMMARY': summary.path,
      },
    );

    expect(ran.exitCode, isNot(0));
    expect(summary.readAsStringSync(), contains('**No tests ran.**'));
  });

  test('nothing is written to a summary nobody asked for', () {
    final source = File('${scratch.path}/results.json')
      ..writeAsStringSync(machineJson(message: 'Expected: one\nActual: none'));
    final summary = File('${scratch.path}/summary.md');
    final ran = Process.runSync(
      'dart',
      <String>[
        'tool/test_report.dart',
        source.path,
        '${scratch.path}/report.html',
        '${scratch.path}/results.xml',
      ],
      environment: <String, String>{'GITHUB_ACTIONS': 'false', 'GITHUB_STEP_SUMMARY': ''},
    );

    // The two switches are separate on purpose: a summary written to a file nobody set would go
    // nowhere, and an annotation printed outside Actions is noise in somebody's terminal.
    expect('${ran.stdout}', isNot(contains('::error')));
    expect(summary.existsSync(), isFalse);
  });
}
