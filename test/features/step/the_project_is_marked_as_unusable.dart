import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';

/// Usage: the project {'unrecorded'} is marked as unusable
Future<void> theProjectIsMarkedAsUnusable(WidgetTester tester, String project) async {
  await lookingAtTheProjects(tester, () async {
    expect(
      find.descendant(of: cardFor(project), matching: find.byIcon(Icons.link_off)),
      findsOneWidget,
      reason: 'nothing can act on it, and the card has to say so',
    );
  });
}
