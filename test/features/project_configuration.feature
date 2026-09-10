# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Changing what a project may reach, and removing a project

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

  Scenario: choosing sets one at a time is explained, not merely how it works
    When I select the project {'checkout'}
    And I open what this project may reach
    Then it says {'ones installed later'}

  # `DeleteProject` landed on 2026-09-08. It removes what Sokar built and refuses rather than
  # deciding, which is why every scenario here is about what it did *not* do.
  Scenario: what would go is shown, and asking removes nothing
    When I ask to remove what Sokar built here
    Then it says {'This removes what Sokar built for checkout'}
    And nothing was removed

  # The field exists because this end said it would have listed the project file among the
  # casualties and believed it. The contract names what survives so a confirmation cannot get it
  # wrong.
  Scenario: the project file is named as kept, never as a casualty
    When I ask to remove what Sokar built here
    Then it says {'/srv/checkout/project.yml'}
    And it says {'A task run in that directory builds all of it again'}

  Scenario: agreeing is a second act, and it says what is still there afterwards
    When I ask to remove what Sokar built here
    And I agree to remove it
    Then it was removed for {'checkout'}
    And it says {'The project file is still there'}
    And nothing was forced

  Scenario: commits nobody reviewed stop it, and say where they exist
    Given removing will refuse because {'HOLDS_WORK'}
    When I ask to remove what Sokar built here
    And I agree to remove it
    Then it says {'nobody has reviewed it'}
    And it says {'in the mirror and nowhere else'}
    And nothing was forced

  Scenario: running work stops it, and is not told the same way
    Given removing will refuse because {'TASKS_RUNNING'}
    When I ask to remove what Sokar built here
    And I agree to remove it
    Then it says {'Work is still running'}
    And it says {'cut off where it stands'}

  Scenario: going past a refusal is a second decision, and is what carries force
    Given removing will refuse because {'HOLDS_WORK'}
    When I ask to remove what Sokar built here
    And I agree to remove it
    And I agree to remove it
    Then it was forced
    And it says {'is gone'}

  # It takes the project's name, not its file — so the one project nothing else can act on is
  # still the one that can be cleared away.
  Scenario: a project whose file nothing can find can still be removed
    When I select the project {'unrecorded'}
    And I open the command finder
    Then the command {'Remove what Sokar built for this project'} is offered
