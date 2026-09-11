# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Reading a task's logs as they are written

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work
    And I select the project {'checkout'}
    And I select the work {'sokar-checkout-shell'}

  Scenario: a log is read inside the interface, without dropping to another tool
    When I read the log {'agent.log'}
    And the log prints {'building the image'}
    Then the log shows {'building the image'}

  Scenario: following can be suspended to read back, and nothing that arrives is lost
    When I read the log {'agent.log'}
    And the log prints {'the first thing'}
    And I stop following
    And the log prints {'what arrived while reading back'}
    Then the log is not being followed
    And the log shows {'what arrived while reading back'}

  Scenario: only the logs the work actually has are offered
    When I ask which logs the work has
    Then the logs offered are {'agent.log'}

  Scenario: a log whose name is not a .log is offered and read like any other
    Given the work also has the log {'events.jsonl'}
    When I ask which logs the work has
    Then the logs offered are {'agent.log, events.jsonl'}

  Scenario: what the firewall blocked is readable, and it is the file a stuck task needs
    Given the work also has the log {'events.jsonl'}
    When I read the log {'events.jsonl'}
    And the log prints {'deny registry.example.com:443'}
    Then the log shows {'deny registry.example.com:443'}

  Scenario: a log whose name does not say what it is arrives explained
    Given the work also has the log {'events.jsonl'}
    And the machine says the log {'events.jsonl'} holds {'what the firewall blocked'}
    When I ask which logs the work has
    Then the log {'events.jsonl'} is described as {'what the firewall blocked'}
    And the log {'agent.log'} is described by nothing

  Scenario: work whose logs are gone says so rather than looking broken
    Given the work has no logs left
    When I ask which logs the work has
    Then it says it has no logs

  Scenario: color an agent wrote is rendered, never shown as escape characters
    When I read the log {'agent.log'}
    And the log prints a red line saying {'it went wrong'}
    Then the log shows {'it went wrong'}
    And the log shows no escape characters

  Scenario: the log of finished work is still readable after it ends
    When I read the log {'agent.log'}
    And the log prints {'the last thing it said'}
    And the log ends
    Then the log shows {'the last thing it said'}
