import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';

/// Which provider a task's agent was brokered to: read from the task's own answer, and
/// empty, never guessed, where a Sokar that did not record it answers nothing.
void main() {
  Map<String, dynamic> task([Map<String, dynamic> more = const <String, dynamic>{}]) => <String, dynamic>{
        'name': 'sokar-api-shell',
        'project': 'api',
        'securityClass': 'guarded',
        'state': 'running',
        'running': true,
        'helpers': 2,
        'agent': 'omp',
        ...more,
      };

  test('the provider is read beside the agent', () {
    expect(Task.from(task(<String, dynamic>{'provider': 'github-copilot'})).provider, 'github-copilot');
  });

  test('a task a Sokar started that did not record it has none', () {
    expect(Task.from(task()).provider, '');
  });
}
