import 'package:flutter_test/flutter_test.dart';

import 'the_project_has_a_conversation_over_reaching_ready.dart';

/// Usage: the messages of {'checkout'} wait because {'the vault is locked'}
Future<void> theMessagesOfWaitBecause(WidgetTester tester, String project, String waits) =>
    conversing(tester, project, 'matrix', '127.0.0.1:8008', ready: true, waits: waits);
