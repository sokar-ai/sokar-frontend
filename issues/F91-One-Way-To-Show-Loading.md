# F91 — One Way To Show Loading

**Status:** soon.

**What must be true.** Every view that reads something when it opens shows, the same way, that it is
reading and what, so a person never takes an empty view for a finished one.

## The shape

- A progress bar at the view's top with one sentence of what is being read ("Reading walk9's
  connections…"), until the answer is there; then the answer, or why there is none.
- The forge's page already shows it this way. The views still to go through: Connections, a machine's
  page, the gate, backups, what a project may reach, Messages, Agents, the vault, the start form, a
  project's machines and keys at its forge, the Default dialog.

## Acceptance

- One shared widget shows the reading, and each of the views above uses it. Seen to fail: a view in
  the list that builds its own progress or none.
- Each view, its answer held back, shows the progress and its sentence, then the answer once it comes.
  Seen to fail: a scenario per view that holds the answer back and finds no progress or no sentence,
  or still finds the progress after the answer came.
