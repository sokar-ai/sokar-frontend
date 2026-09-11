# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Moving around the frame by keyboard and by pointer

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work

  Scenario: what is on the machine is answered before anything is selected
    Then the project {'checkout'} is listed
    And the project {'billing'} is listed
    And the status line mentions {'Connected'}

  Scenario: a project and its work are each one selection away
    When I select the project {'checkout'}
    Then the work {'sokar-checkout-shell'} is listed
    When I select the work {'sokar-checkout-shell'}
    And I open the selection
    Then the detail for {'sokar-checkout-shell'} is shown

  Scenario: the frame is worked from the keyboard with no pointer at all
    When I move the keyboard to the project {'billing'}
    And I press enter
    Then the project {'billing'} is selected

  Scenario: closing a detail comes back with the same selection still made
    When I select the project {'checkout'}
    And I select the work {'sokar-checkout-shell'}
    And I open the selection
    And I close what is open
    Then the work pane is shown
    And the work {'sokar-checkout-shell'} is still selected
    And the project {'checkout'} is selected

  Scenario: one finder names actions belonging to a screen that is not open
    When I open the command finder
    Then the command finder names {'Refresh from the backend'}
    And the command finder names {'Open the selected work'}
    And the command {'Open the selected work'} is offered as unavailable

  Scenario: every action is reachable with a pointer alone
    When I open the menu {'Options'}
    And I choose the menu entry {'Appearance: dark'}
    Then the appearance is {'dark'}

  Scenario: the status line says in words what the last action did
    When I choose the command {'Refresh from the backend'}
    Then the status line mentions {'Refreshed'}

  Scenario: appearance is a choice and it survives a restart
    When I choose the command {'Appearance: dark'}
    Then the appearance is {'dark'}
    When the app is restarted
    Then the appearance is {'dark'}

  Scenario: a narrow window keeps the machines behind the menu button
    When the window is {420} pixels wide
    Then the work pane is shown
    And the project {'checkout'} is not listed
    When I open the machines
    Then the project {'checkout'} is listed

  # The finder teaches where things are: it goes there and marks the action, rather than running it
  # from nowhere.
  Scenario: the finder goes to where an action lives and marks it there
    When I open the command finder
    And I pick {'Check whether this machine can run anything'} in the finder
    Then the menu that holds {'Check whether this machine can run anything'} is open with it marked

  Scenario: the title bar holds only what belongs to no machine
    Then the title bar offers {'Find a command (Ctrl+K), Watch another machine…, Options, About Sokar'}

  Scenario: the title says where you are
    Then the title is {'this machine › Running'}
    When I select the project {'checkout'}
    Then the title is {'this machine › checkout'}

  Scenario: a project shows its own work, and Running shows what runs in every project
    When I select the project {'checkout'}
    Then the work {'sokar-billing-shell'} is no longer listed
    When I show what is running
    Then the work {'sokar-billing-shell'} is listed

  Scenario: Running shows only the work that is running
    Given the work {'sokar-checkout-shell'} is dead
    When I show what is running
    Then the work {'sokar-checkout-shell'} is no longer listed
    When I select the project {'checkout'}
    Then the work {'sokar-checkout-shell'} is listed

  Scenario: a machine's projects can be hidden under it, and opening it shows them again
    When I hide the projects of {'this machine'}
    Then the project {'checkout'} is not listed
    When I go to the work
    Then the project {'checkout'} is listed

  # A machine that does not answer cannot be asked anything, so nothing that would ask it is offered.
  Scenario: a machine that does not answer offers nothing that needs it, and says why
    When I select the project {'checkout'}
    And the tunnel drops
    And I open the command finder
    Then the command {'Describe a new project'} is unavailable because {'not answering'}
    And the command {'Build the environment for this project'} is unavailable because {'not answering'}
    And the command {'Check whether this machine can run anything'} is unavailable because {'not answering'}
    When I close what is open
    And enough time passes for another try

  Scenario: a new project and the stop for every machine wait for a machine that answers
    When the tunnel drops
    Then creating a project on this machine is not offered
    And stopping everything everywhere is not offered
    When enough time passes for another try
    Then stopping everything everywhere is offered
