# F46 — Use A Key Already On The Machine

Opened on 2026-09-19 at the operator's request. Setting up a connection to GitHub on the test
machine, the operator had a key pair `id_ed25519` in `~/.ssh` **there**. The interface offered to
send a key from this computer, or to name a file on the machine by typing its path. It offered
nothing that showed which keys the machine already has.

## What is wrong today

Adding an ssh key connection assumes the key is somewhere else. It is either sent from this
computer into the machine's vault, or named by a path typed without seeing the machine. Typing a
path fails quietly: a path of this computer, or the public half, is declared cleanly and is only
found to be wrong when a fetch is refused. That has already happened twice on the test machine.
A key a person already placed on the machine is the commonest case in a company network, where a
key is assigned rather than made. It is also the one case where nothing needs to be sent at all.

## What must be true

**When adding an ssh key connection, a person is offered the private keys the machine already has
and picks one from a list. No path is typed. Nothing is sent from here, and no key's value crosses
the socket.**

## Acceptance

- **"Use a key already on the machine"** stands beside sending one from this computer. It lists
  the machine's private keys: where each is, its type, its fingerprint, the comment of its public
  half where there is one, and whether it is protected by a passphrase. A public half is never
  offered on its own, and a file that is not a key is not offered at all.
- **The machine says which files are keys.** Nothing here reads, lists or guesses the machine's
  files. Telling a private key from its public half or from anything else takes the file's
  contents, and those stay on the machine.
- **What picking one does is said before it is done.** The choice is between using the key where
  it lies, which leaves it outside the vault and is marked not protected, and copying it into the
  vault. Where the backend offers both, both are offered, with that difference in words. A key
  protected by a passphrase says what that means for work that runs without a person.
- **A machine with no keys says so**, and offers the other ways in rather than an empty list.
- **A Sokar that cannot list keys is not treated as a machine with none.** The choice is offered
  as unavailable, with the reason.

## Built, 2026-09-19, against the shape Sokar posted (`25fdcff`)

- **An ssh key** kept **already on the machine** is picked from `SshKeys()`: each key with its
  type, fingerprint and comment, *named by an IdentityFile in ~/.ssh/config* where that is how
  it was found, and the machine's own sentence about what stands in its way. Only a key with its
  private half is offered.
- **No private key** is said as that, with the way to send one from this computer.
- **A Sokar without `SshKeys()`** falls back to the typed path and says why.
- **Measured on the VM** as `sokinte` against Sokar `0.1.0~snapshot.167.1.1.1+local.20260919T133944`,
  2026-09-19: the IDL's `SshKey` field for field, and the integration leg 8 of 8 — a key made in
  that account, listed by the machine, picked in the dialog, declared as `FILE` and found `present`,
  then forgotten.
- Not yet: **taking it into the vault** from the machine's own disk, which comes with Sokar's
  `fromFile` on `CredentialDeclare` and belongs to F47's wizard.

## What the backend is short of

A method that lists the ssh keys in the account's usual places. For each key it answers where it
is, its type, fingerprint and comment, whether it is protected by a passphrase, and never a value.
If the vault is to take one, it also needs a way to store a key that is **on the machine** into
the vault without the key crossing the socket, much as an agent's credential is imported. Asked of
Sokar in the channel on 2026-09-19.

## To be checked

- **Which places count as "usual", and who says so.** `~/.ssh` alone, or also what `~/.ssh/config`
  names with `IdentityFile`? The answer is Sokar's; this end shows what comes back.
