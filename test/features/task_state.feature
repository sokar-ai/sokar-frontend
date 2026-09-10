# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: What a piece of work is doing, and how long it has been

  Background:
    Given a backend with work on it
    And the app is running
    And I select the project {'checkout'}

  Scenario: work waiting on a person says so, and says what it is waiting on
    Given the work {'sokar-checkout-shell'} is waiting on {'api.example.test:443'}
    Then the work {'sokar-checkout-shell'} is shown as {'waiting'}
    And it says it is waiting on {'api.example.test:443'}

  Scenario: idle is told apart from finished
    Given the work {'sokar-checkout-shell'} is idle
    And the work {'sokar-checkout-migrate'} is dead
    Then the work {'sokar-checkout-shell'} is shown as {'idle'}
    And the work {'sokar-checkout-migrate'} is shown as {'not running'}

  Scenario: how long it has been that way is answerable
    Given the work {'sokar-checkout-shell'} has been idle since {'40'} minutes ago
    Then the work {'sokar-checkout-shell'} is shown as {'idle for 40 minutes'}

  Scenario: work nothing can see is not reported as idle
    Given the work {'sokar-checkout-shell'} cannot be seen
    Then the work {'sokar-checkout-shell'} is shown as {'cannot be seen'}
    And the work {'sokar-checkout-shell'} is not shown as {'idle'}

  Scenario: a change of activity arrives without anybody asking for it
    Given the work {'sokar-checkout-shell'} is idle
    When the backend says it is waiting on {'api.example.test:443'}
    Then the work {'sokar-checkout-shell'} is shown as {'waiting'}
