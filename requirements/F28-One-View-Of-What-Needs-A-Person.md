# F28 — One View Of What Needs A Person

**Status:** open. Proposed on 2026-09-11 after the operator looked at AI Beacon, a fleet dashboard
for coding-agent sessions, and said its surface would orchestrate Sokar better than this one does.
That reading is right about the shape and it is worth being precise about why.

## What is wrong with the frame today

The window is built around [F01](README.md)'s rail — *a rail saying where you are*. Navigation
first: you go to Projects, or to a machine, or to a task, and then you find out how it is. That is
the right frame for **changing** something, and the wrong one for the question an operator actually
opens the window with, which is **does anything need me right now**.

[F20](README.md) already connects every configured machine at once, and its own justification is
this question: *a clearance question has a deadline and a machine nobody watches is one whose work
expires unseen.* So the data arrives from every machine already. What is missing is that nothing
puts it in front of a person in one place.

**This is a landing surface, not a second view**, and that distinction is the whole of this
requirement. A card wall beside the rail would be two answers to one question - the fault this
project names elsewhere as *two implementations of the same question are how they come to
disagree*. What changes is what the window opens **on**; the rail stays exactly what it is, for
going somewhere to change something.

## What it shows, and where each part comes from

Nothing here is a new signal. All of it is already streamed or already on a row:

| On the card | Source | Kind |
|---|---|---|
| a clearance question waits, since when, with its deadline | `Prompts`, streaming | **known** |
| working / idle / waiting / dead, and *"idle for forty minutes"* | `Watch`, from [B11](https://github.com/sokar-ai/sokar/blob/main/requirements/base/B11-What-A-Task-Says-About-Itself.md) | known, with B11's own limits |
| work waiting at the gate | today on [F02](README.md)'s project row | known |
| which machine, which project, which agent, which mode, which class | `List` / `Watch` | known |

**Order is by demand, not by name.** What needs a person is above what is merely running, and what
has a deadline is above what does not.

**A known state and an inferred one are never drawn alike.** A clearance question exists or does
not; an agent that has gone quiet is a guess. B11 is explicit that a quiet task is not a waiting
one and that guessing is wrong in the direction that costs, so an inference appears as one or does
not appear.

## What this takes from the project it was learnt from, and what it does not

**Taken:** work-first over navigation-first, and one pane for every machine rather than one machine
at a time.

**Not taken:** its status detection reads a Claude Code session's terminal and reports *awaiting
permission*. Inside a task that state is by design absent -
[B24](https://github.com/sokar-ai/sokar/blob/main/requirements/base/B24-First-Run-Consent-Inside-The-Box.md)
turns the agent's own prompts off, the container being the answer - so an agent stopping to ask is
a defect here rather than a state to display. What remains is the clearance question, which this
machine knows rather than parses.

**Also not taken:** its browser and its central server. Those are a separate decision with a
separate price, recorded under *What was settled* and in
[B06](https://github.com/sokar-ai/sokar/blob/main/requirements/base/B06-Remote-Access.md). Nothing
in this requirement needs either.

## On the look, which is the frontend's to decide

**The operator named a reference and likes it**: AI Beacon's dashboard, a wall of tiles, one per
session. Its assets are readable at `<base-path>/ai-beacon/docs/assets` - `demo.gif` shows the
thing in motion. That is a preference worth knowing, not a specification, and how it is drawn in
Flutter is yours.

What is worth taking from the shape, because it is functional rather than decorative:

- **One item, one tile, and the state legible without opening it.** The reason to look at this view
  is to not have to go anywhere; a row that requires a click to reveal whether it needs you has
  given that back.
- **The tile carries its own actions.** Answering the question is the point of seeing it.
- **Grouping by machine is a property of the tile, not a mode of the window.** A view that shows
  one machine at a time is the rail again with extra steps.

What is deliberately *not* taken: AI Beacon's tiles lead with model, context and cost. Those are
facts about a session's spending. This view leads with whether somebody is needed and how long
they have - which is the only reason it exists.

## What must be true

**Opening the window answers "does anything need me", for every connected machine at once, without
navigating anywhere - and what it says needs somebody is something this machine knows rather than
something an interface inferred.**

## Acceptance

- The window opens on this view. Reaching it is not an act of navigation.
- Every connected machine's work appears in one list, and which machine a row belongs to is on the
  row rather than in a mode the window is in.
- A task waiting on a clearance question is above one that is merely running, and its deadline is
  shown as time remaining rather than as a timestamp.
- The two or three actions that unblock - answer the question, approve at the gate, attach - are on
  the row, and taking one does not leave this view.
- An inferred state is labelled as inferred, and no inference is drawn where a known state exists.
- A machine that cannot be reached says so **as a row**, not as an absence. A fleet view whose
  quiet means both "nothing needs you" and "three machines are unreachable" is the failure this
  product exists to prevent.
- Counts on a row are as fresh as the row claims, or say when they were taken. See the backend gap
  below - this criterion cannot be met without it.
- Nothing here duplicates [F02](README.md)'s answer to the same question: after this, the project
  row says what a project **is** - prepared, how far behind, how much work - and this view is the
  only place that says what **demands** somebody.

## What the backend is short of, and what it is not

**Nothing here blocks the view.** What the card is *for* already streams: `Prompts` carries a
clearance question and its deadline, `Watch` carries the state. The contract says why that is the
right half to have - *"this is the one place where interface latency costs something real, which is
why it is a stream and not a poll"*. Build against those two.

**What is missing is a push for what `Pending` answers** - how much work waits at the gate.
`Pending` is a call, so the number ages between asks. F02 taught this the hard way: its work pane
updated on a `Watch` push while the row above it kept stale counts, because nothing re-asked.

**Until that stream exists, take F02's own answer** - ask on a cadence and show the age of the
measurement in the same sentence, because a number without one has to be drawn as though it were
current. That is honest, and it is not a workaround: it is the rule this project already applies
to the same kind of number.

Raised against Sokar as `WatchProjects`; a field getting fresher, not a precondition.

## To be checked

- **Whether the actions belong on the card at all when the view is used from elsewhere.** The
  frontend's own open question - whether attaching, opening an editor and putting changes on the
  clipboard can be honoured from another device - decides whether this is a decision surface or a
  full one. A view that invites action leans on that answer harder than a rail does.
- **Whether "needs a person" is one rank or several.** A clearance question has a deadline; work at
  the gate does not, and can sit for days without anything being wrong. Ordering them together may
  put a week-old review above a question with two minutes left.
- **What it does with many machines and much work.** The reason to open the window is a short list
  of things that need answering. Whether that stays true at fifty tasks, or whether it needs
  filtering that then hides something, is a question about the view rather than about the data.
