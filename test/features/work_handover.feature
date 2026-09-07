# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F10 Task Inspection And Work Handover

  Background:
    Given a backend with work on it
    And the app is running
    And I select the project {'checkout'}

  Scenario: what a project pushed is readable file by file, without leaving the interface
    When I review what is waiting at the gate
    And I open the waiting push
    Then the review shows the file {'lib/money.dart'}
    And the review shows {'(value * 100).round()'}

  Scenario: the diff leaves the interface in one action, for reading somewhere else
    When I review what is waiting at the gate
    And I open the waiting push
    And I copy the diff
    Then what was copied mentions {'lib/money.dart'}
    And what was copied mentions {'(value * 100).round()'}

  Scenario: forwarding names the branch rather than guessing one
    When I review what is waiting at the gate
    And I open the waiting push
    And I forward it onto the branch {'fix-rounding'}
    Then it was forwarded onto {'fix-rounding'}
    And the status line mentions {'was forwarded to fix-rounding'}

  Scenario: dropping the request leaves the work in the mirror
    When I review what is waiting at the gate
    And I open the waiting push
    And I drop the request
    Then the status line mentions {'still in the mirror'}
    And nothing was forwarded

  Scenario: a project with no file recorded offers no gate, and names the reason
    When I select the project {'unrecorded'}
    And I open the command finder
    Then the command {'Review what is waiting at the gate'} is offered as unavailable
