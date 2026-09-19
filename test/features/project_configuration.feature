# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Changing what a project may reach, and no longer following one

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work
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

  # A repository may declare egress of its own, and it is added to the project's, never in place of
  # it. So a repository's view is the project's and its own together, its own marked.
  Scenario: what a repository adds is shown on top of what every repository gets, and marked
    Given the project {'checkout'} has the repositories {'checkout, payments-api'}
    And the repository {'payments-api'} adds {'api.stripe.com'}
    When I select the project {'checkout'}
    And I open what the repository {'payments-api'} may reach
    Then it says {'checkout · payments-api'}
    And it says {'github.com'}
    And {'api.stripe.com'} is marked as added by the repository
    And {'github.com'} is not marked as added by the repository
    And egress was asked about the repository {'payments-api'}

  Scenario: a change made for a repository is written into that repository's own block
    Given the project {'checkout'} has the repositories {'checkout, payments-api'}
    When I select the project {'checkout'}
    And I open what the repository {'payments-api'} may reach
    And I add the set {'Container registries'}
    And I agree to the change
    Then every egress change was written into {'payments-api'}

  Scenario: the project's own view names no repository, and asks about none
    When I open what this project may reach
    And I add the set {'Container registries'}
    And I agree to the change
    Then no egress call named a repository

  Scenario: choosing sets one at a time is explained, not merely how it works
    When I select the project {'checkout'}
    And I open what this project may reach
    Then it says {'ones installed later'}

  # A project exists on a machine because the machine follows its repository, so removing it is
  # stopping following. It refuses rather than deciding, which is why every scenario here is about
  # what it did *not* do.
  Scenario: what would go is shown, and asking removes nothing
    When I ask to stop following this project
    Then it says {'This stops following checkout'}
    And nothing was removed

  # The project is its repository, which is not on this machine. A confirmation that did not say so
  # would read as deleting the project itself.
  Scenario: the repository is said to be untouched, and following it again brings it back
    When I ask to stop following this project
    Then it says {'Its repository is not touched'}
    And it says {'Following its repository again brings it back'}

  Scenario: agreeing is a second act, and it says what is still there afterwards
    When I ask to stop following this project
    And I agree to stop following it
    Then following stopped for {'checkout'}
    And it says {'no longer followed here'}
    And nothing was forced

  Scenario: commits nobody reviewed stop it, and say where they exist
    Given stopping following will refuse because {'HOLDS_WORK'}
    When I ask to stop following this project
    And I agree to stop following it
    Then it says {'nobody has reviewed it'}
    And it says {'in the mirror and nowhere else'}
    And nothing was forced

  Scenario: running work stops it, and is not told the same way
    Given stopping following will refuse because {'TASKS_RUNNING'}
    When I ask to stop following this project
    And I agree to stop following it
    Then it says {'Work is still running'}
    And it says {'cut off where it stands'}

  Scenario: going past a refusal is a second decision, and is what carries force
    Given stopping following will refuse because {'HOLDS_WORK'}
    When I ask to stop following this project
    And I agree to stop following it
    And I agree to stop following it
    Then it was forced
    And it says {'is gone'}

  # It takes the project's name, and with force a project nothing follows is swept rather than
  # refused — so what tasks left behind can still be cleared away.
  Scenario: a project this machine does not follow can still be cleared away
    When I select the project {'unrecorded'}
    And I open the command finder
    Then the command {'Stop following this project'} is offered
