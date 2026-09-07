# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F11 Live Log Viewing

  Background:
    Given a backend with work on it
    And the app is running
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

  Scenario: work whose logs are gone says so rather than looking broken
    Given the work has no logs left
    When I ask which logs the work has
    Then it says it has no logs

  Scenario: colour an agent wrote is rendered, never shown as escape characters
    When I read the log {'agent.log'}
    And the log prints a red line saying {'it went wrong'}
    Then the log shows {'it went wrong'}
    And the log shows no escape characters

  Scenario: the log of finished work is still readable after it ends
    When I read the log {'agent.log'}
    And the log prints {'the last thing it said'}
    And the log ends
    Then the log shows {'the last thing it said'}
