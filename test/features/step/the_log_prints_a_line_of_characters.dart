import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the log prints a line of {'85000'} characters
///
/// One JSON event the length an agent writes a whole conversation in.
Future<void> theLogPrintsALineOfCharacters(WidgetTester tester, String count) async {
  const around = '{"event":""}';
  final line = '{"event":"${'x' * (int.parse(count) - around.length)}"}';
  World.backend.tailing.add(<String>[line]);
  await World.settle(tester);
}
