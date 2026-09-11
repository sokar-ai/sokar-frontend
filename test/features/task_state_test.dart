// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_go_to_the_work.dart';
import './step/i_select_the_project.dart';
import './step/the_work_is_waiting_on.dart';
import './step/the_work_is_shown_as.dart';
import './step/it_says_it_is_waiting_on.dart';
import './step/the_work_is_idle.dart';
import './step/the_work_is_dead.dart';
import './step/the_work_has_been_idle_since_minutes_ago.dart';
import './step/the_work_cannot_be_seen.dart';
import './step/the_work_is_not_shown_as.dart';
import './step/the_backend_says_it_is_waiting_on.dart';

void main() {
  group('''What a piece of work is doing, and how long it has been''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iGoToTheWork(tester);
      await iSelectTheProject(tester, 'checkout');
    }

    testWidgets(
        '''work waiting on a person says so, and says what it is waiting on''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkIsWaitingOn(
          tester, 'sokar-checkout-shell', 'api.example.test:443');
      await theWorkIsShownAs(tester, 'sokar-checkout-shell', 'waiting');
      await itSaysItIsWaitingOn(tester, 'api.example.test:443');
    });
    testWidgets('''idle is told apart from finished''', (tester) async {
      await bddSetUp(tester);
      await theWorkIsIdle(tester, 'sokar-checkout-shell');
      await theWorkIsDead(tester, 'sokar-checkout-migrate');
      await theWorkIsShownAs(tester, 'sokar-checkout-shell', 'Quiet');
      await theWorkIsShownAs(tester, 'sokar-checkout-migrate', 'Not running');
    });
    testWidgets('''how long it has been that way is answerable''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHasBeenIdleSinceMinutesAgo(
          tester, 'sokar-checkout-shell', '40');
      await theWorkIsShownAs(
          tester, 'sokar-checkout-shell', 'Quiet for 40 minutes');
    });
    testWidgets('''work nothing can see is not reported as idle''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkCannotBeSeen(tester, 'sokar-checkout-shell');
      await theWorkIsShownAs(tester, 'sokar-checkout-shell', 'Cannot be seen');
      await theWorkIsNotShownAs(tester, 'sokar-checkout-shell', 'Quiet');
    });
    testWidgets(
        '''a change of activity arrives without anybody asking for it''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkIsIdle(tester, 'sokar-checkout-shell');
      await theBackendSaysItIsWaitingOn(tester, 'api.example.test:443');
      await theWorkIsShownAs(tester, 'sokar-checkout-shell', 'waiting');
    });
  });
}
