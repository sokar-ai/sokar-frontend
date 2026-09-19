import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: it was declared as {'TOKEN'} for {'https://gitlab.example/acme/'}, kept in {'VAULT'}
Future<void> itWasDeclaredAsForKeptIn(WidgetTester tester, String kind, String match, String source) async {
  final sent = World.backend.declared.single;
  expect(sent.kind, kind);
  expect(sent.match, match);
  expect(sent.source, source);
}
