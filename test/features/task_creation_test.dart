// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_select_the_project.dart';
import './step/i_start_work_in_this_project.dart';
import './step/i_call_it.dart';
import './step/i_choose_the_agent.dart';
import './step/i_choose.dart';
import './step/i_start_it.dart';
import './step/the_launch_was_called.dart';
import './step/the_launch_asked_for_the_mode.dart';
import './step/the_launch_was_given_the_project_file.dart';
import './step/the_launch_left_the_naming_to_the_machine.dart';
import './step/starting_is_not_offered_yet.dart';
import './step/what_to_ask_it_cannot_be_filled_in.dart';
import './step/i_ask_it_to.dart';
import './step/the_launch_asked_it_to.dart';
import './step/the_operation_prints.dart';
import './step/the_operation_shows.dart';
import './step/i_select_the_work.dart';
import './step/i_continue_this_work.dart';
import './step/what_to_ask_it_says.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_is_offered_as_unavailable.dart';
import './step/one_agent_on_the_machine_cannot_be_read.dart';
import './step/it_says.dart';
import './step/the_launch_was_asked_for_nothing_in_particular.dart';

void main() {
  group('''F08 Task Creation And Modes''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iSelectTheProject(tester, 'checkout');
    }

    testWidgets('''work is started with a name, an agent and a mode''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iCallIt(tester, 'schema-work');
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await iStartIt(tester);
      await theLaunchWasCalled(tester, 'schema-work');
      await theLaunchAskedForTheMode(tester, 'SHELL');
      await theLaunchWasGivenTheProjectFile(tester);
    });
    testWidgets(
        '''a name is optional, so nothing has to be invented before starting''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await iStartIt(tester);
      await theLaunchLeftTheNamingToTheMachine(tester);
    });
    testWidgets('''the mode is chosen, never assumed on somebody's behalf''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await startingIsNotOfferedYet(tester);
    });
    testWidgets(
        '''an unattended run is not started without being told what to do''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'Unattended, against a prompt');
      await startingIsNotOfferedYet(tester);
    });
    testWidgets('''a prompt belongs to an unattended run and to nothing else''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await whatToAskItCannotBeFilledIn(tester);
    });
    testWidgets('''what was chosen is what is sent''', (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'Unattended, against a prompt');
      await iAskItTo(tester, 'Fix the rounding and add a test');
      await iStartIt(tester);
      await theLaunchAskedForTheMode(tester, 'UNATTENDED');
      await theLaunchAskedItTo(tester, 'Fix the rounding and add a test');
    });
    testWidgets(
        '''an unattended run goes to the session, so leaving the dialog does not stop watching''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'Unattended, against a prompt');
      await iAskItTo(tester, 'Fix the rounding and add a test');
      await iStartIt(tester);
      await theOperationPrints(tester, 'agent: reading lib/money.dart');
      await theOperationShows(tester, 'agent: reading lib/money.dart');
    });
    testWidgets(
        '''a finished unattended run is continued with what it was asked to do last time''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheWork(tester, 'sokar-checkout-migrate');
      await iContinueThisWork(tester);
      await whatToAskItSays(tester, 'Fix the rounding in Money.pennies');
    });
    testWidgets('''work that is still running is not offered a new prompt''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheCommandFinder(tester);
      await theCommandIsOfferedAsUnavailable(
          tester, 'Continue this work with a new prompt');
    });
    testWidgets(
        '''an agent that could not be read is named rather than left out''',
        (tester) async {
      await bddSetUp(tester);
      await oneAgentOnTheMachineCannotBeRead(tester);
      await iStartWorkInThisProject(tester);
      await itSays(tester, 'could not be read');
    });
    testWidgets(
        '''a prompt typed and then set aside is not sent with a mode that has no use for it''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'Unattended, against a prompt');
      await iAskItTo(tester, 'Fix the rounding and add a test');
      await iChoose(tester, 'A shell, driven by hand');
      await iStartIt(tester);
      await theLaunchAskedForTheMode(tester, 'SHELL');
      await theLaunchWasAskedForNothingInParticular(tester);
    });
  });
}
