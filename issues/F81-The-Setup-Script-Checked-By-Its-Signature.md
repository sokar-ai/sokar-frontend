# F81 — The Setup Script Checked By Its Signature

**Status:** soon; blocked by `sokar` B99.

**What must be true.** A person preparing a new machine can be sure the setup script that runs as root
is Sokar's, for the version installed; one that cannot be verified is refused and nothing runs.

## Why

The script that runs is already the one shown: fetched once into root's own directory, its SHA-256
said beside what it would do, and nothing run where it differs. A checksum or versioned name from the
same host proves nothing against whoever controls that host. `sokar` B99 signs the script and every
package with the packaging key and publishes that key's public half.

## Acceptance

- The wizard fetches the script for the version it installs, by its versioned name, not the `latest`
  pointer. Seen to fail: a scenario in `adding_a_machine.feature` where `latest` is fetched.
- It checks the script's detached signature against the public key this interface carries, before
  `--show` runs it. Seen to fail: a scenario in `adding_a_machine.feature` where a script with a bad
  signature reaches `--show`.
- A script that fails the check is refused in words that say so, with nothing run on the machine.
  Seen to fail: the same scenario, where the words are missing or a command ran.
- The leased machine's leg runs against a signed script. Seen to fail: that leg, run on a leased
  machine, goes red.
