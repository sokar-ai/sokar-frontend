import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/fleet_backend.dart';

void main() {
  // Measured on Sokar 213: Start raises NoSuchDestination before anything exists, naming the entry.
  test("Start's refusal of a credential nobody can reach is said in words, naming the entry", () async {
    final refused = Stream<StartProgress>.error(
      const VarlinkException('org.fuin.sokar.Tasks1.NoSuchDestination', <String, dynamic>{'name': 'f56-extra'}),
    ).transform(destinationRefusalsSaid);
    await expectLater(
      refused,
      emitsError(isA<NoSuchDestination>().having((it) => '$it', 'words',
          contains('The credential f56-extra is for a destination this machine does not declare. Nothing was started'))),
    );
  });

  test('any other error passes as it came', () async {
    const other = VarlinkException('org.fuin.sokar.Tasks1.NoSuchProject', <String, dynamic>{});
    final passed = Stream<StartProgress>.error(other).transform(destinationRefusalsSaid);
    await expectLater(passed, emitsError(same(other)));
  });
}
