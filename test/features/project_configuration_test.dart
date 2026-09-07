// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
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
import './step/it_warns.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_is_offered_as_unavailable.dart';

void main() {
  group('''F05 Project Configuration''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
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
      await itWarns(
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
  });
}
