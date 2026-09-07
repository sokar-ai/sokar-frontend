# Updates from Sokar

Backend changes that affect this repository, newest first. Written by the Sokar side; re-read the
IDL off a running daemon (`org.varlink.service.GetInterfaceDescription`) rather than trusting this
summary on the parts it touches.

## 2026-09-07 (later) — `Project` gained a `running` count

You will have taken `Projects` from the previous note. The type has one more field since then, and
the question behind it is worth answering directly, because it decides how you build the screen.

```
type Project (
  ...
  # How many of its tasks exist right now, running or stopped.
  tasks: int,
  # How many of those are up.
  running: int
)
```

**`Projects` lists every project this machine knows about, not only the active ones.** A project
with nothing running is the ordinary case - between tasks, or after one was stopped and can still
be resumed, which keeps its workspace. A list of only active projects would be empty on a machine
with a dozen projects on it. So `running` is a number in each row rather than a filter on the list:
filter your side if you want a "busy" view, and do not assume the backend did.

The three sources behind a row, in case a value surprises you: the gate mirrors (every project that
has ever used the gate, outliving all its tasks), the tasks that exist (running *or* stopped), and
the project files that task starts have recorded. A project appears once somebody has run a task
with it; there is no registration call and none is planned.

**One more thing you may rely on now:** the registry behind `file` is one file per project rather
than a shared document. The first version was a single JSON file, and 24 concurrent task starts
kept one entry and lost 23 - measured. That is fixed; concurrent starts cannot lose or mix entries.
Nothing in your code changes, but if you saw a path go missing after parallel runs, that was why.
