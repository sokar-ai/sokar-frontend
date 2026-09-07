// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_show_the_agents_installed_here.dart';
import './step/it_lists_the_agent.dart';
import './step/it_says.dart';
import './step/i_open_the_agent.dart';
import './step/it_shows_the_host.dart';
import './step/one_agent_on_the_machine_cannot_be_read.dart';
import './step/it_lists_the_unusable_agent.dart';
import './step/the_machine_has_no_agents.dart';

void main() {
  group('''F24 Agent Inventory''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
    }

    testWidgets(
        '''every installed agent is listed with its version and where it was found''',
        (tester) async {
      await bddSetUp(tester);
      await iShowTheAgentsInstalledHere(tester);
      await itListsTheAgent(tester, 'An Agent');
      await itSays(tester, '2.4.0');
      await iOpenTheAgent(tester, 'An Agent');
      await itSays(tester, '/usr/share/sokar/agents/an-agent.yml');
    });
    testWidgets(
        '''an agent that reports no version says so rather than showing a blank''',
        (tester) async {
      await bddSetUp(tester);
      await iShowTheAgentsInstalledHere(tester);
      await itSays(tester, 'version not reported');
    });
    testWidgets('''what an agent needs to reach is shown with it''',
        (tester) async {
      await bddSetUp(tester);
      await iShowTheAgentsInstalledHere(tester);
      await iOpenTheAgent(tester, 'An Agent');
      await itShowsTheHost(tester, 'api.anthropic.com');
    });
    testWidgets(
        '''an agent that could not describe itself is listed, not left out''',
        (tester) async {
      await bddSetUp(tester);
      await oneAgentOnTheMachineCannotBeRead(tester);
      await iShowTheAgentsInstalledHere(tester);
      await itListsTheUnusableAgent(tester, 'broken-agent');
    });
    testWidgets(
        '''two copies under one name are reported without guessing which runs''',
        (tester) async {
      await bddSetUp(tester);
      await iShowTheAgentsInstalledHere(tester);
      await iOpenTheAgent(tester, 'An Agent');
      await itSays(tester, 'which one runs');
    });
    testWidgets(
        '''a machine with nothing installed says so, as a state rather than a failure''',
        (tester) async {
      await bddSetUp(tester);
      await theMachineHasNoAgents(tester);
      await iShowTheAgentsInstalledHere(tester);
      await itSays(tester, 'That is a state, not a failure');
    });
  });
}
