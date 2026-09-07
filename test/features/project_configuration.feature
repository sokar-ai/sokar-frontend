# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F05 Project Configuration

  Background:
    Given a backend with work on it
    And the app is running
    And I select the project {'checkout'}

  Scenario: what the work may reach says where each host came from
    When I open what this project may reach
    Then it shows {'api.anthropic.com'} granted by {'agent an-agent'}
    And it shows {'pub.dev'} granted by {'set dart-packages'}

  Scenario: what is asked for and refused is told apart from what nobody added
    When I open what this project may reach
    Then it says {'telemetry.example.test'} is refused

  Scenario: a set says which hosts it grants, because the name alone does not
    When I open what this project may reach
    And I look inside the set {'Container registries'}
    Then it lists {'quay.io'}

  Scenario: nothing is written until what it would do has been shown
    When I open what this project may reach
    And I add the set {'Container registries'}
    Then it says what it would do
    And it would open {'3'} hosts
    And nothing has been written yet

  Scenario: agreeing to the preview writes it, and says when it takes effect
    When I open what this project may reach
    And I add the set {'Container registries'}
    And I agree to the change
    Then it was written
    And it says {'applies to the next task'}

  Scenario: leaving a preview alone writes nothing
    When I open what this project may reach
    And I add the set {'Container registries'}
    And I leave it as it is
    Then nothing has been written yet

  Scenario: a refusal is an outcome with its reason, not a failure
    Given the next change will be refused because the set is not installed
    When I open what this project may reach
    And I add the set {'Container registries'}
    Then it says {'not installed on this machine'}

  Scenario: a change that makes a forge reachable says what it costs
    Given the next change will report a cost
    When I open what this project may reach
    And I add the set {'Container registries'}
    Then the cost warning says {'the gate now rests on the container holding no credential'}

  Scenario: a project that declares no egress at all is not offered the editor
    When I select the project {'billing'}
    And I open the command finder
    Then the command {'Change what this project may reach'} is offered as unavailable
