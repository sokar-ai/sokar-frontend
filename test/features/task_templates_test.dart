// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_select_the_project.dart';
import './step/i_start_work_in_this_project.dart';
import './step/i_choose_the_agent.dart';
import './step/i_choose.dart';
import './step/i_ask_it_to.dart';
import './step/i_keep_it_as.dart';
import './step/i_leave_without_starting.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_finder_names.dart';
import './step/the_job_is_already_named.dart';
import './step/i_choose_the_command.dart';
import './step/i_start_it.dart';
import './step/the_launch_asked_for_the_mode.dart';
import './step/the_launch_asked_it_to.dart';
import './step/what_to_ask_it_says.dart';
import './step/the_command_finder_does_not_name.dart';
import './step/the_app_is_restarted.dart';

void main() {
  group('''Naming a job so it can be started again''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iSelectTheProject(tester, 'checkout');
    }

    testWidgets('''a job is named, and becomes an action of its own''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'Unattended, against a prompt');
      await iAskItTo(tester, 'Run the nightly tests');
      await iKeepItAs(tester, 'nightly-tests');
      await iLeaveWithoutStarting(tester);
      await iOpenTheCommandFinder(tester);
      await theCommandFinderNames(tester, 'Run nightly-tests in checkout');
    });
    testWidgets(
        '''starting from a named job is one action, and it runs what the job carried''',
        (tester) async {
      await bddSetUp(tester);
      await theJobIsAlreadyNamed(tester, 'nightly-tests');
      await iChooseTheCommand(tester, 'Run nightly-tests in checkout');
      await iStartIt(tester);
      await theLaunchAskedForTheMode(tester, 'UNATTENDED');
      await theLaunchAskedItTo(tester, 'Run the nightly tests');
    });
    testWidgets('''what the job asks for is editable before it runs''',
        (tester) async {
      await bddSetUp(tester);
      await theJobIsAlreadyNamed(tester, 'nightly-tests');
      await iChooseTheCommand(tester, 'Run nightly-tests in checkout');
      await whatToAskItSays(tester, 'Run the nightly tests');
      await iAskItTo(tester, 'Run the nightly tests, and the slow ones too');
      await iStartIt(tester);
      await theLaunchAskedItTo(
          tester, 'Run the nightly tests, and the slow ones too');
    });
    testWidgets('''a job named in one project is not offered in another''',
        (tester) async {
      await bddSetUp(tester);
      await theJobIsAlreadyNamed(tester, 'nightly-tests');
      await iSelectTheProject(tester, 'billing');
      await iOpenTheCommandFinder(tester);
      await theCommandFinderDoesNotName(
          tester, 'Run nightly-tests in checkout');
    });
    testWidgets('''a named job outlives the run that named it''',
        (tester) async {
      await bddSetUp(tester);
      await theJobIsAlreadyNamed(tester, 'nightly-tests');
      await theAppIsRestarted(tester);
      await iSelectTheProject(tester, 'checkout');
      await iOpenTheCommandFinder(tester);
      await theCommandFinderNames(tester, 'Run nightly-tests in checkout');
    });
  });
}
