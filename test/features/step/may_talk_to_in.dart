import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: {'sokar-checkout-migrate'} may talk to {'reviewer'}, {'vouched'}, in {'prompt'}
Future<void> mayTalkToIn(WidgetTester tester, String task, String peer, String trust, String mode) async {
  World.backend.peersOf.putIfAbsent(task, () => <TalkPeer>[]).add(TalkPeer(
      name: peer, address: 'local:$peer', trust: trust, perDay: 20, mode: mode, held: false));
}
