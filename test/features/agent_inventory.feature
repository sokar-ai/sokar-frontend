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
