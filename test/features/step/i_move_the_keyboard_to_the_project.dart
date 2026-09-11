import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I move the keyboard to the project {'billing'}
///
/// Tab, and nothing else: a card that the keyboard cannot reach is one only a pointer can use.
Future<void> iMoveTheKeyboardToTheProject(WidgetTester tester, String project) async {
  for (var press = 0; press < 80; press++) {
    final focused = FocusManager.instance.primaryFocus?.context;
    var there = false;
    focused?.visitAncestorElements((element) {
      there = element.widget.key == ValueKey<String>('project $project');
      return !there;
    });
    if (there || focused?.widget.key == ValueKey<String>('project $project')) return;
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  await World.settle(tester);
  fail('the keyboard never reached the project $project');
}
