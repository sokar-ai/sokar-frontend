// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import './step/the_interface_is_running.dart';
import './step/i_watch_the_test_machine_through_a_forward_raised_here.dart';
import './step/the_test_machine_is_answering.dart';
import './step/the_test_machine_is_being_watched.dart';
import './step/every_reply_it_gives_can_be_read.dart';
import './step/i_try_the_test_machine_from_the_dialog.dart';
import './step/the_trial_says.dart';
import './step/no_forward_raised_for_the_trial_is_left.dart';
import './step/i_put_the_dialog_away.dart';
import './step/i_try_the_test_machine_from_the_dialog_with_a_socket_beside_its_own_that_nobody_serves.dart';
import './step/i_try_the_test_machine_from_the_dialog_with_the_socket.dart';
import './step/the_test_machine_has_a_project_repository.dart';
import './step/i_follow_it_from_the_interface_unverified.dart';
import './step/the_interface_says_it_is_following_it.dart';
import './step/the_machine_lists_as_followed_unverified_with_its_repositories_and_their_limits.dart';
import './step/i_stop_following_from_the_interface.dart';
import './step/the_machine_no_longer_lists.dart';
import './step/i_check_a_token_for_in_the_wizard_and_leave_it.dart';
import './step/the_wizards_check_was_answered_by_the_machine.dart';
import './step/the_machine_no_longer_lists_the_connection.dart';
import './step/the_test_machine_has_an_ssh_key_of_its_own.dart';
import './step/i_declare_the_machines_own_key_for_from_the_interface.dart';
import './step/the_machine_lists_the_connection_as_the_key_it_has.dart';
import './step/i_forget_the_connection_from_the_interface.dart';
import './step/the_interface_says_what_still_holds_its_value.dart';
import './step/the_test_machine_has_never_met.dart';
import './step/the_test_machine_connects_to_with_its_own_key.dart';
import './step/i_follow_as_from_the_interface_unverified.dart';
import './step/the_interface_shows_the_keys_of_with.dart';
import './step/i_trust_from_the_interface.dart';
import './step/the_machine_knows_by_the_key.dart';
import './step/the_connection_is_forgotten_again.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('''Reaching a real machine, reading it, and following a project''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await theInterfaceIsRunning(tester);
    }

    testWidgets('''a machine added with a forward raised here is reached''',
        (tester) async {
      await bddSetUp(tester);
      await iWatchTheTestMachineThroughAForwardRaisedHere(tester);
      await theTestMachineIsAnswering(tester);
    });
    testWidgets(
        '''every reply the interface reads can be read from the real daemon''',
        (tester) async {
      await bddSetUp(tester);
      await theTestMachineIsBeingWatched(tester);
      await everyReplyItGivesCanBeRead(tester);
    });
    testWidgets('''a machine is tried from the dialog before it is watched''',
        (tester) async {
      await bddSetUp(tester);
      await iTryTheTestMachineFromTheDialog(tester);
      await theTrialSays(tester, 'Reached Sokar');
      await noForwardRaisedForTheTrialIsLeft(tester);
      await iPutTheDialogAway(tester);
    });
    testWidgets(
        '''a socket nobody serves on the test machine is found by trying it''',
        (tester) async {
      await bddSetUp(tester);
      await iTryTheTestMachineFromTheDialogWithASocketBesideItsOwnThatNobodyServes(
          tester);
      await theTrialSays(tester, 'nothing answers at');
      await theTrialSays(tester, 'none.sock on that machine');
      await noForwardRaisedForTheTrialIsLeft(tester);
      await iPutTheDialogAway(tester);
    });
    testWidgets(
        '''a socket in another user's runtime directory on the test machine is named as that''',
        (tester) async {
      await bddSetUp(tester);
      await iTryTheTestMachineFromTheDialogWithTheSocket(
          tester, '/run/user/0/sokar/none.sock');
      await theTrialSays(tester, 'runtime directory (uid 0)');
      await noForwardRaisedForTheTrialIsLeft(tester);
      await iPutTheDialogAway(tester);
    });
    testWidgets(
        '''a repository followed through the dialog becomes a project, and stops being one''',
        (tester) async {
      await bddSetUp(tester);
      await theTestMachineIsBeingWatched(tester);
      await theTestMachineHasAProjectRepository(tester, 'e2e-follow');
      await iFollowItFromTheInterfaceUnverified(tester);
      await theInterfaceSaysItIsFollowingIt(tester);
      await theMachineListsAsFollowedUnverifiedWithItsRepositoriesAndTheirLimits(
          tester, 'e2e-follow');
      await iStopFollowingFromTheInterface(tester, 'e2e-follow');
      await theMachineNoLongerLists(tester, 'e2e-follow');
    });
    testWidgets(
        '''a token is checked by the real machine, and leaving writes nothing''',
        (tester) async {
      await bddSetUp(tester);
      await theTestMachineIsBeingWatched(tester);
      await iCheckATokenForInTheWizardAndLeaveIt(
          tester, 'https://e2e.invalid/');
      await theWizardsCheckWasAnsweredByTheMachine(tester);
      await theMachineNoLongerListsTheConnection(
          tester, 'https://e2e.invalid/');
    });
    testWidgets(
        '''a key the machine has is picked from its list and declared where it lies''',
        (tester) async {
      await bddSetUp(tester);
      await theTestMachineIsBeingWatched(tester);
      await theTestMachineHasAnSshKeyOfItsOwn(tester, 'id_e2e');
      await iDeclareTheMachinesOwnKeyForFromTheInterface(
          tester, 'ssh://e2e.invalid/');
      await theMachineListsTheConnectionAsTheKeyItHas(
          tester, 'ssh://e2e.invalid/');
      await iForgetTheConnectionFromTheInterface(tester, 'ssh://e2e.invalid/');
      await theInterfaceSaysWhatStillHoldsItsValue(tester);
      await theMachineNoLongerListsTheConnection(tester, 'ssh://e2e.invalid/');
    });
    testWidgets(
        '''a host never met is trusted from the follow, by the key its owner publishes''',
        (tester) async {
      await bddSetUp(tester);
      await theTestMachineIsBeingWatched(tester);
      await theTestMachineHasNeverMet(tester, 'github.com');
      await theTestMachineHasAnSshKeyOfItsOwn(tester, 'id_e2e');
      await theTestMachineConnectsToWithItsOwnKey(tester, 'ssh://github.com/');
      await iFollowAsFromTheInterfaceUnverified(
          tester, 'git@github.com:sokar-ai/sokar-project.git', 'e2e-hostkey');
      await theInterfaceShowsTheKeysOfWith(tester, 'github.com',
          'SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU');
      await iTrustFromTheInterface(
          tester, 'SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU');
      await theMachineKnowsByTheKey(tester, 'github.com',
          'SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU');
      await theMachineNoLongerLists(tester, 'e2e-hostkey');
      await theConnectionIsForgottenAgain(tester, 'ssh://github.com/');
    });
  });
}
