import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

import '../support/world.dart';

/// Usage: {'sokar-checkout-migrate'} may talk to {'partner'}, {'external'}, in {'allow'}, held
Future<void> mayTalkToInHeld(WidgetTester tester, String task, String peer, String trust, String mode) async {
  World.backend.peersOf.putIfAbsent(task, () => <TalkPeer>[]).add(TalkPeer(
      name: peer, address: 'spool:$peer', trust: trust, perDay: 20, mode: mode, held: true));
}
