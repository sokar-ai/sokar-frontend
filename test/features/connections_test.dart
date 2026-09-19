// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_go_to_the_work.dart';
import './step/the_store_is_shut.dart';
import './step/the_machine_connects_to_with_a_key_in_the_vault.dart';
import './step/the_machine_connects_to_with_a_token_in_a_file.dart';
import './step/i_choose_the_command.dart';
import './step/it_says.dart';
import './step/the_connection_is_marked_not_protected.dart';
import './step/the_connection_is_not_marked_not_protected.dart';
import './step/i_add_a_connection_to.dart';
import './step/adding_it_is_not_offered_yet.dart';
import './step/i_choose_it_to_be.dart';
import './step/adding_it_is_offered.dart';
import './step/i_add_it.dart';
import './step/it_was_declared_as_for_kept_in.dart';
import './step/i_type_its_value_into_a_terminal_on_the_machine.dart';
import './step/a_terminal_runs_on_the_machine.dart';
import './step/this_computer_has_the_key.dart';
import './step/i_send_the_key_to_the_machine.dart';
import './step/the_machine_was_given_a_key_by.dart';
import './step/the_status_line_mentions.dart';
import './step/the_way_to_store_it_says.dart';
import './step/nothing_was_given_to_the_machine.dart';
import './step/the_way_to_store_it_is_still_offered.dart';
import './step/i_paste_and_send_it.dart';
import './step/nothing_pasted_is_left_on_screen.dart';
import './step/it_is_kept_in_the_file_on_the_machine.dart';
import './step/i_paste_a_key_and_send_it.dart';
import './step/i_forget_the_connection.dart';
import './step/storing_on_the_machine_will_fail.dart';

void main() {
  group('''How a machine connects out, and giving it a credential''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iGoToTheWork(tester);
    }

    testWidgets(
        '''connections are listed with the vault shut, one outside it marked not protected''',
        (tester) async {
      await bddSetUp(tester);
      await theStoreIsShut(tester);
      await theMachineConnectsToWithAKeyInTheVault(tester, 'ssh://github.com');
      await theMachineConnectsToWithATokenInAFile(
          tester, 'https://gitlab.example/acme/');
      await iChooseTheCommand(tester, 'Show how this machine connects out');
      await itSays(tester, 'ssh://github.com');
      await itSays(tester,
          'the vault is shut, so nothing can say whether its value is there');
      await theConnectionIsMarkedNotProtected(
          tester, 'https://gitlab.example/acme/');
      await theConnectionIsNotMarkedNotProtected(tester, 'ssh://github.com');
    });
    testWidgets(
        '''what a connection is, is chosen and never read off its address''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(tester, 'Show how this machine connects out');
      await iAddAConnectionTo(tester, 'https://gitlab.example/acme/');
      await addingItIsNotOfferedYet(tester);
      await iChooseItToBe(tester, 'TOKEN');
      await addingItIsOffered(tester);
    });
    testWidgets(
        '''a token in the vault is stored by typing it into a terminal on the machine''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(tester, 'Show how this machine connects out');
      await iAddAConnectionTo(tester, 'https://gitlab.example/acme/');
      await iChooseItToBe(tester, 'TOKEN');
      await iAddIt(tester);
      await itWasDeclaredAsForKeptIn(
          tester, 'TOKEN', 'https://gitlab.example/acme/', 'VAULT');
      await itSays(tester, 'sokar vault put git.token.example');
      await iTypeItsValueIntoATerminalOnTheMachine(tester);
      await aTerminalRunsOnTheMachine(
          tester, 'sokar vault put git.token.example');
    });
    testWidgets(
        '''an ssh key is sent from a file of this computer, and nothing of it is kept''',
        (tester) async {
      await bddSetUp(tester);
      await thisComputerHasTheKey(tester, 'id_work');
      await iChooseTheCommand(tester, 'Show how this machine connects out');
      await iAddAConnectionTo(tester, 'ssh://gitlab.example');
      await iChooseItToBe(tester, 'SSH_KEY');
      await iAddIt(tester);
      await iSendTheKeyToTheMachine(tester, 'id_work');
      await theMachineWasGivenAKeyBy(tester, 'sokar vault put git.ssh.example');
      await theStatusLineMentions(tester, 'is stored on');
    });
    testWidgets(
        '''the public half chosen from this computer is refused, and nothing is sent''',
        (tester) async {
      await bddSetUp(tester);
      await thisComputerHasTheKey(tester, 'id_work');
      await iChooseTheCommand(tester, 'Show how this machine connects out');
      await iAddAConnectionTo(tester, 'ssh://gitlab.example');
      await iChooseItToBe(tester, 'SSH_KEY');
      await iAddIt(tester);
      await iSendTheKeyToTheMachine(tester, 'id_work.pub');
      await theWayToStoreItSays(tester, 'That is the public half of a key');
      await nothingWasGivenToTheMachine(tester);
      await theWayToStoreItIsStillOffered(tester);
    });
    testWidgets('''a pasted public key is refused, and nothing is sent''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(tester, 'Show how this machine connects out');
      await iAddAConnectionTo(tester, 'ssh://gitlab.example');
      await iChooseItToBe(tester, 'SSH_KEY');
      await iAddIt(tester);
      await iPasteAndSendIt(tester, 'ssh-ed25519 AAAAC3Nza me@work');
      await theWayToStoreItSays(tester, 'That is the public half of a key');
      await nothingWasGivenToTheMachine(tester);
      await nothingPastedIsLeftOnScreen(tester);
    });
    testWidgets(
        '''pasted text that is no key at all is refused, and nothing is sent''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(tester, 'Show how this machine connects out');
      await iAddAConnectionTo(tester, 'ssh://gitlab.example');
      await iChooseItToBe(tester, 'SSH_KEY');
      await iAddIt(tester);
      await iPasteAndSendIt(tester, 'hunter2');
      await theWayToStoreItSays(tester, 'That is not a private key');
      await nothingWasGivenToTheMachine(tester);
    });
    testWidgets(
        '''a key kept as a file on the machine cannot be named by its public half''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(tester, 'Show how this machine connects out');
      await iAddAConnectionTo(tester, 'ssh://gitlab.example');
      await iChooseItToBe(tester, 'SSH_KEY');
      await itIsKeptInTheFileOnTheMachine(tester, '/home/me/.ssh/id_work.pub');
      await addingItIsNotOfferedYet(tester);
      await itSays(tester, 'That is the public half');
    });
    testWidgets(
        '''a pasted key is sent, and the field it was pasted into is emptied at once''',
        (tester) async {
      await bddSetUp(tester);
      await iChooseTheCommand(tester, 'Show how this machine connects out');
      await iAddAConnectionTo(tester, 'ssh://gitlab.example');
      await iChooseItToBe(tester, 'SSH_KEY');
      await iAddIt(tester);
      await iPasteAKeyAndSendIt(tester);
      await theMachineWasGivenAKeyBy(tester, 'sokar vault put git.ssh.example');
      await nothingPastedIsLeftOnScreen(tester);
    });
    testWidgets('''forgetting a connection says the value is still there''',
        (tester) async {
      await bddSetUp(tester);
      await theMachineConnectsToWithAKeyInTheVault(tester, 'ssh://github.com');
      await iChooseTheCommand(tester, 'Show how this machine connects out');
      await iForgetTheConnection(tester, 'ssh://github.com');
      await itSays(tester, 'Its value is still there');
      await itSays(tester, 'Remove that at the machine');
    });
    testWidgets(
        '''a key that could not be stored is not kept in the field it was pasted into''',
        (tester) async {
      await bddSetUp(tester);
      await storingOnTheMachineWillFail(tester);
      await iChooseTheCommand(tester, 'Show how this machine connects out');
      await iAddAConnectionTo(tester, 'ssh://gitlab.example');
      await iChooseItToBe(tester, 'SSH_KEY');
      await iAddIt(tester);
      await iPasteAKeyAndSendIt(tester);
      await theStatusLineMentions(tester, 'Storing the key did not work');
      await theWayToStoreItIsStillOffered(tester);
      await nothingPastedIsLeftOnScreen(tester);
    });
  });
}
