# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Raising and dropping the forward that reaches a machine

  Background:
    Given a backend with work on it
    And the app is running

  Scenario: a machine is described by where it is, and the forward is raised here
    When I start watching another machine
    And I choose {'Raise the forward for me'}
    And I say it is called {'the build machine'}
    And I say it is at {'user@build.example.test'}
    And I watch it
    Then the forward was raised for {'the build machine'}
    And the machine {'the build machine'} says the forward is raised here

  Scenario: how it is reached is chosen, never assumed
    When I open the machine dialog
    And I say it is called {'the build machine'}
    Then watching it is not offered yet

  Scenario: a machine whose socket is already forwarded has nothing raised for it
    When I watch another machine called {'elsewhere'}
    Then nothing was raised for {'elsewhere'}
    And the machine {'elsewhere'} does not say the forward is raised here

  Scenario: a forward that cannot be raised says what the transport said
    Given raising a forward will fail with {'Host key verification failed.'}
    When I start watching another machine
    And I choose {'Raise the forward for me'}
    And I say it is called {'the build machine'}
    And I say it is at {'user@build.example.test'}
    And I watch it
    Then the machine {'the build machine'} says {'Host key verification failed.'}

  Scenario: closing the interface leaves no forward it raised still running
    When I start watching another machine
    And I choose {'Raise the forward for me'}
    And I say it is called {'the build machine'}
    And I say it is at {'user@build.example.test'}
    And I watch it
    And I close the interface
    Then no forward this interface raised is still running

  Scenario: a forward the interface did not raise is never torn down by it
    When I watch another machine called {'elsewhere'}
    And I close the interface
    Then nothing was torn down for {'elsewhere'}
