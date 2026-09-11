import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/main.dart' as app;
import 'package:sokar_frontend/src/app/sokar_app.dart';

/// The machine these tests run against, as `tool/e2e.sh` names it.
abstract final class E2e {
  /// What the dialog is told to call it.
  static const name = 'e2e machine';

  /// Where it is, as ssh would be given it.
  static String get host => _required('SOKAR_E2E_HOST');

  /// Its daemon's socket, on that machine. Asked of the machine, never guessed: the uid differs.
  static String get remoteSocket => _required('SOKAR_E2E_REMOTE_SOCKET');

  static String _required(String variable) {
    final value = Platform.environment[variable] ?? '';
    if (value.isEmpty) throw StateError('$variable is not set: run these through tool/e2e.sh');
    return value;
  }
}

/// Shows the interface, composed once for the whole run and shown again for each scenario.
Future<SokarApp> showTheInterface(WidgetTester tester) async {
  final interface = await app.sokar();
  await tester.pumpWidget(interface);
  await pumpUntil(tester, () => find.byKey(const Key('machine-tree')).evaluate().isNotEmpty);
  return interface;
}

/// Real time, not fake: the machine is real, and only waiting lets its answers arrive.
Future<void> pumpFor(WidgetTester tester, [Duration wait = const Duration(milliseconds: 300)]) async {
  await Future<void>.delayed(wait);
  await tester.pump();
}

/// Pumps until [done] holds, and fails naming [what] when it never does.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 15),
  String what = 'the window',
}) async {
  final by = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(by)) fail('waited ${timeout.inSeconds}s for $what');
    await pumpFor(tester, const Duration(milliseconds: 200));
  }
}

/// Makes [name] the machine acted on, through the switcher a person would use.
Future<void> switchTo(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(ValueKey<String>('waiting-count $name')));
  await pumpFor(tester);
}

/// Fills the dialog for a forward to the test machine with [socket] there, and tries it.
Future<void> tryFromTheDialog(WidgetTester tester, String socket) async {
  await watchAnotherMachine(tester);
  await tester.enterText(find.byKey(const Key('machine-name')), 'e2e trial');
  await tester.tap(find.byKey(const Key('machine-raise-it')));
  await pumpFor(tester);
  await tester.enterText(find.byKey(const Key('machine-host')), E2e.host);
  await tester.enterText(
    find.byKey(const Key('machine-remote-socket')),
    socket,
  );
  await pumpFor(tester);
  await tester.tap(find.byKey(const Key('try-it')));
  await pumpUntil(
    tester,
    () => find.byKey(const Key('trial-result')).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 30),
    what: 'the trial to say something',
  );
}

/// Opens the dialog that adds a machine, from the menu bar where it lives.
Future<void> watchAnotherMachine(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Watch another machine…'));
  await pumpFor(tester);
}
