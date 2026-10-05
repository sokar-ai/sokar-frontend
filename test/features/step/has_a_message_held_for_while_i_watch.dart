import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: {'sokar-checkout-shell'} has a message held for {'reviewer'} while I watch
Future<void> hasAMessageHeldForWhileIWatch(WidgetTester tester, String task, String peer) async {
  final message = World.holdAMessage(task: task, peer: peer, text: 'held while watched', standing: 'held', reason: 'moderation: prompt');
  World.backend.talking.add(TalkEvent(
      task: task, at: message.at, event: 'held', message: message.message, id: message.id, peer: peer, detail: ''));
  await World.settle(tester);
}
