# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F20 Access From Elsewhere

  Background:
    Given a backend with work on it
    And the app is running

  Scenario: which machine an action will act on is always visible
    Then the machine shown is {'this machine'}

  Scenario: another machine is watched, and switching moves the whole frame to it
    When I watch another machine called {'elsewhere'}
    And I switch to the machine {'elsewhere'}
    Then the machine shown is {'elsewhere'}
    And the project {'shared'} is listed

  Scenario: every machine is watched at once, not only the one being acted on
    When I watch another machine called {'elsewhere'}
    Then every machine is being watched

  Scenario: adding a machine does not move what is being acted on
    When I watch another machine called {'elsewhere'}
    Then the machine shown is {'this machine'}

  Scenario: a lost tunnel reads as a disconnection, never as a machine with nothing on it
    When I select the project {'checkout'}
    And the tunnel drops
    Then the machine is shown as not answering
    And the work {'sokar-checkout-shell'} is listed
    When enough time passes for another try
    Then the machine is shown as answering
