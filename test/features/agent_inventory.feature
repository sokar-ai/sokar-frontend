# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F24 Agent Inventory

  Background:
    Given a backend with work on it
    And the app is running

  Scenario: every installed agent is listed with its version and where it was found
    When I show the agents installed here
    Then it lists the agent {'An Agent'}
    And it says {'2.4.0'}
    When I open the agent {'An Agent'}
    Then it says {'/usr/share/sokar/agents/an-agent.yml'}

  Scenario: an agent that reports no version says so rather than showing a blank
    When I show the agents installed here
    Then it says {'version not reported'}

  Scenario: what an agent needs to reach is shown with it
    When I show the agents installed here
    And I open the agent {'An Agent'}
    Then it shows the host {'api.anthropic.com'}

  Scenario: an agent that could not describe itself is listed, not left out
    Given one agent on the machine cannot be read
    When I show the agents installed here
    Then it lists the unusable agent {'broken-agent'}

  Scenario: a machine with nothing installed says so, as a state rather than a failure
    Given the machine has no agents
    When I show the agents installed here
    Then it says {'That is a state, not a failure'}

  Scenario: what an agent is deliberately refused is shown beside what it may reach
    When I show the agents installed here
    And I open the agent {'An Agent'}
    Then it shows the refused host {'telemetry.example.test'}
    And it says {'deliberately not given'}

  Scenario: the pinned build and its digest are shown
    When I show the agents installed here
    And I open the agent {'An Agent'}
    Then it says {'2.4.0'}
    And it shows the digest {'3b1f8e2a9c4d5067a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718'}

  Scenario: a fetch nobody can check says why, rather than showing a blank
    When I show the agents installed here
    And I open the agent {'Another Agent'}
    Then it says {'Not checked, on purpose: upstream publishes no digest'}

  Scenario: an agent that fetches nothing says so, rather than showing an empty list
    Given the agent {'An Agent'} fetches nothing
    When I show the agents installed here
    And I open the agent {'An Agent'}
    Then it says {'It writes its tool into the image'}

  Scenario: a copy that is installed and never used names the one that runs instead
    Given one agent is shadowed by another copy
    When I show the agents installed here
    Then it lists the unused copy {'/usr/libexec/sokar/agents/an-agent'}
    And it says {'runs instead'}

