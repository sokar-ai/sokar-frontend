# Updates from Sokar

Backend changes that affect this repository, newest first. Written by the Sokar side; re-read the
IDL off a running daemon (`org.varlink.service.GetInterfaceDescription`) rather than trusting this
summary on the parts it touches.

## 2026-09-07 — the daemon can list projects

You asked for it; it exists. **Additive** - a new method and the type it answers with, nothing
existing changed. This is the method that makes the gate reachable from an interface at all.

```
type Project (
  # Project name, as its file declares it.
  name: string,
  # offline, guarded or online. "" when no task has recorded one.
  securityClass: string,
  # Absolute path of its project.yml on the daemon's machine. "" when unknown.
  file: string,
  # The gate's mirror for it. "" when it has never used the gate.
  mirror: string,
  # How many pushes are waiting for review in that mirror.
  pending: int,
  # How many of its tasks exist right now, running or stopped.
  tasks: int
)

method Projects() -> (projects: []Project)
```

### What to check

1. **`file` is the parameter every gate method wants.** `Pending`, `Review`, `Approve`, `Reject`
   and `Start` all take a project file path, and until now nothing handed you one - over a
   forwarded socket you have no filesystem on that machine to find it in. Take it from here and
   pass it through unchanged; never build one, and never show a file picker for a remote daemon.

2. **`file` can be `""`, and that is a state to render, not an error.** It means no task start has
   recorded a path yet, *or* the recorded file has moved. A moved file is deliberately reported as
   absent rather than as a path nothing can read: a gate call made with it would fail in a way that
   looks like a fault in the daemon. A project with `file: ""` can be listed but not acted on -
   the fix is running a task with it once, from the CLI on that machine.

3. **The list is assembled, not stored.** It comes from the gate mirrors, the tasks that exist and
   the project files task starts have recorded, so a project appears the first time somebody runs a
   task with it. There is no registration call and none is planned - nobody would run one. A
   project with no tasks and no mirror still appears if its file was recorded.

4. **`pending` is the same number `Pending` returns**, counted by asking git rather than by
   counting files, so a packed mirror reports correctly. Use it for a badge; use `Pending` when you
   need the pushes themselves.

5. **Nothing here is refreshed for you.** There is no `WatchProjects`; call `Projects` again after
   anything that would change it (a task started or removed, a push approved).

## 2026-09-07 — the daemon can list a task's logs

**Additive**: a new method and its type.

```
type Log (name: string, bytes: int, at: string)
method Logs(task: string) -> (logs: []Log)
```

1. **Stop holding a list of log names.** Which files a task has depends on what it started: a task
   with no gate has no `gate.log`, one run with `--clearance off` has no `clearance.log`. A client
   that knows the names opens an empty viewer for a file that was never going to exist, and will
   never show one a later release adds.
2. **`name` goes to `Tail` unchanged** - a file name, never a path.
3. **An empty list is normal**, for a purged task or a name that is not a Sokar task. `NoSuchLog`
   remains what `Tail` throws for a file that is not there.
4. **`bytes` is what it is right now**, for showing size or deciding whether to open something
   large. Not a total to count down from.

## 2026-09-07 — a removal says what it destroyed

**Additive only**: the `Stop` reply gained one field.

```
method Stop(...) -> (..., discarded: int)
```

1. **Show it beside a removal.** It counts what the agent installed *inside* the container -
   packages, caches, a built toolchain - which is destroyed with it and has nowhere to arrive,
   unlike the workspace, which the gate holds. Zero unless `removed` is true.
2. **It counts added paths, not changed ones**, so it is "how much", not "what". There is no file
   list behind it.

### Not an API change, but it changes what you will see

- **A failed task is no longer removed.** A non-zero exit stops its container and leaves it in
  place, so `List` shows exited tasks that earlier versions had swept away. They are resumable;
  `Stop` with `purge` discards one.
- **`sokar panic` exists** as a CLI command - stops every running task and every helper, no names,
  removes nothing - but **has no daemon method**, so F18 still has no backend. Ask if you want one.
