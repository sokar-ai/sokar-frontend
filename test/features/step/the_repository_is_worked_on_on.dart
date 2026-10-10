import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: the repository {'acme/api'} is worked on on {'vm'}
Future<void> theRepositoryIsWorkedOnOn(WidgetTester tester, String repository, String machines) async {
  final card = find.byKey(ValueKey<String>('forge-repository $repository'));
  final count = machines.split(',').length;
  expect(find.descendant(of: card, matching: find.textContaining('on $count machine')), findsOneWidget);
  final bubble = tester.widget<Tooltip>(find.byKey(ValueKey<String>('repository-machines $repository')));
  // The machines' names and nothing else (walk 10).
  expect(bubble.message, machines.split(',').map((each) => each.trim()).join('\n'));
}
