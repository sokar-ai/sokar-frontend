# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F02 Project Overview

  Background:
    Given a backend with work on it
    And the app is running

  Scenario: a project says what it is and how much work it has
    Then the project {'checkout'} says {'1 of 2 running · guarded'}

  Scenario: a project whose environment is not prepared is marked
    Then the project {'unrecorded'} is marked as not prepared
    And the project {'checkout'} is not marked as not prepared

  Scenario: falling behind says by how much, and when that was measured
    Then the project {'checkout'} says {'3 behind, as of 20 minutes ago'}

  Scenario: never checked is not the same sentence as up to date
    Then the project {'unrecorded'} says {'Never checked against the upstream'}

  Scenario: a project that reaches nothing says that, rather than reporting zero
    Then the project {'billing'} says {'Not checked: this project reaches nothing'}

  Scenario: work waiting for review is said on the row
    Then the project {'checkout'} says {'2'} are waiting at the gate

  Scenario: a project nothing can act on is listed and marked, never left out
    Then the project {'unrecorded'} is listed
    And the project {'unrecorded'} is marked as unusable

  Scenario: what changed elsewhere arrives without anybody asking for it
    When work is started elsewhere in {'checkout'}
    Then the project {'checkout'} says {'2 of 3 running · guarded'}

  Scenario: selecting a project changes nothing about it
    When I select the project {'checkout'}
    Then nothing was asked of the backend about {'checkout'}

  Scenario: a count left over from an older measurement is not drawn as one
    Given the last check for {'billing'} failed, leaving a stale count
    Then the project {'billing'} says {'The last check did not work'}
    And the project {'billing'} does not say {'7 behind'}

