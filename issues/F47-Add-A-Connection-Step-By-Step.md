# F47 — Add A Connection Step By Step

Opened on 2026-09-19 at the operator's request, after an afternoon of adding connections to the
test machine through the single dialog F45 built. He declared the public half of a key. He declared
a path of this computer as a file on the machine. He declared an ssh key for an https address. And
he declared a deploy key for another repository. The single dialog accepted every one of them, and
each surfaced later as a refused fetch. His shape for it, with his decisions on four open points,
is below.

Depends on F46 for step 2's *a key already on the machine*.

## What must be true

**Adding a connection is a few steps: what it is for, where its value comes from, and a check that
nothing is missing. For a token or a password kept in the vault, a last step then stores the value
by typing it into a terminal on the machine. Each step offers only what fits what was chosen before
it, and nothing is declared until the check says it can work.**

## Acceptance

**Step 1 — what it is.** Where it connects to, what it is (an ssh key, a token, a user and
password), and what it is for, chosen from a drop-down of the purposes the machine
accepts, never typed: `git` and `any`, the whole list (Sokar, 13:08Z).

**Step 2 — where its value comes from**, depending on the kind:

- **An ssh key**
  - *A key already on the machine*: chosen from the machine's own keys (F46), each with its
    fingerprint and comment. It is kept where it lies, outside the vault, and says so, or it is
    taken into the vault by the machine from its own disk (`fromFile`).
  - *A variable on the machine*: its name typed. It is kept in the environment and says so.
  - *A key of this computer*: one field for the **private** key, and a button that fills it from a
    local file. It goes **into the vault only**. A public key is refused before anything is sent,
    and so is anything that is not a key.
- **A token**
  - *A variable on the machine*: its name typed.
  - *In the vault*: its value is typed in step 4, into a terminal on the machine.
- **A user and password**
  - *Two variables on the machine*: the names of the user's variable and the password's. The
    user's is given as `$NAME`, which the machine reads from its environment.
  - *In the vault*: the user as text here. The password is typed in step 4, into a terminal on the
    machine.
- **An OAuth token is not offered.** One already recorded on the machine is still listed, with its
  expiry.

Wherever the value ends up, it is stated as a fixed line under the choice rather than as a second
choice: *in the vault*, *in the file … on the machine*, *in the variable … on the machine*. Where it
is outside the vault, it is marked not protected, as today.

**Step 3 — the check.** Before anything is written, the machine is asked with `dryRun`
whether the connection as described would work: whether the address and the kind go together,
whether a file or a variable is there, and whether the vault is open. For an ssh key that is there,
it also says **who the key logs in as** at the forge, beside the key. A deploy key for another
repository is caught here rather than at the first follow. The answer is shown. **Add
it** is offered only when nothing blocks. Anything that blocks sends the person back to the step
it concerns, with what was typed kept.

**Step 4 — for a token or a password in the vault only: its value.** The machine's own `vault put`
runs in a terminal on the machine, as today. The value is typed or pasted there and never passes
through this interface. The machine then says whether the value is there.

**Throughout**: a key's contents are never kept once sent. Going back keeps every
description and never a secret. Leaving the wizard declares nothing.

## Built, 2026-09-19

The wizard replaces the single dialog. Its steps are what it is, where its value comes from, and
whether it would work: the machine's dry run, with who a key logs in as. The value's own step is
what follows *Add it*: a key of this computer is sent, a key on the machine is copied by the
machine, and a token or a password opens a terminal there. The check offers to make or open the
vault where that is what stands in the way, and asks again afterwards. Measured on the VM as
`sokinte`: the integration leg, 8 of 8, reads the real dry run, picks the machine's key, declares
it and forgets it, and leaves nothing written.

## Decided by the operator, 2026-09-19

- **A key sent from this computer goes into the vault, never into `~/.ssh` there.** A key
  already in `~/.ssh` is chosen as *a key already on the machine*, which covers that case without
  this interface copying a private key to a disk.
- **Only the private key is asked for.** The machine works out the public half.
- **A token or a password is typed into a terminal on the machine**, as its own last step, and
  never into this interface. Only a key, which is a file, is sent from here.
- **OAuth is not offered** (13:12Z, with Sokar). Every token in use is long-lived and `kind: token`
  covers it; a refresh flow would be the hardest part built for nobody. If a provider ever forces
  short-lived tokens, that is a requirement of its own.

## What the backend is short of

Answered by Sokar on 2026-09-19 (13:08Z); the operator said yes at 13:12Z, and Sokar is building
it in one piece:

- **`CredentialDeclare` with `dryRun`**: every refusal a real declare gives, nothing written, and
  for an ssh key that is there, who it logs in as, in a field of its own.
- **`CredentialDeclare` with `fromFile`**: a key already on the machine declared into the vault.
  The answer's `storeCommand` is `vault put <name> --from-file <path>`, composed by the machine.
  The vault name comes from the destination, so it is never put on a key.
- **`user` starting with `$`** names a variable on the machine.
- **Purposes are `git` and `any`**, hard-coded here until a second consumer appears.
- **OAuth**: nothing. It is not offered, and `expires` stays on `Connection` as it is.

## To be checked

- **The four pieces on a real machine**, once Sokar's build is on the VM.
