# F62 — An Organisation's Policy Is Shown

**Status:** later; blocked by Sokar's part of `sokar-project` PJ16.

**What must be true.** A person on a machine whose organisation set a policy sees that it is in
force and what it allows, and is told why when it refuses something, rather than being surprised.

## Why

`sokar-project` PJ16, *An organisation decides which providers its machines use*. Sokar's part is
the policy file, its refusals and `doctor`; the contract carries none of it yet: not the policy, its
refusals, or whether a prompt may be allowed.

## Acceptance

- **A machine's policy is shown** with the machine: that one is in force, and what it allows — the
  providers, and whether an unverified follow, an allow at a clearance prompt and the `online` class
  are refused. A machine without one shows nothing of it. Seen to fail: widget tests of a machine
  with a policy and one without.
- **Starting work offers only the providers the policy allows**, and a start refused for its
  provider says so in the machine's words, naming the policy. Seen to fail: a scenario starting work
  under a policy that allows one provider, and one refused for its provider.
- **A clearance prompt under a policy with no allow offers only deny**, saying why; it never offers
  an allow the machine would refuse. Seen to fail: a widget test of the prompt under such a policy.
- **Following unverified, and a project of class `online`**, are refused in the machine's words,
  naming the policy. Seen to fail: a scenario for each refusal.
