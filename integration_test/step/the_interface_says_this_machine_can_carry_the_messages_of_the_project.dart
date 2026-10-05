import 'package:flutter_test/flutter_test.dart';

import 'the_test_machine_has_a_project_with_a_conversation.dart';

/// Usage: the interface says this machine can carry the messages of the project
Future<void> theInterfaceSaysThisMachineCanCarryTheMessagesOfTheProject(WidgetTester tester) async {
  if (noConversationHere != null) return;
  expect(find.textContaining('This machine can carry its messages now.'), findsOneWidget);
}
