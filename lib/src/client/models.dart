/// What became of a stop or a resume.
///
/// **Not an enum, deliberately.** The contract says adding a value is not a breaking change and
/// that a client must render one it does not recognize rather than fail on it. A Dart enum with
/// no fallback case is precisely how that rule gets broken - it would look correct until a
/// routine backend release. So this carries the raw name, compares by it, and tells the caller
/// whether it is one of the values this build knows.
class Outcome {
  /// The name exactly as the backend sent it.
  final String name;

  /// Constructor with the wire value.
  const Outcome(this.name);

  // Stop.
  static const notATask = Outcome('NOT_A_TASK');
  static const nothingToStop = Outcome('NOTHING_TO_STOP');
  static const stopped = Outcome('STOPPED');
  static const holdsWork = Outcome('HOLDS_WORK');
  static const nothingKnows = Outcome('NOTHING_KNOWS');
  static const rescueNeedsItRunning = Outcome('RESCUE_NEEDS_IT_RUNNING');
  static const rescueFailed = Outcome('RESCUE_FAILED');

  // Resume.
  static const resumed = Outcome('RESUMED');
  static const alreadyRunning = Outcome('ALREADY_RUNNING');
  static const noContainer = Outcome('NO_CONTAINER');
  static const noHelpersRecorded = Outcome('NO_HELPERS_RECORDED');

  /// Every value this build was written against.
  static const known = <Outcome>[
    notATask, nothingToStop, stopped, holdsWork, nothingKnows,
    rescueNeedsItRunning, rescueFailed,
    resumed, alreadyRunning, noContainer, noHelpersRecorded,
  ];

  /// Whether this build knows what this value means.
  ///
  /// An interface should still show an unknown one - the backend chose to send it - but it cannot
  /// claim to explain it.
  bool get isKnown => known.contains(this);

  /// The value as a phrase, for a person: `holds work`, and an unknown value lowercased rather
  /// than hidden.
  String get label => name.toLowerCase().replaceAll('_', ' ');

  @override
  bool operator ==(Object other) => other is Outcome && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// What the work is doing, beside — never instead of — the runtime's own words.
///
/// Deliberately not a Dart enum, by the same rule as [Outcome]: adding a value is not a breaking
/// change, so a closed enum is a client that breaks on a routine release.
class Activity {
  /// Constructor taking the name as the contract spells it.
  const Activity(this.name);

  /// The value as it came.
  final String name;

  /// Its container is not up. Stopped, finished or killed — all three.
  static const dead = Activity('DEAD');

  /// Waiting for a person to answer something. **Said by whatever asked**, never guessed from how
  /// long it has been quiet. [Task.waitingFor] says what about.
  static const waiting = Activity('WAITING');

  /// Producing output.
  static const working = Activity('WORKING');

  /// Up, producing nothing, and not waiting for anybody as far as anything can tell.
  static const idle = Activity('IDLE');

  /// Up, and nothing on this side can see what it is doing.
  ///
  /// The normal answer for a task somebody attached a terminal to: its work goes to that terminal
  /// and not to anything the daemon reads. **Never render this as idle** — a state that is
  /// silently wrong is worse than one that says it does not know.
  static const unknown = Activity('UNKNOWN');

  /// The values this build knows. Not a validation list.
  static const known = <Activity>[dead, waiting, working, idle, unknown];

  /// Whether this build knows what it means.
  bool get recognized => known.any((value) => value.name == name);

  /// Words for a person, unrecognized values included.
  String get label => switch (name) {
        'DEAD' => 'not running',
        'WAITING' => 'waiting',
        'WORKING' => 'working',
        'IDLE' => 'idle',
        'UNKNOWN' => 'cannot be seen',
        '' => 'not recorded',
        _ => name.toLowerCase().replaceAll('_', ' '),
      };

  @override
  bool operator ==(Object other) => other is Activity && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// How somebody is meant to be involved in a task.
class Mode {
  /// Constructor taking the name as the contract spells it.
  const Mode(this.name);

  /// The value as it came.
  final String name;

  /// A terminal in the container, driven by hand.
  static const shell = Mode('SHELL');

  /// The agent's own session, attached, with a person working through it.
  static const agent = Mode('AGENT');

  /// Started with a prompt and left to run. Nobody is expected to be watching.
  static const unattended = Mode('UNATTENDED');

  /// The values this build knows.
  static const known = <Mode>[shell, agent, unattended];

  /// Whether this build knows what it means.
  bool get recognized => known.any((value) => value.name == name);

  /// Words for a person.
  String get label => switch (name) {
        'SHELL' => 'a shell, driven by hand',
        'AGENT' => 'an agent session, worked through',
        'UNATTENDED' => 'unattended, against a prompt',
        '' => 'not recorded',
        _ => name.toLowerCase().replaceAll('_', ' '),
      };

  @override
  bool operator ==(Object other) => other is Mode && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// One task on the machine, running or not.
class Task {
  /// Container name, which every other call takes.
  final String name;

  /// Project it belongs to, or empty when nothing recorded one.
  final String project;

  /// `offline`, `guarded`, `online`, or empty.
  final String securityClass;

  /// The container runtime's own words. **Free text for a person; never parse it.**
  final String state;

  /// Whether the runtime says it is up.
  final bool running;

  /// How many recorded helper processes are alive.
  ///
  /// A container that is up with no helpers has lost its gate or its clearance watcher, which is
  /// not the same thing as a healthy task.
  final int helpers;

  /// Which agent is running in it, by the name `Agents` reports. Empty when nothing recorded one.
  final String agent;

  /// How somebody is meant to be involved.
  final Mode mode;

  /// What an unattended task was asked to do. Kept after it has finished.
  final String prompt;

  /// The ref its work goes to, such as `refs/sokar/incoming/shell`.
  final String branch;

  /// When the **current** state began, ISO-8601.
  ///
  /// Empty when the runtime cannot say — a container created and never started answers a zero
  /// time, which renders as a date centuries out. Compute "idle for forty minutes" from this and
  /// never from [state].
  final String since;

  /// What the work is doing, beside [state].
  final Activity activity;

  /// What is enforcing this task's egress: `prompt`, `allow`, `deny` or `off`.
  ///
  /// Empty when nothing recorded it, which is every task started before the field existed —
  /// render the absence rather than guessing `prompt`.
  ///
  /// **`off` is the one to mark wherever the task appears.** Nothing asks and nothing is refused:
  /// the firewall is loaded and no decision is ever put to anybody. Somebody chose that
  /// deliberately, and showing such a run like any other hides the choice.
  final String clearance;

  /// Whether nothing will ever be asked about what this task reaches.
  bool get unenforced => clearance == 'off';

  /// What it is waiting to be told, when [activity] is `WAITING`. A destination, such as
  /// `api.example.test:443`.
  final String waitingFor;

  /// When the current state began, or null when the runtime could not say.
  DateTime? get startedAt => since.isEmpty ? null : DateTime.tryParse(since);

  /// Constructor taking every field.
  const Task({
    required this.name,
    required this.project,
    required this.securityClass,
    required this.state,
    required this.running,
    required this.helpers,
    this.agent = '',
    this.mode = const Mode(''),
    this.prompt = '',
    this.branch = '',
    this.since = '',
    this.activity = const Activity(''),
    this.waitingFor = '',
    this.clearance = '',
  });

  /// Reads one from a reply.
  factory Task.from(Map<String, dynamic> map) => Task(
        name: _string(map, 'name'),
        project: _string(map, 'project'),
        securityClass: _string(map, 'securityClass'),
        state: _string(map, 'state'),
        running: map['running'] == true,
        helpers: _int(map, 'helpers'),
        // A task started before these fields existed answers empty for all of them. That is an
        // absence to render, not an error.
        agent: _string(map, 'agent'),
        mode: Mode(_string(map, 'mode')),
        prompt: _string(map, 'prompt'),
        branch: _string(map, 'branch'),
        since: _string(map, 'since'),
        activity: Activity(_string(map, 'activity')),
        waitingFor: _string(map, 'waitingFor'),
        clearance: _string(map, 'clearance'),
      );
}

/// An agent binary installed on the machine.
class Agent {
  /// Name the binary calls itself by, which is what starting a task takes.
  final String name;

  /// Human-readable name.
  final String label;

  /// The command it runs inside the container.
  final String binary;

  /// The build this agent pins, from `install.version` in its own manifest.
  ///
  /// **Not what the binary says about itself** — nothing executes an agent to ask. The IDL said
  /// otherwise until 2026-09-07, which is how this was recorded as a gap when it was the answer.
  final String version;

  /// Where the binary was found.
  final String from;

  /// Hosts this agent needs, on top of the project's own.
  final List<String> allowedDomains;

  /// Hosts this agent declares and is **deliberately not given**.
  ///
  /// A decision, not an omission — and a dropped packet cannot tell the two apart, which is why
  /// it is worth saying out loud wherever the allowed list is shown.
  final List<String> refusedDomains;

  /// What this agent fetches when it is installed into an image.
  ///
  /// Empty is a normal answer: an agent that writes its tool into the image fetches nothing, so
  /// it has a pinned version and no digest at all.
  final List<InstallArtifact> artifacts;

  /// Constructor taking every field.
  const Agent({
    required this.name,
    required this.label,
    required this.binary,
    required this.version,
    required this.from,
    required this.allowedDomains,
    this.refusedDomains = const <String>[],
    this.artifacts = const <InstallArtifact>[],
  });

  /// Reads one from a reply.
  factory Agent.from(Map<String, dynamic> map) => Agent(
        name: _string(map, 'name'),
        label: _string(map, 'label'),
        binary: _string(map, 'binary'),
        version: _string(map, 'version'),
        from: _string(map, 'from'),
        allowedDomains: _strings(map, 'allowedDomains'),
        refusedDomains: _strings(map, 'refusedDomains'),
        artifacts: _list(map, 'artifacts').map(InstallArtifact.from).toList(),
      );
}

/// One file an agent fetches when it is installed.
///
/// **There are two states and not three.** Either it carries a `sha256`, or it is `unverified`
/// with a stated `reason` — the daemon's own constructor refuses to build one with neither, so
/// nothing here has to render a blank digest with no explanation.
class InstallArtifact {
  /// Where it is fetched from.
  final String url;

  /// Its digest, lower case and 64 characters, or empty when [unverified].
  final String sha256;

  /// Where it lands in the image, or empty.
  final String target;

  /// Whether it is knowingly fetched without a digest.
  final bool unverified;

  /// Why it is unverified. **Never empty when [unverified]**, by the daemon's own rule.
  final String reason;

  /// Constructor taking every field.
  const InstallArtifact({
    required this.url,
    required this.sha256,
    required this.target,
    required this.unverified,
    required this.reason,
  });

  /// Reads one from a reply.
  factory InstallArtifact.from(Map<String, dynamic> map) => InstallArtifact(
        url: _string(map, 'url'),
        sha256: _string(map, 'sha256'),
        target: _string(map, 'target'),
        unverified: map['unverified'] == true,
        reason: _string(map, 'reason'),
      );
}

/// An installed agent binary that is never started, because another copy wins.
///
/// **A list rather than a flag on [Agent].** A shadowed binary is never executed, so it has no
/// `Agent` entry to mark — it is resolved away before anything is listed. The rule is that
/// locations are searched most specific first and the first filename wins.
class ShadowedAgent {
  /// The binary that does not run.
  final String path;

  /// The one that runs instead. Named rather than implied: *"not in use"* on its own leaves
  /// somebody asking where to look.
  final String usedInstead;

  /// Constructor taking both paths.
  const ShadowedAgent({required this.path, required this.usedInstead});

  /// Reads one from a reply.
  factory ShadowedAgent.from(Map<String, dynamic> map) => ShadowedAgent(
        path: _string(map, 'path'),
        usedInstead: _string(map, 'usedInstead'),
      );
}

/// One entry in the vault. Never its value.
class Credential {
  /// What it is called.
  final String name;

  /// What kind it is, or empty.
  final String type;

  /// Length of the stored value, so an interface can show that something is there.
  final int characters;

  /// Constructor taking every field.
  const Credential({required this.name, required this.type, required this.characters});

  /// Reads one from a reply.
  factory Credential.from(Map<String, dynamic> map) => Credential(
        name: _string(map, 'name'),
        type: _string(map, 'type'),
        characters: _int(map, 'characters'),
      );
}

/// One project on the machine.
///
/// Assembled by the daemon from the gate mirrors, the tasks that exist and the project files task
/// starts have recorded — not stored, and not registered. A project appears the first time
/// somebody runs a task with it.
class Project {
  /// Project name, as its file declares it.
  final String name;

  /// offline, guarded or online. Empty when no task has recorded one.
  final String securityClass;

  /// Absolute path of its `project.yml` **on the daemon's machine**.
  ///
  /// This is the parameter every gate method wants, and `Start` too. **Pass it through unchanged;
  /// never build one**, and never offer a file picker for it — over a forwarded socket there is no
  /// filesystem on that machine to pick from.
  ///
  /// Empty when no task start has recorded a path yet, or when the recorded file has moved. A
  /// moved file is reported absent rather than as a path nothing can read, because a gate call
  /// made with it would fail in a way that looks like a fault in the daemon.
  final String file;

  /// The gate's mirror for it. Empty when it has never used the gate.
  final String mirror;

  /// How many pushes are waiting for review in that mirror. The same number `Pending` returns.
  final int pending;

  /// How many of its tasks exist right now, running or stopped.
  final int tasks;

  /// How many of those are up.
  ///
  /// Given rather than inferred, and a project with none is the ordinary case — between tasks, or
  /// after one was stopped and can still be resumed, which keeps its workspace. **`Projects`
  /// lists every project, not only the busy ones**; filtering to a busy view is this end's job
  /// and must never be assumed of the other.
  final int running;

  /// Whether a task can start here without building an image first.
  ///
  /// One call on the daemon's side for the whole list, not one per project — `Projects` is asked
  /// again after every task start and every approval, so a subprocess per project would have made
  /// ordinary use of this interface expensive for reasons nothing on screen could explain.
  final bool prepared;

  /// How many commits its mirror is behind the upstream.
  ///
  /// **Meaningless unless [behindReason] is `MEASURED`.** Zero means "up to date" only then; the
  /// other reasons all report zero and mean something else entirely.
  final int behind;

  /// When [behind] was measured, RFC 3339. Empty when it never was.
  ///
  /// **Not optional to show.** A number with no age has to be drawn as though it were current,
  /// and the only thing worse than a stale answer is a stale answer that looks fresh. It is
  /// measured on the daemon's own timer, never on the listing path.
  final String behindMeasured;

  /// Why [behind] says what it says: `MEASURED`, `NEVER_CHECKED`, `NO_UPSTREAM`, `OFFLINE` or
  /// `FAILED`.
  ///
  /// A string rather than an enum, by the rule that already covers [Outcome]: a value added later
  /// must render rather than throw. **There is no `VAULT_LOCKED`** — the gate fetches with the
  /// machine's own git credentials and the vault is not in that path at all.
  final String behindReason;

  /// Prose for a person, only when [behindReason] is `FAILED`. Never parsed.
  final String behindDetail;

  /// Constructor taking every field.
  const Project({
    required this.name,
    required this.securityClass,
    required this.file,
    required this.mirror,
    required this.pending,
    required this.tasks,
    required this.running,
    this.prepared = false,
    this.behind = 0,
    this.behindMeasured = '',
    this.behindReason = '',
    this.behindDetail = '',
  });

  /// Reads one from a reply.
  factory Project.from(Map<String, dynamic> map) => Project(
        name: _string(map, 'name'),
        securityClass: _string(map, 'securityClass'),
        file: _string(map, 'file'),
        mirror: _string(map, 'mirror'),
        pending: _int(map, 'pending'),
        tasks: _int(map, 'tasks'),
        running: _int(map, 'running'),
        prepared: map['prepared'] == true,
        behind: _int(map, 'behind'),
        behindMeasured: _string(map, 'behindMeasured'),
        behindReason: _string(map, 'behindReason'),
        behindDetail: _string(map, 'behindDetail'),
      );

  /// Whether this project is behind its upstream by an amount somebody can act on.
  ///
  /// False for every reason but `MEASURED`, because [behind] is zero in all of them and zero
  /// would otherwise read as *up to date*.
  bool get hasFallenBehind => behindReason == 'MEASURED' && behind > 0;

  /// What to say about how far behind it is, in one line.
  ///
  /// The age is part of the sentence rather than a detail underneath it: the number is only as
  /// good as when it was taken, and a reader who cannot see that has to assume it is current.
  String get behindWords => switch (behindReason) {
        'MEASURED' when behind == 0 => 'Up to date$_asOf',
        'MEASURED' => '$behind behind$_asOf',
        // Not zero, and not up to date. The two are the same number and different sentences.
        'NEVER_CHECKED' => 'Never checked against the upstream',
        'NO_UPSTREAM' => 'No upstream to fall behind',
        'OFFLINE' => 'Not checked: this project reaches nothing',
        'FAILED' => behindDetail.isEmpty
            ? 'The last check did not work'
            : 'The last check did not work: $behindDetail',
        // Added after this build shipped. Rendered, never thrown on.
        '' => 'Nothing said how far behind it is',
        _ => behindReason.toLowerCase().replaceAll('_', ' '),
      };

  String get _asOf {
    final when = DateTime.tryParse(behindMeasured);
    if (when == null) return '';
    final ago = DateTime.now().difference(when);
    if (ago.isNegative || ago.inMinutes < 1) return ', measured just now';
    if (ago.inMinutes < 60) return ', as of ${ago.inMinutes} minutes ago';
    if (ago.inHours < 48) return ', as of ${ago.inHours} hours ago';
    return ', as of ${ago.inDays} days ago';
  }

  /// Whether anything can be done to it beyond looking at it.
  ///
  /// Every method that acts on a project takes [file], so a project without one can be listed and
  /// not acted on. That is a state to render, never an error.
  bool get canBeActedOn => file.isNotEmpty;
}

/// One host a project's work may reach, and what granted it.
class EgressHost {
  /// The host.
  final String host;

  /// What granted it: `agent <name>`, `provider <name>`, `set <name>`, `project` or `upstream`.
  ///
  /// **The first grant wins**, so a host in both a set and an agent's list is reported as the
  /// agent's — which is why the order it arrives in is meaningful and must not be sorted away.
  final String origin;

  /// Constructor taking the host and its origin.
  const EgressHost({required this.host, required this.origin});

  /// Reads one from a reply.
  factory EgressHost.from(Map<String, dynamic> map) =>
      EgressHost(host: _string(map, 'host'), origin: _string(map, 'origin'));
}

/// A curated set of destinations, installed on the machine.
class EgressSet {
  /// What a project writes in its `egress.sets`, and what `SetEgress` takes.
  final String name;

  /// Human-readable name, for a listing.
  final String label;

  /// The hosts it grants, in the order the file declares them.
  ///
  /// Shown, because a set exists so nobody authors host lists by hand, and that only works if the
  /// name can be seen through.
  final List<String> domains;

  /// Constructor taking every field.
  const EgressSet({
    required this.name,
    required this.label,
    required this.domains,
  });

  /// Reads one from a reply.
  factory EgressSet.from(Map<String, dynamic> map) => EgressSet(
        name: _string(map, 'name'),
        label: _string(map, 'label'),
        domains: _strings(map, 'domains'),
      );
}

/// What a change to a project's egress did, or would do.
///
/// **Every refusal is an outcome, not an exception.** Not a Dart enum, by the rule that already
/// covers [Outcome]: a value added later must render rather than throw.
class EgressOutcome {
  /// Constructor taking the name as the contract spells it.
  const EgressOutcome(this.name);

  /// The value as it came.
  final String name;

  /// Applied and written to the project file.
  static const changed = EgressOutcome('CHANGED');

  /// What it would do. Nothing was written, because `dryRun` was set.
  static const previewed = EgressOutcome('PREVIEWED');

  /// The file already said that.
  static const noChange = EgressOutcome('NO_CHANGE');

  /// A named set is not installed here, so the file would name nothing real.
  static const noSuchSet = EgressOutcome('NO_SUCH_SET');

  /// An offline project declares no egress at all.
  static const refusedByClass = EgressOutcome('REFUSED_BY_CLASS');

  /// The project file could not be read.
  static const unreadable = EgressOutcome('UNREADABLE');

  /// The change was right and the file could not be written — `opens` and `closes` still say what
  /// it would have done.
  static const notWritten = EgressOutcome('NOT_WRITTEN');

  /// The values this build knows.
  static const known = <EgressOutcome>[
    changed,
    previewed,
    noChange,
    noSuchSet,
    refusedByClass,
    unreadable,
    notWritten,
  ];

  /// Whether this build knows what it means.
  bool get recognized => known.any((value) => value.name == name);

  /// Whether anything was actually written.
  bool get wrote => name == 'CHANGED';

  /// Words for a person, unrecognized values included.
  String get label {
    final words = name.toLowerCase().split('_').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return name;
    words[0] = words.first[0].toUpperCase() + words.first.substring(1);
    return words.join(' ');
  }

  @override
  bool operator ==(Object other) => other is EgressOutcome && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// What a change to a project's egress did, and what it opened and closed.
class EgressChange {
  /// What happened.
  final EgressOutcome outcome;

  /// Hosts the change opens, in the order the sources granted them. **Never sorted.**
  final List<EgressHost> opens;

  /// Hosts it closes, in the same order.
  final List<EgressHost> closes;

  /// A sentence to show prominently, and usually empty.
  ///
  /// Filled only when *this* change makes a forge reachable for a guarded project, and not
  /// repeated on later edits — a warning shown when nothing changed is one people learn to skip.
  final String cost;

  /// Why, in words, for an outcome that needs one.
  final String detail;

  /// Constructor taking every field.
  const EgressChange({
    required this.outcome,
    required this.opens,
    required this.closes,
    required this.cost,
    required this.detail,
  });

  /// Reads one from a reply.
  factory EgressChange.from(Map<String, dynamic> map) => EgressChange(
        outcome: EgressOutcome(_string(map, 'outcome')),
        opens: _list(map, 'opens').map(EgressHost.from).toList(),
        closes: _list(map, 'closes').map(EgressHost.from).toList(),
        cost: _string(map, 'cost'),
        detail: _string(map, 'detail'),
      );
}

/// How far a widening goes.
///
/// **Sent, never received**, which is why this is a Dart enum where [WidenOutcome] is not: the
/// tolerance rule is about values arriving from a backend newer than this build, and nothing
/// arrives here. There is no default and the daemon will not pick one — `ScopeRequired` is the
/// answer to omitting it — because "this run needs it" and "this project needs it" are different
/// intentions and a silent default would make one of them for somebody.
enum Scope {
  /// This run only. **It does not outlive the run**: a resumed task rebuilds its ruleset and its
  /// resolver from what is on disk, and a run-only grant is not on disk.
  run('RUN'),

  /// This run and the project file, so the next task starts with it too.
  runAndProject('RUN_AND_PROJECT');

  const Scope(this.wire);

  /// The value as the contract spells it.
  final String wire;
}

/// What widening a running task did, or would do.
///
/// Not a Dart enum, by the rule that already covers [Outcome] and [EgressOutcome]: a value added
/// later must render rather than throw.
class WidenOutcome {
  /// Constructor taking the name as the contract spells it.
  const WidenOutcome(this.name);

  /// The value as it came.
  final String name;

  /// The running task can reach it now.
  static const widened = WidenOutcome('WIDENED');

  /// What it would grant. Nothing was changed, because `dryRun` was set.
  static const previewed = WidenOutcome('PREVIEWED');

  /// It could already reach all of that.
  static const noChange = WidenOutcome('NO_CHANGE');

  /// There is no running container to widen.
  static const notRunning = WidenOutcome('NOT_RUNNING');

  /// An offline project's tasks reach nothing, and this is not a way around that.
  static const refusedByClass = WidenOutcome('REFUSED_BY_CLASS');

  /// **The run was widened and the file was not**, because nothing knows where the file is.
  static const noProjectFile = WidenOutcome('NO_PROJECT_FILE');

  /// It did not work, and [Widened.detail] says what happened.
  static const failed = WidenOutcome('FAILED');

  /// The values this build knows.
  static const known = <WidenOutcome>[
    widened,
    previewed,
    noChange,
    notRunning,
    refusedByClass,
    noProjectFile,
    failed,
  ];

  /// Whether this build knows what it means.
  bool get recognized => known.any((value) => value.name == name);

  /// Whether the running task can reach the names now.
  ///
  /// `NO_PROJECT_FILE` counts. It is a **partial success**: the run was widened and only the file
  /// was not written. Reading it as a failure tells somebody the task still cannot reach the host
  /// when it can, which is the wrong direction to be wrong in.
  bool get reached => name == 'WIDENED' || name == 'NO_PROJECT_FILE';

  /// Whether anything is left to put right.
  ///
  /// `NO_PROJECT_FILE` is not one: nothing broke, and there is nothing to retry.
  bool get failedOutright =>
      name == 'NOT_RUNNING' || name == 'REFUSED_BY_CLASS' || name == 'FAILED';

  /// Words for a person, unrecognized values included.
  String get label {
    final words = name.toLowerCase().split('_').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return name;
    words[0] = words.first[0].toUpperCase() + words.first.substring(1);
    return words.join(' ');
  }

  @override
  bool operator ==(Object other) => other is WidenOutcome && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// What widening a running task granted, and how far it went.
class Widened {
  /// What happened.
  final WidenOutcome outcome;

  /// The names it grants, in the order they were asked for. **Never sorted**, and names rather
  /// than addresses: a grant covers what is under it.
  final List<String> opens;

  /// Whether the project file was written too, so the next task starts with it.
  ///
  /// Read this rather than the scope that was asked for: asking for `RUN_AND_PROJECT` and getting
  /// `false` is exactly what `NO_PROJECT_FILE` means.
  final bool persisted;

  /// Why, in words, for an outcome that needs one.
  final String detail;

  /// Constructor taking every field.
  const Widened({
    required this.outcome,
    required this.opens,
    required this.persisted,
    required this.detail,
  });

  /// Reads one from a reply.
  factory Widened.from(Map<String, dynamic> map) => Widened(
        outcome: WidenOutcome(_string(map, 'outcome')),
        opens: (map['opens'] is List)
            ? (map['opens']! as List).whereType<String>().toList()
            : const <String>[],
        persisted: map['persisted'] == true,
        detail: _string(map, 'detail'),
      );
}

/// One of a task's log files.
class Log {
  /// File name. **Pass it to `Tail` unchanged** — it is a name, never a path.
  final String name;

  /// How large it is right now. A tail that is running will pass it, so it is a size to show or
  /// to decide by, never a total to count down from.
  final int bytes;

  /// When it was last written, ISO-8601.
  final String at;

  /// Constructor taking every field.
  const Log({required this.name, required this.bytes, required this.at});

  /// Reads one from a reply.
  factory Log.from(Map<String, dynamic> map) => Log(
        name: _string(map, 'name'),
        bytes: _int(map, 'bytes'),
        at: _string(map, 'at'),
      );
}

/// A push waiting at the gate for a decision.
class PendingPush {
  /// Ref name, which reviewing, approving and rejecting all take.
  final String name;

  /// Commit at the tip.
  final String commit;

  /// First line of its message.
  final String subject;

  /// How long it has been waiting, as words.
  final String waiting;

  /// When it arrived, ISO-8601.
  final String at;

  /// Constructor taking every field.
  const PendingPush({
    required this.name,
    required this.commit,
    required this.subject,
    required this.waiting,
    required this.at,
  });

  /// Reads one from a reply.
  factory PendingPush.from(Map<String, dynamic> map) => PendingPush(
        name: _string(map, 'name'),
        commit: _string(map, 'commit'),
        subject: _string(map, 'subject'),
        waiting: _string(map, 'waiting'),
        at: _string(map, 'at'),
      );
}

/// A connection a task tried to make and was stopped for.
///
/// The task is blocked while this goes unanswered and the watcher gives up on its own timeout, so
/// this is the one place where interface latency costs something real.
class Prompt {
  /// Container name, for routing the answer back.
  final String task;

  /// Pass this back unchanged when deciding. **Never rebuild it** - it is derived, and a client
  /// that got the derivation wrong would answer a prompt that does not exist.
  final String key;

  /// Host or address the task asked for.
  final String destination;

  /// `tcp` or `udp`.
  final String protocol;

  /// Port, or zero when there is none.
  final int port;

  /// When it was blocked, ISO-8601.
  final String at;

  /// Where in the ruleset it was stopped. Empty on an event carrying a [verdict] — nothing
  /// decided it a second time.
  final String prefix;

  /// Absent while the question is open; `allow`, `deny` or `timeout` once it is settled.
  ///
  /// A plain string on purpose. The contract declares it as one rather than as an enumeration,
  /// and a closed Dart enum is exactly how the tolerance rule gets broken.
  final String? verdict;

  /// Constructor taking every field.
  const Prompt({
    required this.task,
    required this.key,
    required this.destination,
    required this.protocol,
    required this.port,
    required this.at,
    required this.prefix,
    this.verdict,
  });

  /// Reads one from a reply.
  factory Prompt.from(Map<String, dynamic> map) => Prompt(
        task: _string(map, 'task'),
        key: _string(map, 'key'),
        destination: _string(map, 'destination'),
        protocol: _string(map, 'protocol'),
        port: _int(map, 'port'),
        at: _string(map, 'at'),
        prefix: _string(map, 'prefix'),
        // Genuinely absent rather than empty, which is the difference between an open question
        // and one that was settled by something this build has never heard of.
        verdict: map['verdict'] is String ? map['verdict'] as String : null,
      );

  /// Destination as it should be shown: with the port, unless there is none.
  String get shown => port == 0 ? destination : '$destination:$port';

  /// Whether this event is an answer rather than a question.
  bool get settled => verdict != null;

  /// Whether it ran out rather than being answered.
  ///
  /// The only way to learn that: nothing asks about an expired prompt again, so a question that
  /// simply stops arriving is otherwise indistinguishable from one still waiting for its
  /// operator. `Decide` still works on one, and still takes effect.
  bool get expired => verdict == 'timeout';

  /// What identifies one prompt across the question and the answer to it.
  ///
  /// `task` and `key`, and nothing else. The answer arrives as the same destination a second
  /// time, so anything that keyed on a field which differs between the two — [at] carries the
  /// block time on one and the decision time on the other, [prefix] is empty on the answer —
  /// would show every blocked destination twice.
  String get identity => '$task/$key';
}

/// What a stop did, or refused to do.
class Stopped {
  /// What became of it.
  final Outcome outcome;

  /// What the task holds, when that is why it was refused.
  final String work;

  /// Where rescued work was put, when it was rescued.
  final String rescuedRef;

  /// Whether the container was removed.
  final bool removed;

  /// How many helpers were stopped.
  final int helpers;

  /// How many helpers are still alive. Not zero is worth showing.
  final int surviving;

  /// Why, in words, for an outcome that needs one.
  final String detail;

  /// How many paths the container had that its image did not.
  ///
  /// What the agent installed *inside* it — packages, caches, a built toolchain — which goes with
  /// the container and has nowhere to arrive, unlike the workspace the gate holds. A count and not
  /// a list: a container that ran at all reports `/etc` and `/var` as changed, so only added paths
  /// are counted and there is nothing behind it to enumerate. Zero unless [removed].
  final int discarded;

  /// Constructor taking every field.
  const Stopped({
    required this.outcome,
    required this.work,
    required this.rescuedRef,
    required this.removed,
    required this.helpers,
    required this.surviving,
    required this.detail,
    required this.discarded,
  });

  /// Reads one from a reply.
  factory Stopped.from(Map<String, dynamic> map) => Stopped(
        outcome: Outcome(_string(map, 'outcome')),
        work: _string(map, 'work'),
        rescuedRef: _string(map, 'rescuedRef'),
        removed: map['removed'] == true,
        helpers: _int(map, 'helpers'),
        surviving: _int(map, 'surviving'),
        detail: _string(map, 'detail'),
        discarded: _int(map, 'discarded'),
      );
}

/// What a resume did.
class Resumed {
  /// What became of it.
  final Outcome outcome;

  /// How many helpers were started.
  final int started;

  /// How many the task is recorded as having had. Fewer started than recorded is a partial
  /// resume, and worth saying so.
  final int recorded;

  /// Set when the image the container was built from has changed since.
  final String imageDrift;

  /// What went wrong, per helper that did not come back.
  final List<String> problems;

  /// Constructor taking every field.
  const Resumed({
    required this.outcome,
    required this.started,
    required this.recorded,
    required this.imageDrift,
    required this.problems,
  });

  /// Reads one from a reply.
  factory Resumed.from(Map<String, dynamic> map) => Resumed(
        outcome: Outcome(_string(map, 'outcome')),
        started: _int(map, 'started'),
        recorded: _int(map, 'recorded'),
        imageDrift: _string(map, 'imageDrift'),
        problems: _strings(map, 'problems'),
      );
}

/// What the vault holds, without any of it.
class VaultState {
  /// Where the vault file is.
  final String vault;

  /// Whether that file exists.
  final bool exists;

  /// What is in it, by name only.
  final List<Credential> credentials;

  /// Whether the list can be believed.
  ///
  /// An empty list from a locked vault and an empty list from an empty vault are different
  /// things, and an interface must not show them the same way.
  final bool readable;

  /// Constructor taking every field.
  const VaultState({
    required this.vault,
    required this.exists,
    required this.credentials,
    required this.readable,
  });

  /// Reads one from a reply.
  factory VaultState.from(Map<String, dynamic> map) => VaultState(
        vault: _string(map, 'vault'),
        exists: map['exists'] == true,
        credentials: _list(map, 'credentials').map(Credential.from).toList(),
        readable: map['readable'] == true,
      );
}

/// What the gate has waiting for a project.
class GateState {
  /// Path to the bare mirror the agent pushes into.
  final String mirror;

  /// `offline`, `gatekeeping` or `online`.
  final String mode;

  /// Where the mirror was seeded from, or empty.
  final String seededFrom;

  /// What is waiting.
  final List<PendingPush> pending;

  /// Constructor taking every field.
  const GateState({
    required this.mirror,
    required this.mode,
    required this.seededFrom,
    required this.pending,
  });

  /// Reads one from a reply.
  factory GateState.from(Map<String, dynamic> map) => GateState(
        mirror: _string(map, 'mirror'),
        mode: _string(map, 'mode'),
        seededFrom: _string(map, 'seededFrom'),
        pending: _list(map, 'pending').map(PendingPush.from).toList(),
      );
}

/// What a backend says it is.
class ServiceInfo {
  /// Product name.
  final String product;

  /// Build version. **Show it; never gate a feature on it.**
  final String version;

  /// Who publishes it.
  final String vendor;

  /// Interfaces it serves.
  final List<String> interfaces;

  /// Constructor taking every field.
  const ServiceInfo({
    required this.product,
    required this.version,
    required this.vendor,
    required this.interfaces,
  });

  /// Reads one from a reply.
  factory ServiceInfo.from(Map<String, dynamic> map) => ServiceInfo(
        product: _string(map, 'product'),
        version: _string(map, 'version'),
        vendor: _string(map, 'vendor'),
        interfaces: _strings(map, 'interfaces'),
      );
}

// Readers that never throw on a shape the backend did not promise. New reply fields are expected
// and ignored; a missing one reads as empty rather than as a crash, because a client that dies on
// an unfamiliar reply is a client that dies on a routine backend release.

String _string(Map<String, dynamic> map, String key) {
  final value = map[key];
  return value is String ? value : '';
}

int _int(Map<String, dynamic> map, String key) {
  final value = map[key];
  return value is num ? value.toInt() : 0;
}

List<String> _strings(Map<String, dynamic> map, String key) {
  final value = map[key];
  return value is List ? value.whereType<String>().toList() : const [];
}

List<Map<String, dynamic>> _list(Map<String, dynamic> map, String key) {
  final value = map[key];
  return value is List ? value.whereType<Map<String, dynamic>>().toList() : const [];
}
