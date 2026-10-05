import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/tiles.dart';

/// Usage: following a repository on this machine is not offered
Future<void> followingARepositoryOnThisMachineIsNotOffered(WidgetTester tester) async {
  await lookingAtTheProjects(tester, () async {
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('follow-a-repository'))).onPressed, isNull);
  });
}
