// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/a_backend_with_work_on_it.dart';
import './step/the_app_is_running.dart';
import './step/i_go_to_the_work.dart';
import './step/i_describe_a_new_project.dart';
import './step/it_says.dart';
import './step/the_sets_offered_are_the_ones_installed_here.dart';
import './step/i_answer_the_project_questions.dart';
import './step/the_machine_was_asked_to_check_the_answers.dart';
import './step/nothing_was_created.dart';
import './step/the_machine_will_reject_because.dart';
import './step/creating_it_is_not_offered.dart';
import './step/the_machine_will_warn_about_because.dart';
import './step/creating_it_is_offered.dart';
import './step/i_leave_the_project_undescribed.dart';
import './step/i_create_the_project.dart';
import './step/creating_will_find_a_file_already_there.dart';
import './step/i_am_done_with_the_new_project.dart';
import './step/the_project_is_selected.dart';
import './step/the_machine_was_asked_without_a_project_file.dart';
import './step/i_put_the_project_file_at.dart';
import './step/the_machine_was_asked_with_the_project_file.dart';
import './step/the_machine_does_not_choose_a_place_for_project_files_yet.dart';

void main() {
  group('''Creating a project, checked by the machine that will run it''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await aBackendWithWorkOnIt(tester);
      await theAppIsRunning(tester);
      await iGoToTheWork(tester);
    }

    testWidgets(
        '''every question is in one place, and the sets offered are the ones this machine has''',
        (tester) async {
      await bddSetUp(tester);
      await iDescribeANewProject(tester);
      await itSays(tester, 'Its file goes where the machine keeps projects');
      await itSays(tester, 'What its work may reach');
      await theSetsOfferedAreTheOnesInstalledHere(tester);
    });
    testWidgets('''the answers are checked by the machine that will run them''',
        (tester) async {
      await bddSetUp(tester);
      await iDescribeANewProject(tester);
      await iAnswerTheProjectQuestions(tester);
      await theMachineWasAskedToCheckTheAnswers(tester);
      await nothingWasCreated(tester);
    });
    testWidgets('''an answer the machine rejects says which one and why''',
        (tester) async {
      await bddSetUp(tester);
      await theMachineWillRejectBecause(
          tester, 'name', 'a project name cannot contain a slash');
      await iDescribeANewProject(tester);
      await iAnswerTheProjectQuestions(tester);
      await itSays(tester, 'a project name cannot contain a slash');
      await creatingItIsNotOffered(tester);
    });
    testWidgets(
        '''something worth knowing that does not block is not treated as a refusal''',
        (tester) async {
      await bddSetUp(tester);
      await theMachineWillWarnAboutBecause(
          tester, 'baseImage', 'not on this machine yet, so it will be pulled');
      await iDescribeANewProject(tester);
      await iAnswerTheProjectQuestions(tester);
      await itSays(tester, 'not on this machine yet, so it will be pulled');
      await creatingItIsOffered(tester);
    });
    testWidgets('''what would be written is shown before anything is created''',
        (tester) async {
      await bddSetUp(tester);
      await iDescribeANewProject(tester);
      await iAnswerTheProjectQuestions(tester);
      await itSays(tester, 'security_class: "guarded"');
      await itSays(tester, 'It is an ordinary file');
      await nothingWasCreated(tester);
    });
    testWidgets('''walking away leaves nothing behind''', (tester) async {
      await bddSetUp(tester);
      await iDescribeANewProject(tester);
      await iAnswerTheProjectQuestions(tester);
      await iLeaveTheProjectUndescribed(tester);
      await nothingWasCreated(tester);
    });
    testWidgets('''creating says what is done and what is not''',
        (tester) async {
      await bddSetUp(tester);
      await iDescribeANewProject(tester);
      await iAnswerTheProjectQuestions(tester);
      await iCreateTheProject(tester);
      await itSays(tester, 'is created');
      await itSays(tester, 'preparing its environment takes minutes');
    });
    testWidgets('''a project file that is already there is never overwritten''',
        (tester) async {
      await bddSetUp(tester);
      await creatingWillFindAFileAlreadyThere(tester);
      await iDescribeANewProject(tester);
      await iAnswerTheProjectQuestions(tester);
      await iCreateTheProject(tester);
      await itSays(tester, 'There is already a project file');
      await itSays(tester, 'Nothing was written');
    });
    testWidgets('''a project made here is the one chosen once it is made''',
        (tester) async {
      await bddSetUp(tester);
      await iDescribeANewProject(tester);
      await iAnswerTheProjectQuestions(tester);
      await iCreateTheProject(tester);
      await iAmDoneWithTheNewProject(tester);
      await theProjectIsSelected(tester, 'new-thing');
    });
    testWidgets(
        '''the machine chooses where the project file goes, and says where''',
        (tester) async {
      await bddSetUp(tester);
      await iDescribeANewProject(tester);
      await iAnswerTheProjectQuestions(tester);
      await itSays(tester,
          'Its file goes to /home/somebody/.config/sokar/projects/new-thing/project.yml');
      await theMachineWasAskedWithoutAProjectFile(tester);
    });
    testWidgets('''a project file of one's own goes where it was put''',
        (tester) async {
      await bddSetUp(tester);
      await iDescribeANewProject(tester);
      await iPutTheProjectFileAt(
          tester, '/home/somebody/work/new-thing/project.yml');
      await iAnswerTheProjectQuestions(tester);
      await itSays(
          tester, 'Its file goes to /home/somebody/work/new-thing/project.yml');
      await theMachineWasAskedWithTheProjectFile(
          tester, '/home/somebody/work/new-thing/project.yml');
    });
    testWidgets(
        '''a Sokar that does not choose a place yet says so, rather than claiming a file is there''',
        (tester) async {
      await bddSetUp(tester);
      await theMachineDoesNotChooseAPlaceForProjectFilesYet(tester);
      await iDescribeANewProject(tester);
      await iAnswerTheProjectQuestions(tester);
      await iCreateTheProject(tester);
      await itSays(tester,
          "This machine's Sokar does not choose a place for the project file yet");
      await itSays(tester, 'Put it somewhere else');
    });
  });
}
