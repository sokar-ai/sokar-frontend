# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Adding a machine through a wizard that starts from what you have

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work
    When I open the machine dialog

  Scenario: the first page asks for a name and one of three kinds
    Then it says {'Its socket is already forwarded'}
    And it says {'Raise the forward for me'}
    And it says {'A new machine'}

  # Nothing is preselected: the kinds are different commitments, and a default would choose one.
  Scenario: the wizard goes on only with a name and a kind
    When I say it is called {'the build machine'}
    Then the wizard cannot go on yet
    When I choose {'Raise the forward for me'}
    And I go on
    Then its socket there is not filled in

  Scenario: a kind without a name does not go on either
    When I choose {'Its socket is already forwarded'}
    Then the wizard cannot go on yet

  Scenario: going back keeps what was said, and another kind can be chosen
    When I say it is called {'the build machine'}
    And I choose {'Raise the forward for me'}
    And I go on
    And I say it is at {'user@build.example.test'}
    And I go back
    And I choose {'Its socket is already forwarded'}
    And I go on
    And the forwarded socket is {'/tmp/sokar-build.sock'}
    And I watch it
    Then nothing was raised for {'the build machine'}
