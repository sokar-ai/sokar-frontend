import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the key this device keeps is nowhere on screen
Future<void> theKeyThisDeviceKeepsIsNowhereOnScreen(WidgetTester tester) async {
  final kept = await World.keys.read(World.backend.nodeId);
  expect(kept, isNotNull, reason: 'nothing was enrolled, so this proves nothing');
  final texts = tester.widgetList<Text>(find.byType(Text)).map((each) => each.data ?? '');
  expect(texts.where((each) => each.contains(kept!.share)), isEmpty);
}
