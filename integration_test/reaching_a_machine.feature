# The Feature line is the report row: one short sentence, 70 characters at most,
# saying what this file tests. Run by tool/e2e.sh against a real machine.
Feature: Reaching a real machine and reading what its daemon says

  Background:
    Given the interface is running

  Scenario: a machine added with a forward raised here is reached
    When I watch the test machine through a forward raised here
    Then the test machine is answering

  Scenario: every reply the interface reads can be read from the real daemon
    Given the test machine is being watched
    Then every reply it gives can be read
