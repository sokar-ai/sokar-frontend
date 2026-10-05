# F88 — A Nickname For Each Agent

**Status:** later; blocked by sokar (`@label`, the agent card) and sokar-message-matrix (the display
name).

**What must be true.** A person gives each agent a nickname when starting its work, sees it wherever
the agent is shown, and can name the agent by it in the room; the agent knows its nickname too.

## Why

An agent is talked with in three places: its terminal, a direct chat, and the project's room, where
all agents read along and `@` names one. A task name alone is hard to tell apart there.

## The shape

- **The nickname is the task's label** (`Label`), a caption and never a rename: the task's name stays
  its identity and its address. It is set with `Label` right after `Start` (which takes no label), and
  changed on the work's page with the caption dialog that already exists (`panes.dart`).
- **The address stays the task name.** The filter takes only plain names in `metadata.to` and
  `.from`, so a nickname is display only; Sokar resolves `@<nickname>` to the task name before it
  writes `to`.
- **Sokar** resolves `@<label>` to the task, puts `"you": {"task": …, "nickname": …}` into
  `agent-card.json`, tells the agent in its guide to read it there, and hands the label to the
  transport at enrollment and when it changes.
- **The transport** takes it as a display name (`enroll --display`, `rename --display`) and shows it
  in pills. It takes 1 to 64 characters after stripping, no control characters, no `@` and no `:`;
  umlauts, spaces and emoji are fine.

## Acceptance

- A nickname given in the start form is set as the task's label after it starts and shown on its tile
  and page. Seen to fail: a scenario in `test/features/task_creation.feature` that starts with a
  nickname and does not find the label set and shown.
- A nickname with a space or an umlaut is taken. Seen to fail: a scenario in
  `test/features/task_creation.feature` that types one and finds it refused.
- A nickname with `@`, `:` or a control character, or longer than 64 characters, is refused as it is
  typed, saying which character is not taken. Seen to fail: a scenario in
  `test/features/task_creation.feature` that types one and finds it taken, or no reason given.
- No nickname given sets no label. Seen to fail: a scenario in `test/features/task_creation.feature`
  that starts without one and finds `Label` called.
- In the room and a direct chat the agent's account shows the nickname, and a person's message naming
  `@<nickname>` reaches that task and wakes it; the agent takes a message naming its task name or its
  nickname as meant for it. Seen to fail: on the VM against Sokar's handover, a message to
  `@<nickname>` in the room that the task does not answer, or an account shown by its task name.
