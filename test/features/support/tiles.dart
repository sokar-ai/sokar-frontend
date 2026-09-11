import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tile for one piece of work, matched on its key rather than on text it happens to show.
Finder tileFor(String work) => find.byWidgetPredicate(
    (widget) => widget is Card && '${widget.key}'.contains("'tile ") && '${widget.key}'.endsWith(" $work'>]"));

/// The card of one project on the machine being looked at.
Finder cardFor(String project) => find.byKey(ValueKey<String>('project $project'));

/// The rail entry of one machine, by the badge every entry carries.
Finder railEntryFor(String machine) => find.byKey(ValueKey<String>('waiting-count $machine'));

/// Brings [target] on screen and taps it.
Future<void> tapOnScreen(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target.first);
  await tester.pump();
  await tester.tap(target.first);
}

/// Everything a piece of work's tile says, as one line.
String whatItSaysAbout(WidgetTester tester, String work) => <String>[
      for (final text in tester.widgetList<Text>(
          find.descendant(of: tileFor(work), matching: find.byType(Text))))
        text.data ?? text.textSpan?.toPlainText() ?? '',
    ].join(' ');

/// Presses what the finder marked where it went, when it went somewhere rather than running.
Future<void> followTheFinder(WidgetTester tester) async {
  final there = find.byKey(const Key('highlighted'));
  if (there.evaluate().isEmpty) return;
  await tester.tap(there.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 350));
}
