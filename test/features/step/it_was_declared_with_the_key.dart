import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it was declared with the key {'/home/me/.ssh/id_ed25519'}
Future<void> itWasDeclaredWithTheKey(WidgetTester tester, String path) async {
  final sent = World.backend.declared.single;
  expect(sent.source, 'FILE');
  expect(sent.id, path);
}
