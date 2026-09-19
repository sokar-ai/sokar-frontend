// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_go_to_the_work.dart';
import './step/i_follow_a_repository.dart';
import './step/i_name_it_at.dart';
import './step/following_it_is_not_offered_yet.dart';
import './step/i_choose_to_check_its_commits_against_a_key.dart';
import './step/i_give_the_key.dart';
import './step/following_it_is_offered.dart';
import './step/i_follow_it.dart';
import './step/the_follow_was_sent_with_the_key.dart';
import './step/it_says.dart';
import './step/i_go_to_the_project_it_made.dart';
import './step/the_project_is_the_one_chosen.dart';
import './step/i_choose_to_follow_it_unverified.dart';
import './step/the_follow_was_sent_unverified.dart';
import './step/the_next_follow_is_refused_as.dart';
import './step/there_is_no_project.dart';
import './step/the_next_follow_finds_a_rewritten_history.dart';
import './step/the_follow_accepted_no_rewrite.dart';
import './step/i_take_the_rewritten_history.dart';
import './step/the_follow_accepted_the_rewrite.dart';
import './step/the_credential_check_answers.dart';
import './step/no_follow_was_sent.dart';
import './step/setting_up_its_connection_is_offered.dart';
import './step/the_machine_is_reached_over_ssh_as.dart';
import './step/i_open_the_vault_from_the_follow.dart';
import './step/a_terminal_runs_on_the_machine.dart';
import './step/the_machine_has_no_credential_check.dart';

void main() {
  group('''A project comes to a machine by following its repository''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iGoToTheWork(tester);
    }

    testWidgets('''how its commits are checked is chosen, never assumed''',
        (tester) async {
      await bddSetUp(tester);
      await iFollowARepository(tester);
      await iNameItAt(tester, 'payments', 'git@example.org:payments.git');
      await followingItIsNotOfferedYet(tester);
      await iChooseToCheckItsCommitsAgainstAKey(tester);
      await followingItIsNotOfferedYet(tester);
      await iGiveTheKey(tester, 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5');
      await followingItIsOffered(tester);
    });
    testWidgets(
        '''a pinned key goes with the follow, and the project is there at once''',
        (tester) async {
      await bddSetUp(tester);
      await iFollowARepository(tester);
      await iNameItAt(tester, 'payments', 'git@example.org:payments.git');
      await iChooseToCheckItsCommitsAgainstAKey(tester);
      await iGiveTheKey(tester, 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5');
      await iFollowIt(tester);
      await theFollowWasSentWithTheKey(
          tester, 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5');
      await itSays(tester, 'Following, at c0ffee1');
      await iGoToTheProjectItMade(tester);
      await theProjectIsTheOneChosen(tester, 'payments');
    });
    testWidgets(
        '''following unverified says what that gives away before it is chosen''',
        (tester) async {
      await bddSetUp(tester);
      await iFollowARepository(tester);
      await iNameItAt(tester, 'payments', 'git@example.org:payments.git');
      await itSays(tester,
          'Anybody who can push to the repository decides what this machine runs');
      await iChooseToFollowItUnverified(tester);
      await iFollowIt(tester);
      await theFollowWasSentUnverified(tester);
    });
    testWidgets(
        '''a commit the machine will not take is said, and no project is made of it''',
        (tester) async {
      await bddSetUp(tester);
      await theNextFollowIsRefusedAs(tester, 'NOT_SIGNED');
      await iFollowARepository(tester);
      await iNameItAt(tester, 'payments', 'git@example.org:payments.git');
      await iChooseToFollowItUnverified(tester);
      await iFollowIt(tester);
      await itSays(tester, 'is not signed');
      await thereIsNoProject(tester, 'payments');
    });
    testWidgets('''a rewritten history is taken only as a second decision''',
        (tester) async {
      await bddSetUp(tester);
      await theNextFollowFindsARewrittenHistory(tester);
      await iFollowARepository(tester);
      await iNameItAt(tester, 'payments', 'git@example.org:payments.git');
      await iChooseToFollowItUnverified(tester);
      await iFollowIt(tester);
      await itSays(tester, 'Nothing here can tell which');
      await theFollowAcceptedNoRewrite(tester);
      await iTakeTheRewrittenHistory(tester);
      await theFollowAcceptedTheRewrite(tester);
    });
    testWidgets('''a key can be pinned by the fingerprint a refusal showed''',
        (tester) async {
      await bddSetUp(tester);
      await iFollowARepository(tester);
      await iNameItAt(tester, 'payments', 'git@example.org:payments.git');
      await iChooseToCheckItsCommitsAgainstAKey(tester);
      await itSays(tester, 'or its fingerprint');
      await iGiveTheKey(tester, 'SHA256:9xQeTbL1');
      await iFollowIt(tester);
      await theFollowWasSentWithTheKey(tester, 'SHA256:9xQeTbL1');
    });
    testWidgets(
        '''a repository nothing is set up to reach is not followed, and its connection is offered''',
        (tester) async {
      await bddSetUp(tester);
      await theCredentialCheckAnswers(tester, 'NO_CREDENTIAL');
      await iFollowARepository(tester);
      await iNameItAt(tester, 'payments', 'git@example.org:payments.git');
      await iChooseToFollowItUnverified(tester);
      await iFollowIt(tester);
      await itSays(
          tester, 'Nothing on this machine is set up to reach this address');
      await noFollowWasSent(tester);
      await settingUpItsConnectionIsOffered(tester);
    });
    testWidgets(
        '''a credential in a shut vault offers to open it, and follows nothing''',
        (tester) async {
      await bddSetUp(tester);
      await theCredentialCheckAnswers(tester, 'VAULT_LOCKED');
      await theMachineIsReachedOverSshAs(tester, 'michi@vm');
      await iFollowARepository(tester);
      await iNameItAt(tester, 'payments', 'git@example.org:payments.git');
      await iChooseToFollowItUnverified(tester);
      await iFollowIt(tester);
      await noFollowWasSent(tester);
      await iOpenTheVaultFromTheFollow(tester);
      await aTerminalRunsOnTheMachine(
          tester, 'ssh -t michi@vm sokar vault unlock');
    });
    testWidgets(
        '''a machine older than the check is still followed, and says itself what is wrong''',
        (tester) async {
      await bddSetUp(tester);
      await theMachineHasNoCredentialCheck(tester);
      await iFollowARepository(tester);
      await iNameItAt(tester, 'payments', 'git@example.org:payments.git');
      await iChooseToFollowItUnverified(tester);
      await iFollowIt(tester);
      await theFollowWasSentUnverified(tester);
    });
    testWidgets('''a local repository needs nothing, and is followed''',
        (tester) async {
      await bddSetUp(tester);
      await theCredentialCheckAnswers(tester, 'NOT_NEEDED');
      await iFollowARepository(tester);
      await iNameItAt(tester, 'payments', '/srv/git/payments');
      await iChooseToFollowItUnverified(tester);
      await iFollowIt(tester);
      await theFollowWasSentUnverified(tester);
    });
  });
}
