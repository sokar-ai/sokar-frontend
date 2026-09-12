# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. It is the group name in every surface CI renders.
Feature: Raising and dropping the forward that reaches a machine

  Background:
    Given a backend with work on it
    And the app is running
    And I go to the work

  Scenario: a machine is described by where it is, and the forward is raised here
    When I start watching another machine
    And I choose {'Raise the forward for me'}
    And I say it is called {'the build machine'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
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
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I watch it
    Then the machine {'the build machine'} says {'Host key verification failed.'}

  # A machine that answered yesterday and does not today is usually a daemon nobody started.
  Scenario: a watched machine that is silent can be started from its menu, once somebody agrees
    Given nothing answers on that machine
    When I start watching another machine
    And I choose {'Raise the forward for me'}
    And I say it is called {'the build machine'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I watch it
    And I switch to the machine {'the build machine'}
    And I ask to start Sokar on this machine
    Then nothing was started on that machine
    When I agree to start it
    Then the machine was asked to start {'setsid sokard'}
    And the session recorded {'Start Sokar on user@build.example.test'}
    And the machine {'the build machine'} answers again

  Scenario: a start nobody agreed to runs nothing
    Given nothing answers on that machine
    When I start watching another machine
    And I choose {'Raise the forward for me'}
    And I say it is called {'the build machine'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I watch it
    And I switch to the machine {'the build machine'}
    And I ask to start Sokar on this machine
    And I do not agree to start it
    Then nothing was started on that machine
    When the machine can answer again
    Then the machine {'the build machine'} answers again

  Scenario: a machine that answers is offered no start at all
    When I start watching another machine
    And I choose {'Raise the forward for me'}
    And I say it is called {'the build machine'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I watch it
    And I switch to the machine {'the build machine'}
    And I open the command finder
    Then the command {'Start Sokar on this machine'} is unavailable because {'already answering'}

  Scenario: a machine somebody else forwards is offered no start, because there is no host
    When I watch another machine called {'elsewhere'}
    And I switch to the machine {'elsewhere'}
    And I open the command finder
    Then the command {'Start Sokar on this machine'} is unavailable because {'somebody else'}

  Scenario: closing the interface leaves no forward it raised still running
    When I start watching another machine
    And I choose {'Raise the forward for me'}
    And I say it is called {'the build machine'}
    And I say it is at {'user@build.example.test'}
    And its socket there is {'/run/user/1001/sokar/sokard.sock'}
    And I watch it
    And I close the interface
    Then no forward this interface raised is still running

  Scenario: a forward the interface did not raise is never torn down by it
    When I watch another machine called {'elsewhere'}
    And I close the interface
    Then nothing was torn down for {'elsewhere'}

  Scenario: the socket on the other machine is asked for, never guessed
    When I start watching another machine
    And I choose {'Raise the forward for me'}
    Then its socket there is not filled in
