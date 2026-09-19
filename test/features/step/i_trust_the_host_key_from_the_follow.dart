import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: I trust the host key {'SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU'} from the follow
Future<void> iTrustTheHostKeyFromTheFollow(WidgetTester tester, String fingerprint) async {
  await World.choose(tester, 'host-key-choice', 'host-key-$fingerprint');
  await World.tapInView(tester, 'follow-trust-host-key');
}
