import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the machine never saw the forge's token
Future<void> theMachineNeverSawTheForgesToken(WidgetTester tester) async {
  final told = <String>[
    for (final each in World.backend.follows) '${each.url} ${each.signedBy}',
    for (final each in World.backend.deployKeysMade) '${each.upstream} ${each.publicKey}',
  ];
  expect(told.where((each) => each.contains('ghp_accepted')), isEmpty);
}
