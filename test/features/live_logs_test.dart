// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_select_the_project.dart';
import './step/i_select_the_work.dart';
import './step/i_read_the_log.dart';
import './step/the_log_prints.dart';
import './step/the_log_shows.dart';
import './step/i_stop_following.dart';
import './step/the_log_is_not_being_followed.dart';
import './step/i_ask_which_logs_the_work_has.dart';
import './step/the_logs_offered_are.dart';
import './step/the_work_has_no_logs_left.dart';
import './step/it_says_it_has_no_logs.dart';
import './step/the_log_prints_a_red_line_saying.dart';
import './step/the_log_shows_no_escape_characters.dart';
import './step/the_log_ends.dart';

void main() {
  group('''F11 Live Log Viewing''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iSelectTheProject(tester, 'checkout');
      await iSelectTheWork(tester, 'sokar-checkout-shell');
    }

    testWidgets(
        '''a log is read inside the interface, without dropping to another tool''',
        (tester) async {
      await bddSetUp(tester);
      await iReadTheLog(tester, 'agent.log');
      await theLogPrints(tester, 'building the image');
      await theLogShows(tester, 'building the image');
    });
    testWidgets(
        '''following can be suspended to read back, and nothing that arrives is lost''',
        (tester) async {
      await bddSetUp(tester);
      await iReadTheLog(tester, 'agent.log');
      await theLogPrints(tester, 'the first thing');
      await iStopFollowing(tester);
      await theLogPrints(tester, 'what arrived while reading back');
      await theLogIsNotBeingFollowed(tester);
      await theLogShows(tester, 'what arrived while reading back');
    });
    testWidgets('''only the logs the work actually has are offered''',
        (tester) async {
      await bddSetUp(tester);
      await iAskWhichLogsTheWorkHas(tester);
      await theLogsOfferedAre(tester, 'agent.log');
    });
    testWidgets(
        '''work whose logs are gone says so rather than looking broken''',
        (tester) async {
      await bddSetUp(tester);
      await theWorkHasNoLogsLeft(tester);
      await iAskWhichLogsTheWorkHas(tester);
      await itSaysItHasNoLogs(tester);
    });
    testWidgets(
        '''colour an agent wrote is rendered, never shown as escape characters''',
        (tester) async {
      await bddSetUp(tester);
      await iReadTheLog(tester, 'agent.log');
      await theLogPrintsARedLineSaying(tester, 'it went wrong');
      await theLogShows(tester, 'it went wrong');
      await theLogShowsNoEscapeCharacters(tester);
    });
    testWidgets('''the log of finished work is still readable after it ends''',
        (tester) async {
      await bddSetUp(tester);
      await iReadTheLog(tester, 'agent.log');
      await theLogPrints(tester, 'the last thing it said');
      await theLogEnds(tester);
      await theLogShows(tester, 'the last thing it said');
    });
  });
}
