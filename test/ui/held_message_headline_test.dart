import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/ui/held_message_view.dart';

/// A held message's heading says whose it is (walk 8: "A question going out from a person" did not).
void main() {
  HeldMessage held(String role) => HeldMessage.from(<String, dynamic>{
        'task': 'sokar-test-project-foo',
        'standing': 'held',
        'message': 'm.json',
        'role': role,
        'peer': 'michi',
        'kind': 'question',
        'direction': 'out',
      });

  test('one the person wrote is said as theirs', () {
    expect(HeldMessageRow.headline(held('ROLE_USER'), 'walk8'),
        'A question you wrote, going out through sokar-test-project-foo to michi, on walk8');
  });

  test("one the task's agent wrote is said as the task's", () {
    expect(HeldMessageRow.headline(held('ROLE_AGENT'), 'walk8'),
        'A question going out from sokar-test-project-foo to michi, on walk8');
  });
}
