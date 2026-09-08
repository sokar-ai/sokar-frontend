# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F06 Upstream Synchronisation And Backups

  Background:
    Given a backend with work on it
    And the app is running
    And I select the project {'checkout'}

  # A bundle is written wherever an operator names it and the command forgets it, so "what has
  # been taken" was never a missing listing — it was a question with no data behind it. What is
  # listed is a record written when each one was taken.
  Scenario: what has been taken is listed with enough to tell two apart
    When I show what has been backed up here
    Then it says {'/srv/checkout/backups/before-sync.bundle'}
    And it says {'2 pushes when it was taken'}
    And it says {'4.0 MB now'}

  # A record is not the bundle. The file can be moved afterwards and nothing here would know, so
  # what was true then and what is true now are told apart rather than merged.
  Scenario: a bundle somebody moved is shown as missing, never dropped
    When I show what has been backed up here
    Then it says {'/srv/checkout/backups/moved-away.bundle'}
    And it says {'the file is not there any more'}

  # An empty list means nothing recorded, never nothing exists.
  Scenario: a project with no record says so, without claiming no bundle exists
    Given nothing has been backed up here
    When I show what has been backed up here
    Then it says {'Nothing is recorded for this project'}
    And it says {'not the same as no bundle existing'}

  Scenario: removing one says what it held before anything goes
    When I show what has been backed up here
    And I consider removing the first backup
    Then it says {'It held 2 pushes nobody had reviewed'}
    And no backup was removed

  Scenario: keeping it removes nothing
    When I show what has been backed up here
    And I consider removing the first backup
    And I keep the backup
    Then no backup was removed

  Scenario: agreeing removes it, and says what it held
    When I show what has been backed up here
    And I consider removing the first backup
    And I remove the backup
    Then it says {'Gone: the bundle and the record of it'}

  # A tidy-up rather than a loss, and saying both the same way would tell somebody they had
  # destroyed something they had not.
  Scenario: clearing the record of a bundle already gone is not called a loss
    Given the bundle is already gone
    When I show what has been backed up here
    And I consider removing the first backup
    And I remove the backup
    Then it says {'The record is cleared. The file was already gone'}
