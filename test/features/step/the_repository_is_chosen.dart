import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: the repository {'payments-api'} is chosen
Future<void> theRepositoryIsChosen(WidgetTester tester, String repository) async {
  expect(World.fieldOffering(tester, id: 'start-repository-$repository')?.value, repository);
}
