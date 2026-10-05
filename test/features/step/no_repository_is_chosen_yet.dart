import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: no repository is chosen yet
Future<void> noRepositoryIsChosenYet(WidgetTester tester) async {
  final field = World.fieldOffering(tester, id: 'start-repository-payments-api');
  expect(field, isNotNull, reason: 'no repository is offered');
  expect(field!.value, isNull, reason: 'a repository was chosen for the person');
}
