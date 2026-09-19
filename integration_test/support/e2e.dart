import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/main.dart' as app;
import 'package:sokar_frontend/src/app/sokar_app.dart';
import 'package:sokar_frontend/src/ui/choice_field.dart';

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
    if (DateTime.now().isAfter(by)) {
      // What was there instead, so a red run says what it saw rather than only what it missed.
      final shown = tester.widgetList<Text>(find.byType(Text)).map((each) => each.data).nonNulls.toList();
      fail('waited ${timeout.inSeconds}s for $what; on screen: $shown');
    }
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
  await choose(tester, 'machine-kind-choice', 'machine-raise-it');
  await goOnInTheWizard(tester);
  await tester.enterText(find.byKey(const Key('machine-host')), E2e.host);
  await tester.enterText(
    find.byKey(const Key('machine-remote-socket')),
    socket,
  );
  await pumpFor(tester);
  await tester.tap(find.byKey(const Key('try-it')));
  await pumpUntil(
    tester,
    () =>
        find.byKey(const Key('host-key-accept')).evaluate().isNotEmpty ||
        find.byKey(const Key('trial-result')).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 30),
    what: 'the trial or the host key question',
  );
  await trustTheHostKeyIfAsked(tester);
  await pumpUntil(
    tester,
    () => find.byKey(const Key('trial-result')).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 30),
    what: 'the trial to say something',
  );
}

/// Goes from the wizard's first page, a name and a kind, to what that kind needs.
Future<void> goOnInTheWizard(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('wizard-next')));
  await pumpFor(tester);
}

/// Trusts the test machine's host key when the wizard shows it. `tool/e2e.sh` writes it to
/// `known_hosts` before the run, so it is normally not asked; if it is, this is a machine the run
/// itself leased.
Future<void> trustTheHostKeyIfAsked(WidgetTester tester) async {
  final trust = find.byKey(const Key('host-key-accept'));
  if (trust.evaluate().isEmpty) return;
  await tester.tap(trust);
  await pumpFor(tester);
}

/// Waits until the machine dialog has closed — it asks the host for its key first, which takes a
/// real round trip — trusting that key if the wizard asks about it.
Future<void> untilTheDialogCloses(WidgetTester tester) async {
  await pumpUntil(
    tester,
    () {
      if (find.byKey(const Key('host-key-accept')).evaluate().isNotEmpty) return true;
      return find.byKey(const Key('watch-it')).evaluate().isEmpty;
    },
    timeout: const Duration(seconds: 30),
    what: 'the machine dialog to close or ask about the host key',
  );
  await trustTheHostKeyIfAsked(tester);
  await pumpUntil(
    tester,
    () => find.byKey(const Key('watch-it')).evaluate().isEmpty,
    timeout: const Duration(seconds: 30),
    what: 'the machine dialog to close',
  );
}

/// Opens the dialog that adds a machine, from the menu bar where it lives.
Future<void> watchAnotherMachine(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Watch another machine…'));
  await pumpFor(tester);
}

/// Chooses [choice] in the drop-down [field]: opened first, then the entry's text in the open menu —
/// the field keeps a copy of every entry for its width, and a tap on that copy chooses nothing.
Future<void> choose(WidgetTester tester, String field, String choice) async {
  await tester.ensureVisible(find.byKey(Key(field)));
  await tester.pump();
  await tester.tap(find.byKey(Key(field)));
  await pumpFor(tester);
  await tester.tap(find.descendant(of: find.byKey(Key(choice)).last, matching: find.byType(Text)));
  await pumpFor(tester);
  final chosen = tester.widget<ChoiceField<Object?>>(find.ancestor(
      of: find.byKey(Key(field)), matching: find.byWidgetPredicate((each) => each is ChoiceField)));
  expect(chosen.choices.where((each) => each.value == chosen.value).map((each) => each.id), [choice],
      reason: 'choosing $choice in $field');
}
