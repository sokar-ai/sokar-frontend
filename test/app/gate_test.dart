import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/app/gate.dart';

import 'fleet_model_test.dart' show aBackendThatRefusesEverything;

/// The gate refuses to be asked about a project it cannot name.
///
/// Unreachable from the interface, which offers no gate for such a project and says why — but a
/// caller could still get here, and opening on nothing would be the wrong answer.
void main() {
  test('a project with no file is not asked about at all', () async {
    final gate = Gate();

    await gate.lookAt(
      aBackendThatRefusesEverything,
      Project.from(const <String, dynamic>{'name': 'unrecorded', 'file': ''}),
    );

    expect(gate.reachable, isFalse);
    expect(gate.problem, contains('No project file is recorded'));
    expect(gate.waiting, isEmpty);
  });
}
