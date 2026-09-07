/// What became of a stop or a resume.
///
/// **Not an enum, deliberately.** The contract says adding a value is not a breaking change and
/// that a client must render one it does not recognise rather than fail on it. A Dart enum with
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

  /// Constructor taking every field.
  const Task({
    required this.name,
    required this.project,
    required this.securityClass,
    required this.state,
    required this.running,
    required this.helpers,
  });

  /// Reads one from a reply.
  factory Task.from(Map<String, dynamic> map) => Task(
        name: _string(map, 'name'),
        project: _string(map, 'project'),
        securityClass: _string(map, 'securityClass'),
        state: _string(map, 'state'),
        running: map['running'] == true,
        helpers: _int(map, 'helpers'),
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

  /// Version it reports, or empty.
  final String version;

  /// Where the binary was found.
  final String from;

  /// Hosts this agent needs, on top of the project's own.
  final List<String> allowedDomains;

  /// Constructor taking every field.
  const Agent({
    required this.name,
    required this.label,
    required this.binary,
    required this.version,
    required this.from,
    required this.allowedDomains,
  });

  /// Reads one from a reply.
  factory Agent.from(Map<String, dynamic> map) => Agent(
        name: _string(map, 'name'),
        label: _string(map, 'label'),
        binary: _string(map, 'binary'),
        version: _string(map, 'version'),
        from: _string(map, 'from'),
        allowedDomains: _strings(map, 'allowedDomains'),
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

  /// Constructor taking every field.
  const Project({
    required this.name,
    required this.securityClass,
    required this.file,
    required this.mirror,
    required this.pending,
    required this.tasks,
  });

  /// Reads one from a reply.
  factory Project.from(Map<String, dynamic> map) => Project(
        name: _string(map, 'name'),
        securityClass: _string(map, 'securityClass'),
        file: _string(map, 'file'),
        mirror: _string(map, 'mirror'),
        pending: _int(map, 'pending'),
        tasks: _int(map, 'tasks'),
      );

  /// Whether anything can be done to it beyond looking at it.
  ///
  /// Every method that acts on a project takes [file], so a project without one can be listed and
  /// not acted on. That is a state to render, never an error.
  bool get canBeActedOn => file.isNotEmpty;
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
