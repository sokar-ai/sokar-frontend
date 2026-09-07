# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F08 Task Creation And Modes

  Background:
    Given a backend with work on it
    And the app is running
    And I select the project {'checkout'}

  Scenario: work is started with a name, an agent and a mode
    When I start work in this project
    And I call it {'schema-work'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    And I start it
    Then the launch was called {'schema-work'}
    And the launch asked for the mode {'SHELL'}
    And the launch was given the project file

  Scenario: a name is optional, so nothing has to be invented before starting
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    And I start it
    Then the launch left the naming to the machine

  Scenario: the mode is chosen, never assumed on somebody's behalf
    When I start work in this project
    And I choose the agent {'An Agent'}
    Then starting is not offered yet

  Scenario: an unattended run is not started without being told what to do
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    Then starting is not offered yet

  Scenario: a prompt belongs to an unattended run and to nothing else
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then what to ask it cannot be filled in

  Scenario: what was chosen is what is sent
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    And I ask it to {'Fix the rounding and add a test'}
    And I start it
    Then the launch asked for the mode {'UNATTENDED'}
    And the launch asked it to {'Fix the rounding and add a test'}

  Scenario: an unattended run goes to the session, so leaving the dialog does not stop watching
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    And I ask it to {'Fix the rounding and add a test'}
    And I start it
    And the operation prints {'agent: reading lib/money.dart'}
    Then the operation shows {'agent: reading lib/money.dart'}

  Scenario: a finished unattended run is continued with what it was asked to do last time
    When I select the work {'sokar-checkout-migrate'}
    And I continue this work
    Then what to ask it says {'Fix the rounding in Money.pennies'}

  Scenario: work that is still running is not offered a new prompt
    When I select the work {'sokar-checkout-shell'}
    And I open the command finder
    Then the command {'Continue this work with a new prompt'} is offered as unavailable

  Scenario: an agent that could not be read is named rather than left out
    Given one agent on the machine cannot be read
    When I start work in this project
    Then it says {'could not be read'}

  Scenario: a prompt typed and then set aside is not sent with a mode that has no use for it
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    And I ask it to {'Fix the rounding and add a test'}
    And I choose {'A shell, driven by hand'}
    And I start it
    Then the launch asked for the mode {'SHELL'}
    And the launch was asked for nothing in particular

