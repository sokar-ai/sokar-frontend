# F96 — Keys A Machine No Longer Knows, Found By Their Title

**Status:** soon.

**What must be true.** Clearing a machine also removes, at the forge, the keys the machine no longer
knows itself, found by their title, so none stay behind.

## Why

Clearing a machine or a project already takes its keys at the forge and its line in
`machine-signers` in one step, said thing by thing; it finds only the keys the machine still names.

## Acceptance

- Keys at the forge whose title names the machine are found and cleared with it, though the machine
  does not name them. Seen to fail: a scenario with such a key at the forge that is still there after
  clearing, or not listed among what was cleared.
- The clearing is measured on a machine against Sokar's handover. Seen to fail: on the VM, a key of
  the cleared machine still at the forge, or its line still in `machine-signers`.
