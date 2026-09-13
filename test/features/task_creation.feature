# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Starting work with an agent, a mode and a credential

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work
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

  # The operator's Foo Bar was sent, the image was built, and only podman's create refused the name.
  Scenario: a name no container could have is refused before anything starts
    When I start work in this project
    And I call it {'Foo Bar'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then the name is refused saying {'cannot hold a space'}
    And starting is not offered yet

  # A case-insensitive filesystem makes Foo and foo one git ref.
  Scenario: a name in upper case is refused, because two of them could be one ref
    When I start work in this project
    And I call it {'Schema-Work'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then the name is refused saying {'lowercase'}
    And starting is not offered yet

  Scenario: a name of other characters, or with a hyphen at its edge, is refused
    When I start work in this project
    And I call it {'schema_work-'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then the name is refused saying {'starts and ends with a letter or a digit'}
    And starting is not offered yet

  # A login container is sokar-login-<digits>.
  Scenario: a name of only digits is refused
    When I start work in this project
    And I call it {'123'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then the name is refused saying {'only digits'}
    And starting is not offered yet

  # The container name holds the prefix, and the task's longest socket path has to fit.
  Scenario: a name too long for its project is refused, saying how long it may be
    When I start work in this project
    And I call it {'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'}
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then the name is refused saying {'at most 65 fit'}
    And starting is not offered yet

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

  Scenario: a missing credential is named before anything is started
    Given the vault holds no credential for what a run would use
    When I start work in this project
    And I choose the agent {'An Agent'}
    Then it says {'The vault holds no credential called a-provider'}
    And nothing was started

  Scenario: a locked vault is a different sentence, and points at the machine
    Given the vault is locked
    When I start work in this project
    And I choose the agent {'An Agent'}
    Then it says {'Unlock it at the machine'}
    And it says {'a daemon has no terminal'}

  Scenario: choosing a provider is not storing a secret
    Given the agent names no default provider
    When I start work in this project
    And I choose the agent {'An Agent'}
    Then it says {'this is a provider, not a secret'}

  Scenario: an unattended run that cannot authenticate is not offered at all
    Given the vault is locked
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'Unattended, against a prompt'}
    And I ask it to {'Fix the rounding'}
    Then starting is not offered yet
    And it says {'no container, no workspace, nothing to clear up'}

  Scenario: an interactive run is offered anyway, and says what it will cost
    Given the vault is locked
    When I start work in this project
    And I choose the agent {'An Agent'}
    And I choose {'A shell, driven by hand'}
    Then it says {'a container you will have to clear up'}

