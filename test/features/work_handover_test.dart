// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_select_the_project.dart';
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

void main() {
  group('''F10 Task Inspection And Work Handover''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iSelectTheProject(tester, 'checkout');
    }

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
  });
}
