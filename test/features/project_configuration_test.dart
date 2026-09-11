// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_go_to_the_work.dart';
import './step/i_select_the_project.dart';
import './step/i_open_what_this_project_may_reach.dart';
import './step/it_shows_granted_by.dart';
import './step/it_says_is_refused.dart';
import './step/i_look_inside_the_set.dart';
import './step/it_lists.dart';
import './step/i_add_the_set.dart';
import './step/it_says_what_it_would_do.dart';
import './step/it_would_open_hosts.dart';
import './step/nothing_has_been_written_yet.dart';
import './step/i_agree_to_the_change.dart';
import './step/it_was_written.dart';
import './step/it_says.dart';
import './step/i_leave_it_as_it_is.dart';
import './step/the_next_change_will_be_refused_because_the_set_is_not_installed.dart';
import './step/the_next_change_will_report_a_cost.dart';
import './step/the_cost_warning_says.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_is_offered_as_unavailable.dart';
import './step/i_ask_to_remove_what_sokar_built_here.dart';
import './step/nothing_was_removed.dart';
import './step/i_agree_to_remove_it.dart';
import './step/it_was_removed_for.dart';
import './step/nothing_was_forced.dart';
import './step/removing_will_refuse_because.dart';
import './step/it_was_forced.dart';
import './step/the_command_is_offered.dart';

void main() {
  group('''Changing what a project may reach, and removing a project''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iGoToTheWork(tester);
      await iSelectTheProject(tester, 'checkout');
    }

    testWidgets('''what the work may reach says where each host came from''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenWhatThisProjectMayReach(tester);
      await itShowsGrantedBy(tester, 'api.anthropic.com', 'agent an-agent');
      await itShowsGrantedBy(tester, 'pub.dev', 'set dart-packages');
    });
    testWidgets(
        '''what is asked for and refused is told apart from what nobody added''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenWhatThisProjectMayReach(tester);
      await itSaysIsRefused(tester, 'telemetry.example.test');
    });
    testWidgets(
        '''a set says which hosts it grants, because the name alone does not''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenWhatThisProjectMayReach(tester);
      await iLookInsideTheSet(tester, 'Container registries');
      await itLists(tester, 'quay.io');
    });
    testWidgets('''nothing is written until what it would do has been shown''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenWhatThisProjectMayReach(tester);
      await iAddTheSet(tester, 'Container registries');
      await itSaysWhatItWouldDo(tester);
      await itWouldOpenHosts(tester, '3');
      await nothingHasBeenWrittenYet(tester);
    });
    testWidgets(
        '''agreeing to the preview writes it, and says when it takes effect''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenWhatThisProjectMayReach(tester);
      await iAddTheSet(tester, 'Container registries');
      await iAgreeToTheChange(tester);
      await itWasWritten(tester);
      await itSays(tester, 'applies to the next task');
    });
    testWidgets('''leaving a preview alone writes nothing''', (tester) async {
      await bddSetUp(tester);
      await iOpenWhatThisProjectMayReach(tester);
      await iAddTheSet(tester, 'Container registries');
      await iLeaveItAsItIs(tester);
      await nothingHasBeenWrittenYet(tester);
    });
    testWidgets('''a refusal is an outcome with its reason, not a failure''',
        (tester) async {
      await bddSetUp(tester);
      await theNextChangeWillBeRefusedBecauseTheSetIsNotInstalled(tester);
      await iOpenWhatThisProjectMayReach(tester);
      await iAddTheSet(tester, 'Container registries');
      await itSays(tester, 'not installed on this machine');
    });
    testWidgets('''a change that makes a forge reachable says what it costs''',
        (tester) async {
      await bddSetUp(tester);
      await theNextChangeWillReportACost(tester);
      await iOpenWhatThisProjectMayReach(tester);
      await iAddTheSet(tester, 'Container registries');
      await theCostWarningSays(
          tester, 'the gate now rests on the container holding no credential');
    });
    testWidgets(
        '''a project that declares no egress at all is not offered the editor''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'billing');
      await iOpenTheCommandFinder(tester);
      await theCommandIsOfferedAsUnavailable(
          tester, 'Change what this project may reach');
    });
    testWidgets(
        '''choosing sets one at a time is explained, not merely how it works''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'checkout');
      await iOpenWhatThisProjectMayReach(tester);
      await itSays(tester, 'ones installed later');
    });
    testWidgets('''what would go is shown, and asking removes nothing''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToRemoveWhatSokarBuiltHere(tester);
      await itSays(tester, 'This removes what Sokar built for checkout');
      await nothingWasRemoved(tester);
    });
    testWidgets('''the project file is named as kept, never as a casualty''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToRemoveWhatSokarBuiltHere(tester);
      await itSays(tester, '/srv/checkout/project.yml');
      await itSays(
          tester, 'A task run in that directory builds all of it again');
    });
    testWidgets(
        '''agreeing is a second act, and it says what is still there afterwards''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToRemoveWhatSokarBuiltHere(tester);
      await iAgreeToRemoveIt(tester);
      await itWasRemovedFor(tester, 'checkout');
      await itSays(tester, 'The project file is still there');
      await nothingWasForced(tester);
    });
    testWidgets('''commits nobody reviewed stop it, and say where they exist''',
        (tester) async {
      await bddSetUp(tester);
      await removingWillRefuseBecause(tester, 'HOLDS_WORK');
      await iAskToRemoveWhatSokarBuiltHere(tester);
      await iAgreeToRemoveIt(tester);
      await itSays(tester, 'nobody has reviewed it');
      await itSays(tester, 'in the mirror and nowhere else');
      await nothingWasForced(tester);
    });
    testWidgets('''running work stops it, and is not told the same way''',
        (tester) async {
      await bddSetUp(tester);
      await removingWillRefuseBecause(tester, 'TASKS_RUNNING');
      await iAskToRemoveWhatSokarBuiltHere(tester);
      await iAgreeToRemoveIt(tester);
      await itSays(tester, 'Work is still running');
      await itSays(tester, 'cut off where it stands');
    });
    testWidgets(
        '''going past a refusal is a second decision, and is what carries force''',
        (tester) async {
      await bddSetUp(tester);
      await removingWillRefuseBecause(tester, 'HOLDS_WORK');
      await iAskToRemoveWhatSokarBuiltHere(tester);
      await iAgreeToRemoveIt(tester);
      await iAgreeToRemoveIt(tester);
      await itWasForced(tester);
      await itSays(tester, 'is gone');
    });
    testWidgets(
        '''a project whose file nothing can find can still be removed''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'unrecorded');
      await iOpenTheCommandFinder(tester);
      await theCommandIsOffered(
          tester, 'Remove what Sokar built for this project');
    });
  });
}
