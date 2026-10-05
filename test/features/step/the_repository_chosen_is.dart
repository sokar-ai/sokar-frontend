import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the repository chosen is {'payments-api'}
Future<void> theRepositoryChosenIs(WidgetTester tester, String repository) async {
  final field = World.fieldOffering(tester, id: 'start-repository-$repository');
  expect(field, isNotNull, reason: '$repository is not offered');
  expect(field!.value, repository);
}
