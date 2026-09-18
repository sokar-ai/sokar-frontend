import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/src/app/shell_model.dart';

void main() {
  test('every machine starts closed in the tree, and opens where somebody goes', () {
    final shell = ShellModel();
    expect(shell.isExpanded('this machine'), isFalse);

    shell.setExpanded('this machine', expanded: true);
    expect(shell.isExpanded('this machine'), isTrue);
    expect(shell.isExpanded('elsewhere'), isFalse, reason: 'opening one opened another');

    shell.setExpanded('this machine', expanded: false);
    expect(shell.isExpanded('this machine'), isFalse);
  });
}
