import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/tunnel.dart';

/// A refused login says what to change, from ssh's own words.
void main() {
  test('an agent cut off before its right key is told to name the key for the host', () {
    expect(whySshRefused('Received disconnect from 192.168.122.174 port 22:2: Too many authentication failures', 'walk8@vm'),
        allOf(contains('IdentitiesOnly yes'), contains('walk8@vm')));
  });

  test('no key accepted is said as the account lacking the key, or the account', () {
    expect(whySshRefused('walk8@vm: Permission denied (publickey).', 'walk8@vm'), contains('authorized_keys'));
  });

  test('words that tell nothing say nothing', () {
    expect(whySshRefused('', 'walk8@vm'), isNull);
  });
}
