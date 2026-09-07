# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F13 Operation Feedback And History

  Background:
    Given a backend with work on it
    And the app is running
    And I select the project {'checkout'}

  Scenario: the frame stays usable while a long operation runs
    When I choose the command {'Show what this project would open, creating nothing'}
    And I close what is open
    And I select the project {'checkout'}
    Then the work {'sokar-checkout-shell'} is listed
    And the operation is still running

  Scenario: output goes to the operation and disturbs nothing else
    When I choose the command {'Show what this project would open, creating nothing'}
    And the operation prints {'Building the image'}
    Then the operation shows {'Building the image'}
    When I close what is open
    Then {'Building the image'} is nowhere on the frame

  Scenario: an operation can be left and watched again without stopping it
    When I choose the command {'Show what this project would open, creating nothing'}
    And the operation prints {'step one'}
    And I close what is open
    And the operation prints {'step two'}
    And I show what this session has run
    And I open the last operation
    Then the operation shows {'step one'}
    And the operation shows {'step two'}
    And the operation is still running

  Scenario: everything this session ran is listed afterwards with its outcome
    When I choose the command {'Show what this project would open, creating nothing'}
    And the operation finishes
    And I close what is open
    And I show what this session has run
    Then the record shows {'would open'}
    And the record shows {'Finished.'}

  Scenario: failure is reported where success would have been, with the output that explains it
    When I choose the command {'Show what this project would open, creating nothing'}
    And the operation prints {'could not read project.yml'}
    And the operation fails
    And I close what is open
    And I show what this session has run
    Then the record shows {'exited with code 1'}
    And the record marks it as failed
    When I open the last operation
    Then the operation shows {'could not read project.yml'}

  Scenario: a run stopped by its own time limit is not read as a run that went wrong
    When I choose the command {'Show what this project would open, creating nothing'}
    And the operation prints {'agent: editing lib/money.dart'}
    And the operation runs out of time
    And I close what is open
    And I show what this session has run
    Then the record shows {'ran out of the time it was given'}
    When I open the last operation
    Then the operation shows {'agent: editing lib/money.dart'}

  Scenario: a run with no agent installed says nothing ran, rather than that it failed
    When I choose the command {'Show what this project would open, creating nothing'}
    And no agent is installed
    And I close what is open
    And I show what this session has run
    Then the record shows {'No agent is installed, so nothing ran'}

