# The requirement id belongs on the Feature line and nowhere else: it becomes the JUnit group,
# which is what makes the CI report a traceability matrix.
Feature: F09 Task Control

  Scenario: a task holding unpushed work is refused rather than removed
    Given the app is running
    Then the placeholder is shown
