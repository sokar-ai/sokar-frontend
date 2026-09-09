// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_select_the_project.dart';
import './step/i_select_the_work.dart';
import './step/i_open_the_selection.dart';
import './step/it_says.dart';
import './step/i_review_what_is_waiting_at_the_gate.dart';
import './step/i_open_the_waiting_push.dart';
import './step/the_review_shows_the_file.dart';
import './step/the_review_shows.dart';
import './step/i_copy_the_diff.dart';
import './step/what_was_copied_mentions.dart';
import './step/i_forward_it_onto_the_branch.dart';
import './step/it_was_forwarded_onto.dart';
import './step/the_status_line_mentions.dart';
import './step/i_drop_the_request.dart';
import './step/nothing_was_forwarded.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_is_offered_as_unavailable.dart';
import './step/the_work_holds_unpushed_commits_and_changed_files.dart';
import './step/nobody_could_look_inside_the_work.dart';
import './step/the_work_held_unpushed_commits_when_it_stopped.dart';
import './step/the_machine_knows_no_such_task.dart';

void main() {
  group('''F10 Task Inspection And Work Handover''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iSelectTheProject(tester, 'checkout');
    }

    testWidgets(
        '''work whose own commits are waiting for review says so on its detail''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheWork(tester, 'sokar-checkout-migrate');
      await iOpenTheSelection(tester);
      await itSays(tester, 'its own work is waiting for review');
    });
    testWidgets('''work with nothing of its own waiting says that instead''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheSelection(tester);
      await itSays(tester, 'nothing of its own is waiting');
    });
    testWidgets(
        '''what a project pushed is readable file by file, without leaving the interface''',
        (tester) async {
      await bddSetUp(tester);
      await iReviewWhatIsWaitingAtTheGate(tester);
      await iOpenTheWaitingPush(tester);
      await theReviewShowsTheFile(tester, 'lib/money.dart');
      await theReviewShows(tester, '(value * 100).round()');
    });
    testWidgets(
        '''the diff leaves the interface in one action, for reading somewhere else''',
        (tester) async {
      await bddSetUp(tester);
      await iReviewWhatIsWaitingAtTheGate(tester);
      await iOpenTheWaitingPush(tester);
      await iCopyTheDiff(tester);
      await whatWasCopiedMentions(tester, 'lib/money.dart');
      await whatWasCopiedMentions(tester, '(value * 100).round()');
    });
    testWidgets('''forwarding names the branch rather than guessing one''',
        (tester) async {
      await bddSetUp(tester);
      await iReviewWhatIsWaitingAtTheGate(tester);
      await iOpenTheWaitingPush(tester);
      await iForwardItOntoTheBranch(tester, 'fix-rounding');
      await itWasForwardedOnto(tester, 'fix-rounding');
      await theStatusLineMentions(tester, 'was forwarded to fix-rounding');
    });
    testWidgets('''dropping the request leaves the work in the mirror''',
        (tester) async {
      await bddSetUp(tester);
      await iReviewWhatIsWaitingAtTheGate(tester);
      await iOpenTheWaitingPush(tester);
      await iDropTheRequest(tester);
      await theStatusLineMentions(tester, 'still in the mirror');
      await nothingWasForwarded(tester);
    });
    testWidgets(
        '''a project with no file recorded offers no gate, and names the reason''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'unrecorded');
      await iOpenTheCommandFinder(tester);
      await theCommandIsOfferedAsUnavailable(
          tester, 'Review what is waiting at the gate');
    });
    testWidgets(
        '''the gate says what it does not see, rather than reading as a wall''',
        (tester) async {
      await bddSetUp(tester);
      await iReviewWhatIsWaitingAtTheGate(tester);
      await itSays(tester, 'Work can also be pushed straight upstream by hand');
      await itSays(tester, 'per clone, on the machine you push from');
    });
    testWidgets(
        '''where somebody asks what an agent was told, the answer is not here''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheSelection(tester);
      await itSays(
          tester, 'in the repository — nothing here has a view of them');
    });
    testWidgets(
        '''what a running task holds that never reached the gate is on its detail''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHoldsUnpushedCommitsAndChangedFiles(tester, 2, 3);
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheSelection(tester);
      await itSays(tester, 'holds 2 unpushed commits and 3 changed files');
    });
    testWidgets('''holding nothing is said as holding nothing''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHoldsUnpushedCommitsAndChangedFiles(tester, 0, 0);
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheSelection(tester);
      await itSays(tester, 'holds nothing that never reached the gate');
    });
    testWidgets(
        '''a task nobody could look inside says that, not that it holds nothing''',
        (tester) async {
      await bddSetUp(tester);
      await nobodyCouldLookInsideTheWork(tester);
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheSelection(tester);
      await itSays(tester, 'nothing recorded what it held');
      await itSays(tester, 'killed, rebooted, or stopped by an older Sokar');
    });
    testWidgets(
        '''a stopped task says what it held when it stopped, and when that was''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHeldUnpushedCommitsWhenItStopped(tester, 4);
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheSelection(tester);
      await itSays(tester, 'held 4 unpushed commits when it stopped');
      await itSays(tester, 'minutes ago');
    });
    testWidgets(
        '''a name the machine does not know is refused rather than read as unreadable''',
        (tester) async {
      await bddSetUp(tester);
      await theMachineKnowsNoSuchTask(tester);
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheSelection(tester);
      await itSays(tester, 'does not know a task called');
    });
  });
}
