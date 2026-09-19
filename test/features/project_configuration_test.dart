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
import './step/the_project_has_the_repositories.dart';
import './step/the_repository_adds.dart';
import './step/i_open_what_the_repository_may_reach.dart';
import './step/is_marked_as_added_by_the_repository.dart';
import './step/is_not_marked_as_added_by_the_repository.dart';
import './step/egress_was_asked_about_the_repository.dart';
import './step/every_egress_change_was_written_into.dart';
import './step/no_egress_call_named_a_repository.dart';
import './step/i_ask_to_stop_following_this_project.dart';
import './step/nothing_was_removed.dart';
import './step/i_agree_to_stop_following_it.dart';
import './step/following_stopped_for.dart';
import './step/nothing_was_forced.dart';
import './step/stopping_following_will_refuse_because.dart';
import './step/it_was_forced.dart';
import './step/the_command_is_offered.dart';

void main() {
  group('''Changing what a project may reach, and no longer following one''',
      () {
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
        '''what a repository adds is shown on top of what every repository gets, and marked''',
        (tester) async {
      await bddSetUp(tester);
      await theProjectHasTheRepositories(
          tester, 'checkout', 'checkout, payments-api');
      await theRepositoryAdds(tester, 'payments-api', 'api.stripe.com');
      await iSelectTheProject(tester, 'checkout');
      await iOpenWhatTheRepositoryMayReach(tester, 'payments-api');
      await itSays(tester, 'checkout · payments-api');
      await itSays(tester, 'github.com');
      await isMarkedAsAddedByTheRepository(tester, 'api.stripe.com');
      await isNotMarkedAsAddedByTheRepository(tester, 'github.com');
      await egressWasAskedAboutTheRepository(tester, 'payments-api');
    });
    testWidgets(
        '''a change made for a repository is written into that repository's own block''',
        (tester) async {
      await bddSetUp(tester);
      await theProjectHasTheRepositories(
          tester, 'checkout', 'checkout, payments-api');
      await iSelectTheProject(tester, 'checkout');
      await iOpenWhatTheRepositoryMayReach(tester, 'payments-api');
      await iAddTheSet(tester, 'Container registries');
      await iAgreeToTheChange(tester);
      await everyEgressChangeWasWrittenInto(tester, 'payments-api');
    });
    testWidgets(
        '''the project's own view names no repository, and asks about none''',
        (tester) async {
      await bddSetUp(tester);
      await iOpenWhatThisProjectMayReach(tester);
      await iAddTheSet(tester, 'Container registries');
      await iAgreeToTheChange(tester);
      await noEgressCallNamedARepository(tester);
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
      await iAskToStopFollowingThisProject(tester);
      await itSays(tester, 'This stops following checkout');
      await nothingWasRemoved(tester);
    });
    testWidgets(
        '''the repository is said to be untouched, and following it again brings it back''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToStopFollowingThisProject(tester);
      await itSays(tester, 'Its repository is not touched');
      await itSays(tester, 'Following its repository again brings it back');
    });
    testWidgets(
        '''agreeing is a second act, and it says what is still there afterwards''',
        (tester) async {
      await bddSetUp(tester);
      await iAskToStopFollowingThisProject(tester);
      await iAgreeToStopFollowingIt(tester);
      await followingStoppedFor(tester, 'checkout');
      await itSays(tester, 'no longer followed here');
      await nothingWasForced(tester);
    });
    testWidgets('''commits nobody reviewed stop it, and say where they exist''',
        (tester) async {
      await bddSetUp(tester);
      await stoppingFollowingWillRefuseBecause(tester, 'HOLDS_WORK');
      await iAskToStopFollowingThisProject(tester);
      await iAgreeToStopFollowingIt(tester);
      await itSays(tester, 'nobody has reviewed it');
      await itSays(tester, 'in the mirror and nowhere else');
      await nothingWasForced(tester);
    });
    testWidgets('''running work stops it, and is not told the same way''',
        (tester) async {
      await bddSetUp(tester);
      await stoppingFollowingWillRefuseBecause(tester, 'TASKS_RUNNING');
      await iAskToStopFollowingThisProject(tester);
      await iAgreeToStopFollowingIt(tester);
      await itSays(tester, 'Work is still running');
      await itSays(tester, 'cut off where it stands');
    });
    testWidgets(
        '''going past a refusal is a second decision, and is what carries force''',
        (tester) async {
      await bddSetUp(tester);
      await stoppingFollowingWillRefuseBecause(tester, 'HOLDS_WORK');
      await iAskToStopFollowingThisProject(tester);
      await iAgreeToStopFollowingIt(tester);
      await iAgreeToStopFollowingIt(tester);
      await itWasForced(tester);
      await itSays(tester, 'is gone');
    });
    testWidgets(
        '''a project this machine does not follow can still be cleared away''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'unrecorded');
      await iOpenTheCommandFinder(tester);
      await theCommandIsOffered(tester, 'Stop following this project');
    });
  });
}
