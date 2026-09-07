// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/work_is_blocked_reaching.dart';
import './step/the_rail_says_is_waiting.dart';
import './step/i_go_to_what_is_blocked.dart';
import './step/it_shows_the_destination.dart';
import './step/it_names_the_work_and_the_rule.dart';
import './step/other_work_is_blocked_reaching.dart';
import './step/both_are_shown_together.dart';
import './step/i_let_it_through.dart';
import './step/the_answer_sent_was.dart';
import './step/i_keep_it_blocked.dart';
import './step/i_select_the_project.dart';
import './step/the_work_is_marked_as_unenforced.dart';
import './step/the_work_is_not_marked_as_unenforced.dart';
import './step/the_answer_comes_back.dart';
import './step/it_says.dart';
import './step/the_question_runs_out.dart';
import './step/it_says_the_question_ran_out.dart';
import './step/nothing_is_waiting_any_more.dart';
import './step/i_select_the_work.dart';
import './step/i_choose_the_command.dart';
import './step/i_ask_it_to_reach.dart';
import './step/i_choose.dart';
import './step/i_show_what_that_would_grant.dart';
import './step/it_lists_the_grant.dart';
import './step/nothing_has_been_granted_yet.dart';
import './step/showing_what_it_would_grant_is_not_offered_yet.dart';
import './step/i_grant_it.dart';
import './step/the_scope_sent_was.dart';
import './step/the_project_file_cannot_be_found.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_is_offered_as_unavailable.dart';

void main() {
  group('''F17 Network Exposure Control''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
    }

    testWidgets(
        '''a blocked connection turns up without anybody going to look for it''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReaching(tester, 'api.example.test:443');
      await theRailSaysIsWaiting(tester, '1');
    });
    testWidgets(
        '''what was attempted, by which work, and which rule stopped it''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReaching(tester, 'api.example.test:443');
      await iGoToWhatIsBlocked(tester);
      await itShowsTheDestination(tester, 'api.example.test:443');
      await itNamesTheWorkAndTheRule(tester);
    });
    testWidgets(
        '''several pieces of work are watched in one view, not one view each''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReaching(tester, 'api.example.test:443');
      await otherWorkIsBlockedReaching(tester, 'files.example.test:22');
      await iGoToWhatIsBlocked(tester);
      await bothAreShownTogether(tester);
    });
    testWidgets('''letting one through tells the work that is waiting''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReaching(tester, 'api.example.test:443');
      await iGoToWhatIsBlocked(tester);
      await iLetItThrough(tester);
      await theAnswerSentWas(tester, 'allow');
    });
    testWidgets('''keeping one blocked is a separate answer, not a silence''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReaching(tester, 'api.example.test:443');
      await iGoToWhatIsBlocked(tester);
      await iKeepItBlocked(tester);
      await theAnswerSentWas(tester, 'deny');
    });
    testWidgets('''work nothing is enforcing is marked wherever it appears''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'billing');
      await theWorkIsMarkedAsUnenforced(tester, 'sokar-billing-audit');
      await theWorkIsNotMarkedAsUnenforced(tester, 'sokar-billing-shell');
    });
    testWidgets(
        '''letting one through says the host is reachable, not that the attempt succeeded''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReaching(tester, 'api.example.test:443');
      await iGoToWhatIsBlocked(tester);
      await iLetItThrough(tester);
      await theAnswerComesBack(tester);
      await itSays(tester, 'the attempt that was refused is gone');
    });
    testWidgets(
        '''a destination asked about again says why that is not a mistake''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReaching(tester, 'cdn.example.test:443');
      await iGoToWhatIsBlocked(tester);
      await iLetItThrough(tester);
      await theAnswerComesBack(tester);
      await workIsBlockedReaching(tester, 'cdn.example.test:443');
      await itSays(tester, 'remembered per address');
    });
    testWidgets(
        '''a question that ran out says so rather than quietly disappearing''',
        (tester) async {
      await bddSetUp(tester);
      await workIsBlockedReaching(tester, 'api.example.test:443');
      await iGoToWhatIsBlocked(tester);
      await theQuestionRunsOut(tester);
      await itSaysTheQuestionRanOut(tester);
      await nothingIsWaitingAnyMore(tester);
    });
    testWidgets(
        '''what running work may reach is changed from where that work is listed''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'checkout');
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iChooseTheCommand(tester, 'Let this work reach something new');
      await iAskItToReach(tester, 'files.example.test');
      await iChoose(tester, 'Just this run');
      await iShowWhatThatWouldGrant(tester);
      await itListsTheGrant(tester, 'files.example.test');
      await nothingHasBeenGrantedYet(tester);
    });
    testWidgets('''how far the change goes is chosen, never defaulted''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'checkout');
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iChooseTheCommand(tester, 'Let this work reach something new');
      await iAskItToReach(tester, 'files.example.test');
      await showingWhatItWouldGrantIsNotOfferedYet(tester);
    });
    testWidgets('''the scope that was chosen is the scope that is sent''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'checkout');
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iChooseTheCommand(tester, 'Let this work reach something new');
      await iAskItToReach(tester, 'files.example.test');
      await iChoose(tester, 'This run and the project file');
      await iShowWhatThatWouldGrant(tester);
      await iGrantIt(tester);
      await theScopeSentWas(tester, 'RUN_AND_PROJECT');
    });
    testWidgets(
        '''a grant says the host is reachable next time, not that what failed will now work''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'checkout');
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iChooseTheCommand(tester, 'Let this work reach something new');
      await iAskItToReach(tester, 'files.example.test');
      await iChoose(tester, 'Just this run');
      await iShowWhatThatWouldGrant(tester);
      await iGrantIt(tester);
      await itSays(tester, 'Reachable from the next attempt');
      await itSays(tester, 'This run only');
    });
    testWidgets(
        '''a run widened with no project file to write is a partial success, not a failure''',
        (tester) async {
      await bddSetUp(tester);
      await theProjectFileCannotBeFound(tester);
      await iSelectTheProject(tester, 'checkout');
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iChooseTheCommand(tester, 'Let this work reach something new');
      await iAskItToReach(tester, 'files.example.test');
      await iChoose(tester, 'This run and the project file');
      await iShowWhatThatWouldGrant(tester);
      await iGrantIt(tester);
      await itSays(tester, 'Granted for this run');
      await itSays(tester, 'Reachable from the next attempt');
    });
    testWidgets('''work that is not running says why it cannot be widened''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'checkout');
      await iSelectTheWork(tester, 'sokar-checkout-migrate');
      await iOpenTheCommandFinder(tester);
      await theCommandIsOfferedAsUnavailable(
          tester, 'Let this work reach something new');
    });
    testWidgets('''an offline project is never offered the action''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheProject(tester, 'billing');
      await iSelectTheWork(tester, 'sokar-billing-shell');
      await iOpenTheCommandFinder(tester);
      await theCommandIsOfferedAsUnavailable(
          tester, 'Let this work reach something new');
    });
  });
}
