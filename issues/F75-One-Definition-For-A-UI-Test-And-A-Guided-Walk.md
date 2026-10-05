# F75 — One Definition For A UI Test And A Guided Walk

**Status:** later; blocked by flutter-guided-walk: a scenario that is also a walk.

**What must be true.** Each of the interface's scenarios is also a walk a person can run, so a walk
and its test never drift apart.

## The shape

Once `flutter-guided-walk` lets a Cucumber step carry its walk steps, the interface's step
definitions are given their walk steps (target key, condition, German text), the steps outside the
interface are marked as by hand, and `doc/walks/*.json` is made from the scenarios instead of kept
beside them. The mechanism is the plugin's; the backend is short of nothing.

## Acceptance

- Every walk in `doc/walks/` is generated from a scenario, and none is written by hand. Seen to fail:
  `test/walks_test.dart` goes red where a walk file differs from what its scenario generates.
- Every step of a scenario has walk steps or is marked as by hand. Seen to fail: a test that lists a
  step with neither.
