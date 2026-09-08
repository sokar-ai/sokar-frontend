// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_show_what_this_machine_can_authenticate_against.dart';
import './step/it_says.dart';
import './step/i_open_the_provider.dart';
import './step/the_command_to_store_one_is.dart';
import './step/the_store_cannot_be_read.dart';
import './step/i_import_what_the_agent_already_has.dart';
import './step/no_secret_crossed_the_socket.dart';
import './step/importing_will_find_nothing.dart';
import './step/importing_will_find_the_store_shut.dart';

void main() {
  group('''F14 Authentication Flows''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
    }

    testWidgets(
        '''what a machine can authenticate against is listed with what each one is''',
        (tester) async {
      await bddSetUp(tester);
      await iShowWhatThisMachineCanAuthenticateAgainst(tester);
      await itSays(tester, 'A Provider');
      await itSays(tester, 'Another Provider');
      await iOpenTheProvider(tester, 'A Provider');
      await itSays(tester, 'api.example.test');
    });
    testWidgets('''which are authenticated and which are not is stated''',
        (tester) async {
      await bddSetUp(tester);
      await iShowWhatThisMachineCanAuthenticateAgainst(tester);
      await itSays(tester, 'a-provider · authenticated');
      await itSays(tester, 'other-provider · not authenticated');
    });
    testWidgets(
        '''where a credential belongs is taken from the machine, never worked out here''',
        (tester) async {
      await bddSetUp(tester);
      await iShowWhatThisMachineCanAuthenticateAgainst(tester);
      await iOpenTheProvider(tester, 'Another Provider');
      await itSays(tester, 'an-agent');
      await theCommandToStoreOneIs(
          tester, 'sokar vault put an-agent --type oauth');
    });
    testWidgets(
        '''nothing here asks for a secret, and it says where one is typed instead''',
        (tester) async {
      await bddSetUp(tester);
      await iShowWhatThisMachineCanAuthenticateAgainst(tester);
      await itSays(tester, 'Nothing here asks for a secret');
      await itSays(tester,
          'in the terminal half of the connection this window already uses');
    });
    testWidgets(
        '''a shut store says it cannot tell, rather than showing everything as unauthenticated''',
        (tester) async {
      await bddSetUp(tester);
      await theStoreCannotBeRead(tester);
      await iShowWhatThisMachineCanAuthenticateAgainst(tester);
      await itSays(tester, 'cannot say while the store is shut');
      await itSays(tester, 'That is not the same as none of them being');
    });
    testWidgets(
        '''what an agent already holds there is imported without a secret crossing''',
        (tester) async {
      await bddSetUp(tester);
      await iShowWhatThisMachineCanAuthenticateAgainst(tester);
      await iOpenTheProvider(tester, 'A Provider');
      await iImportWhatTheAgentAlreadyHas(tester);
      await itSays(tester, 'Stored as an-agent: 51 characters');
      await noSecretCrossedTheSocket(tester);
    });
    testWidgets(
        '''nothing to import is a sentence with a next step, never a failure''',
        (tester) async {
      await bddSetUp(tester);
      await importingWillFindNothing(tester);
      await iShowWhatThisMachineCanAuthenticateAgainst(tester);
      await iOpenTheProvider(tester, 'A Provider');
      await iImportWhatTheAgentAlreadyHas(tester);
      await itSays(tester, 'nobody has logged in with it on that machine yet');
      await itSays(tester, 'Logging in there is the next step');
    });
    testWidgets('''a shut store is not drawn as a missing credential''',
        (tester) async {
      await bddSetUp(tester);
      await importingWillFindTheStoreShut(tester);
      await iShowWhatThisMachineCanAuthenticateAgainst(tester);
      await iOpenTheProvider(tester, 'A Provider');
      await iImportWhatTheAgentAlreadyHas(tester);
      await itSays(tester,
          'The store is shut, so nothing here can say whether it holds one');
    });
  });
}
