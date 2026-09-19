// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_go_to_the_work.dart';
import './step/i_select_the_project.dart';
import './step/reading_the_agents_is_slow.dart';
import './step/i_start_work_in_this_project.dart';
import './step/it_says.dart';
import './step/the_machine_has_answered.dart';
import './step/it_does_not_say.dart';
import './step/i_call_it.dart';
import './step/i_choose_the_agent.dart';
import './step/i_choose.dart';
import './step/i_start_it.dart';
import './step/the_launch_was_called.dart';
import './step/the_launch_asked_for_the_mode.dart';
import './step/the_launch_named_the_project.dart';
import './step/the_launch_left_the_naming_to_the_machine.dart';
import './step/the_name_is_refused_saying.dart';
import './step/starting_is_not_offered_yet.dart';
import './step/the_machine_refuses_the_name_saying.dart';
import './step/the_machine_was_asked_about_the_name.dart';
import './step/what_to_ask_it_cannot_be_filled_in.dart';
import './step/i_ask_it_to.dart';
import './step/the_launch_asked_it_to.dart';
import './step/the_operation_prints.dart';
import './step/the_operation_shows.dart';
import './step/i_select_the_work.dart';
import './step/i_continue_this_work.dart';
import './step/what_to_ask_it_says.dart';
import './step/i_open_the_command_finder.dart';
import './step/the_command_is_offered_as_unavailable.dart';
import './step/one_agent_on_the_machine_cannot_be_read.dart';
import './step/the_launch_was_asked_for_nothing_in_particular.dart';
import './step/the_vault_holds_no_credential_for_what_a_run_would_use.dart';
import './step/nothing_was_started.dart';
import './step/i_store_the_credential_from_the_start.dart';
import './step/a_terminal_runs_on_the_machine.dart';
import './step/the_unlock_terminal_ends_and_is_put_away.dart';
import './step/whether_work_can_start_is_asked_again.dart';
import './step/the_terminal_prints_a_link_to.dart';
import './step/nothing_was_opened_in_the_browser.dart';
import './step/i_open_the_link_to.dart';
import './step/the_browser_was_given.dart';
import './step/the_terminal_prints_a_link_that_would_run.dart';
import './step/the_terminal_offers_no_link.dart';
import './step/the_agent_logs_in_by_its_own_login.dart';
import './step/i_log_in_with_the_agent_from_the_start.dart';
import './step/the_login_prints_its_page_and_its_reply_port.dart';
import './step/the_reply_port_is_forwarded.dart';
import './step/the_reply_forward_is_taken_down.dart';
import './step/logging_in_is_not_offered.dart';
import './step/starting_says_the_credential_is_stored_by.dart';
import './step/the_machine_fails_to_say_whether_work_can_start_with.dart';
import './step/the_start_brings_up_in_running.dart';
import './step/the_session_on_screen_is.dart';
import './step/no_session_was_opened.dart';
import './step/the_vault_is_locked.dart';
import './step/the_agent_names_no_default_provider.dart';
import './step/the_project_has_the_repositories.dart';
import './step/no_repository_is_chosen_yet.dart';
import './step/nothing_warns_about_starting.dart';
import './step/i_choose_the_repository.dart';
import './step/the_machine_was_asked_whether_work_can_start_in.dart';
import './step/the_launch_was_in_the_repository.dart';
import './step/the_launch_named_no_repository.dart';
import './step/the_work_works_in_the_repository.dart';
import './step/the_repository_is_chosen.dart';

void main() {
  group('''Starting work with an agent, a mode and a credential''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iGoToTheWork(tester);
      await iSelectTheProject(tester, 'checkout');
    }

    testWidgets(
        '''the start dialog opens at once, and says it is still asking the machine''',
        (tester) async {
      await bddSetUp(tester);
      await readingTheAgentsIsSlow(tester);
      await iStartWorkInThisProject(tester);
      await itSays(tester, 'Asking the machine what it has');
      await theMachineHasAnswered(tester);
      await itDoesNotSay(tester, 'Asking the machine what it has');
    });
    testWidgets('''work is started with a name, an agent and a mode''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iCallIt(tester, 'schema-work');
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await iStartIt(tester);
      await theLaunchWasCalled(tester, 'schema-work');
      await theLaunchAskedForTheMode(tester, 'SHELL');
      await theLaunchNamedTheProject(tester, 'checkout');
    });
    testWidgets(
        '''a name is optional, so nothing has to be invented before starting''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await iStartIt(tester);
      await theLaunchLeftTheNamingToTheMachine(tester);
    });
    testWidgets(
        '''a name no container could have is refused before anything starts''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iCallIt(tester, 'Foo Bar');
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await theNameIsRefusedSaying(tester, 'cannot hold a space');
      await startingIsNotOfferedYet(tester);
    });
    testWidgets(
        '''a name in upper case is refused, because two of them could be one ref''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iCallIt(tester, 'Schema-Work');
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await theNameIsRefusedSaying(tester, 'lowercase');
      await startingIsNotOfferedYet(tester);
    });
    testWidgets(
        '''a name of other characters, or with a hyphen at its edge, is refused''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iCallIt(tester, 'schema_work-');
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await theNameIsRefusedSaying(
          tester, 'starts and ends with a letter or a digit');
      await startingIsNotOfferedYet(tester);
    });
    testWidgets('''a name of only digits is refused''', (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iCallIt(tester, '123');
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await theNameIsRefusedSaying(tester, 'only digits');
      await startingIsNotOfferedYet(tester);
    });
    testWidgets(
        '''a name too long for its project is refused, saying how long it may be''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iCallIt(
          tester, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await theNameIsRefusedSaying(tester, 'at most 65 fit');
      await startingIsNotOfferedYet(tester);
    });
    testWidgets('''a name the machine refuses is refused in its words''',
        (tester) async {
      await bddSetUp(tester);
      await theMachineRefusesTheNameSaying(
          tester, 'login-7', 'kept for login containers - login7 would do');
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await iCallIt(tester, 'login-7');
      await theNameIsRefusedSaying(tester, 'login7 would do');
      await startingIsNotOfferedYet(tester);
      await theMachineWasAskedAboutTheName(tester, 'login-7');
    });
    testWidgets('''the mode is chosen, never assumed on somebody's behalf''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await startingIsNotOfferedYet(tester);
    });
    testWidgets(
        '''an unattended run is not started without being told what to do''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'Unattended, against a prompt');
      await startingIsNotOfferedYet(tester);
    });
    testWidgets('''a prompt belongs to an unattended run and to nothing else''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await whatToAskItCannotBeFilledIn(tester);
    });
    testWidgets('''what was chosen is what is sent''', (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'Unattended, against a prompt');
      await iAskItTo(tester, 'Fix the rounding and add a test');
      await iStartIt(tester);
      await theLaunchAskedForTheMode(tester, 'UNATTENDED');
      await theLaunchAskedItTo(tester, 'Fix the rounding and add a test');
    });
    testWidgets(
        '''an unattended run goes to the session, so leaving the dialog does not stop watching''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'Unattended, against a prompt');
      await iAskItTo(tester, 'Fix the rounding and add a test');
      await iStartIt(tester);
      await theOperationPrints(tester, 'agent: reading lib/money.dart');
      await theOperationShows(tester, 'agent: reading lib/money.dart');
    });
    testWidgets(
        '''a finished unattended run is continued with what it was asked to do last time''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheWork(tester, 'sokar-checkout-migrate');
      await iContinueThisWork(tester);
      await whatToAskItSays(tester, 'Fix the rounding in Money.pennies');
    });
    testWidgets('''work that is still running is not offered a new prompt''',
        (tester) async {
      await bddSetUp(tester);
      await iSelectTheWork(tester, 'sokar-checkout-shell');
      await iOpenTheCommandFinder(tester);
      await theCommandIsOfferedAsUnavailable(
          tester, 'Continue this work with a new prompt');
    });
    testWidgets(
        '''an agent that could not be read is named rather than left out''',
        (tester) async {
      await bddSetUp(tester);
      await oneAgentOnTheMachineCannotBeRead(tester);
      await iStartWorkInThisProject(tester);
      await itSays(tester, 'could not be read');
    });
    testWidgets(
        '''a prompt typed and then set aside is not sent with a mode that has no use for it''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'Unattended, against a prompt');
      await iAskItTo(tester, 'Fix the rounding and add a test');
      await iChoose(tester, 'A shell, driven by hand');
      await iStartIt(tester);
      await theLaunchAskedForTheMode(tester, 'SHELL');
      await theLaunchWasAskedForNothingInParticular(tester);
    });
    testWidgets('''a missing credential is named before anything is started''',
        (tester) async {
      await bddSetUp(tester);
      await theVaultHoldsNoCredentialForWhatARunWouldUse(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await itSays(tester, 'The vault holds no credential called a-provider');
      await nothingWasStarted(tester);
    });
    testWidgets(
        '''a missing credential is stored from the start dialog, and starting is asked about again''',
        (tester) async {
      await bddSetUp(tester);
      await theVaultHoldsNoCredentialForWhatARunWouldUse(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iStoreTheCredentialFromTheStart(tester);
      await aTerminalRunsOnTheMachine(
          tester, 'sh -c sokar vault put a-provider');
      await theUnlockTerminalEndsAndIsPutAway(tester);
      await whetherWorkCanStartIsAskedAgain(tester);
    });
    testWidgets(
        '''a link the terminal marks is opened in the browser here with a press, and only then''',
        (tester) async {
      await bddSetUp(tester);
      await theVaultHoldsNoCredentialForWhatARunWouldUse(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iStoreTheCredentialFromTheStart(tester);
      await theTerminalPrintsALinkTo(
          tester, 'https://claude.com/cai/oauth/authorize?code=true');
      await nothingWasOpenedInTheBrowser(tester);
      await iOpenTheLinkTo(
          tester, 'https://claude.com/cai/oauth/authorize?code=true');
      await theBrowserWasGiven(
          tester, 'https://claude.com/cai/oauth/authorize?code=true');
    });
    testWidgets('''a link that is not a web address is never offered''',
        (tester) async {
      await bddSetUp(tester);
      await theVaultHoldsNoCredentialForWhatARunWouldUse(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iStoreTheCredentialFromTheStart(tester);
      await theTerminalPrintsALinkThatWouldRun(tester, 'file:///usr/bin/xcalc');
      await theTerminalOffersNoLink(tester);
    });
    testWidgets(
        '''an agent that declares a login is logged in from the start, its reply forwarded''',
        (tester) async {
      await bddSetUp(tester);
      await theVaultHoldsNoCredentialForWhatARunWouldUse(tester);
      await theAgentLogsInByItsOwnLogin(tester, 'an-agent');
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iLogInWithTheAgentFromTheStart(tester);
      await aTerminalRunsOnTheMachine(
          tester, 'sokar vault login --agent an-agent');
      await theLoginPrintsItsPageAndItsReplyPort(
          tester, 'https://claude.com/cai/oauth/authorize', '42017');
      await theReplyPortIsForwarded(tester, '42017');
      await nothingWasOpenedInTheBrowser(tester);
      await iOpenTheLinkTo(tester, 'https://claude.com/cai/oauth/authorize');
      await theBrowserWasGiven(
          tester, 'https://claude.com/cai/oauth/authorize');
      await theUnlockTerminalEndsAndIsPutAway(tester);
      await theReplyForwardIsTakenDown(tester);
      await whetherWorkCanStartIsAskedAgain(tester);
    });
    testWidgets('''an agent that declares no login is not offered one''',
        (tester) async {
      await bddSetUp(tester);
      await theVaultHoldsNoCredentialForWhatARunWouldUse(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await loggingInIsNotOffered(tester);
    });
    testWidgets(
        '''the credential is stored by the command the readiness answer names''',
        (tester) async {
      await bddSetUp(tester);
      await startingSaysTheCredentialIsStoredBy(
          tester, 'sokar vault put a-provider');
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iStoreTheCredentialFromTheStart(tester);
      await aTerminalRunsOnTheMachine(tester, 'sokar vault put a-provider');
    });
    testWidgets(
        '''a machine that fails to say whether work can start is said in the dialog''',
        (tester) async {
      await bddSetUp(tester);
      await theMachineFailsToSayWhetherWorkCanStartWith(
          tester, 'the vault could not be read');
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await itSays(tester,
          'The machine could not say whether work can start: the vault could not be read');
    });
    testWidgets(
        '''work started to be driven by hand opens its session once it is up''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iCallIt(tester, 'schema-work');
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await iStartIt(tester);
      await theStartBringsUpInRunning(
          tester, 'sokar-checkout-schema-work', 'checkout', 'SHELL');
      await theSessionOnScreenIs(tester, 'sokar-checkout-schema-work');
    });
    testWidgets('''an unattended run opens no session when it is up''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iCallIt(tester, 'nightly');
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'Unattended, against a prompt');
      await iAskItTo(tester, 'run the tests');
      await iStartIt(tester);
      await theStartBringsUpInRunning(
          tester, 'sokar-checkout-nightly', 'checkout', 'UNATTENDED');
      await noSessionWasOpened(tester);
    });
    testWidgets(
        '''a locked vault is a different sentence, and points at the machine''',
        (tester) async {
      await bddSetUp(tester);
      await theVaultIsLocked(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await itSays(tester, 'Unlock it at the machine');
      await itSays(tester, 'a daemon has no terminal');
    });
    testWidgets('''choosing a provider is not storing a secret''',
        (tester) async {
      await bddSetUp(tester);
      await theAgentNamesNoDefaultProvider(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await itSays(tester, 'this is a provider, not a secret');
    });
    testWidgets(
        '''an unattended run that cannot authenticate is not offered at all''',
        (tester) async {
      await bddSetUp(tester);
      await theVaultIsLocked(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'Unattended, against a prompt');
      await iAskItTo(tester, 'Fix the rounding');
      await startingIsNotOfferedYet(tester);
      await itSays(tester, 'no container, no workspace, nothing to clear up');
    });
    testWidgets(
        '''an interactive run is offered anyway, and says what it will cost''',
        (tester) async {
      await bddSetUp(tester);
      await theVaultIsLocked(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await itSays(tester, 'a container you will have to clear up');
    });
    testWidgets(
        '''work starts in a repository somebody chose, never in one chosen for them''',
        (tester) async {
      await bddSetUp(tester);
      await theProjectHasTheRepositories(
          tester, 'checkout', 'checkout, payments-api');
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await noRepositoryIsChosenYet(tester);
      await startingIsNotOfferedYet(tester);
      await nothingWarnsAboutStarting(tester);
      await iChooseTheRepository(tester, 'payments-api');
      await theMachineWasAskedWhetherWorkCanStartIn(tester, 'payments-api');
      await iStartIt(tester);
      await theLaunchWasInTheRepository(tester, 'payments-api');
    });
    testWidgets(
        '''an unattended run waiting for its repository is not told it would be refused''',
        (tester) async {
      await bddSetUp(tester);
      await theProjectHasTheRepositories(
          tester, 'checkout', 'checkout, payments-api');
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'Unattended, against a prompt');
      await iAskItTo(tester, 'Fix the rounding');
      await startingIsNotOfferedYet(tester);
      await nothingWarnsAboutStarting(tester);
    });
    testWidgets('''a machine that names no repositories is asked for none''',
        (tester) async {
      await bddSetUp(tester);
      await iStartWorkInThisProject(tester);
      await iChooseTheAgent(tester, 'An Agent');
      await iChoose(tester, 'A shell, driven by hand');
      await iStartIt(tester);
      await theLaunchNamedNoRepository(tester);
    });
    testWidgets('''work continued goes on in the repository it worked in''',
        (tester) async {
      await bddSetUp(tester);
      await theProjectHasTheRepositories(
          tester, 'checkout', 'checkout, payments-api');
      await theWorkWorksInTheRepository(
          tester, 'sokar-checkout-migrate', 'payments-api');
      await iSelectTheWork(tester, 'sokar-checkout-migrate');
      await iContinueThisWork(tester);
      await theRepositoryIsChosen(tester, 'payments-api');
    });
  });
}
