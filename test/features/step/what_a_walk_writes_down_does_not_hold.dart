import 'package:flutter_test/flutter_test.dart';
import 'package:guided_walk/guided_walk.dart';

/// Usage: what a walk writes down does not hold {'pw-1-once'}
///
/// What a guided walk writes into its folder about the window, read as it would be now: a secret
/// on screen is never in it.
Future<void> whatAWalkWritesDownDoesNotHold(WidgetTester tester, String secret) async {
  final written = windowState(tester.binding.rootElement!);
  expect(written, isNotEmpty);
  expect(written, isNot(contains(secret)));
}
