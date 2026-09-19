import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_backend.dart';
import 'templates.dart';

/// Starting work: which project, which agent, which way of being involved, and what to ask for.
///
/// The mode is the part worth being careful about. It is not decoration on a start button — it
/// says whether a person is going to be there. `Start` will default it (`UNATTENDED` when a
/// prompt is given, `SHELL` otherwise), and the default is deliberately not relied on here,
/// because work is started *with* a mode, and a screen that quietly picked one
/// would be answering that for somebody.
class StartWork extends ChangeNotifier {
  /// Which project the work starts in, or null when nothing is being started.
  Project? project;

  /// The agents installed on this machine.
  List<Agent> agents = const <Agent>[];

  /// Agents that could not be read, and why. Shown rather than dropped: an agent missing from a
  /// list is indistinguishable from one that was never installed.
  Map<String, String> failures = const <String, String>{};

  /// Which agent was chosen, by the name `Agents` reports.
  String? agent;

  /// How somebody is meant to be involved. **Null until chosen.**
  Mode? mode;

  /// Which of the project's repositories the work starts in. **Null until chosen, and never
  /// chosen for somebody** (Sokar B67, the operator's decision): not even when there is one.
  String? repository;

  /// Whether a repository has to be chosen: whenever the machine named any. A machine older than
  /// B67 names none and is sent none.
  bool get needsARepository => (project?.repositories ?? const <String>[]).isNotEmpty;

  /// What an unattended run is asked to do.
  String prompt = '';

  /// What to call the work, or empty to let the machine name it.
  ///
  /// Optional on purpose: `Start` names a task when nothing else does, and a name somebody had to
  /// invent before they could begin is a question asked at the worst moment.
  String name = '';

  /// The task being continued, or null when this is new work.
  Task? continuing;

  /// The template this was opened from, or null when it was not.
  Template? from;

  /// What to call this job if it is kept as a template.
  String templateName = '';

  /// Whether the agent list is being read.
  bool busy = false;

  /// Why it could not be read or started, in words.
  String? problem;

  /// Whether work can start here, as the daemon answers it. Null until it has been asked.
  ///
  /// Asked when the dialog opens and again when the agent changes, never cached for the session:
  /// what it answers turns on what the vault holds, and that changes without anything else
  /// changing.
  Readiness? readiness;

  /// Whether a prompt belongs with the chosen mode.
  ///
  /// Only with `UNATTENDED`. The backend accepts `SHELL` with a prompt and records `SHELL`, which
  /// would say a person is driving a run nobody is attached to — so the combination is not
  /// offered rather than sent and regretted.
  bool get takesAPrompt => mode == Mode.unattended;

  /// Whether there is enough to start with.
  ///
  /// An unattended run with no prompt is the one combination that would start something and then
  /// have nothing for it to do.
  bool get ready =>
      project != null &&
      agent != null &&
      mode != null &&
      (!needsARepository || repository != null) &&
      (!takesAPrompt || prompt.trim().isNotEmpty) &&
      nameProblem == null &&
      !refusedOutright;

  /// Why the name cannot be a task's, or null when it can or none was typed.
  ///
  /// **Sokar's rule for a task name**, accepted by the operator on 2026-09-13 after `Foo Bar` was
  /// sent, the image built, and only `podman create` refused it. Lowercase letters, digits and
  /// inner hyphens: podman names the container `sokar-<project>-<task>`, git names the ref after the
  /// task, and a case-insensitive filesystem makes `Foo` and `foo` one ref. Not only digits, which a
  /// login container's name is. And the container name at most [longestContainerName] characters,
  /// because the task's longest socket path must fit. Start stays the authority; this only stops a
  /// name it will refuse from being sent.
  String? get nameProblem => _localNameProblem ?? _refusedName;

  /// The machine's own refusal of the name, when it answered for the name on screen.
  ///
  /// **Its words, not ours**: they carry the rule as it is on that machine and a name that would do.
  String? get _refusedName {
    final answer = readiness;
    if (name.isEmpty || answer == null || _readinessName != name) return null;
    if (answer.outcome != StartOutcome.badTaskName) return null;
    return answer.detail.isEmpty ? 'This is not a name a task can have.' : answer.detail;
  }

  /// Whether what the machine last said is about the name rather than about starting at all.
  bool get readinessIsAboutTheName => readiness?.outcome == StartOutcome.badTaskName;

  String? get _localNameProblem {
    if (name.isEmpty) return null;
    if (name.contains(' ')) return 'A name cannot hold a space. Use lowercase letters, digits and "-".';
    if (name != name.toLowerCase()) return 'A name is lowercase: letters, digits and "-".';
    if (!_taskName.hasMatch(name)) {
      return 'A name holds only lowercase letters, digits and "-", and starts and ends with a letter '
          'or a digit.';
    }
    if (_onlyDigits.hasMatch(name)) return 'A name cannot be only digits.';
    final where = project;
    if (where != null) {
      final container = 'sokar-${where.name}-$name';
      if (container.length > longestContainerName) {
        return 'That name is too long for this project: "$container" is ${container.length} '
            'characters, and at most $longestContainerName fit.';
      }
    }
    return null;
  }

  /// The longest a task's container name may be, prefix included.
  static const int longestContainerName = 65;

  static final RegExp _taskName = RegExp(r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?$');
  static final RegExp _onlyDigits = RegExp(r'^[0-9]+$');

  /// Whether starting would be refused before anything was created.
  ///
  /// **Only for an unattended run.** One that cannot authenticate is certain to be wasted and
  /// nobody is watching it, so the daemon refuses it outright — and a button that is going to be
  /// refused is better not offered. The interactive modes are offered anyway: a person is right
  /// there, may know something this does not, and the cost is said rather than hidden.
  bool get refusedOutright =>
      takesAPrompt &&
      readiness != null &&
      !readiness!.ready &&
      !readinessIsAboutTheName &&
      !readinessIsAboutTheRepository;

  /// Whether the machine's answer is only that a repository has to be chosen — **the dialog's own
  /// required choice**, never a refusal, and never a reason to warn about what starting costs.
  bool get readinessIsAboutTheRepository =>
      readiness?.outcome == StartOutcome.noRepositoryChosen && needsARepository;

  /// What starting would cost when it is offered in spite of a problem.
  ///
  /// Measured on the Sokar side rather than guessed: a missing credential does not stop a launch.
  /// It prints one line and starts anyway, the agent fails to authenticate from inside, and a
  /// failed run is **kept** — so what is left is a container and a workspace to clear up by hand.
  String? get whatItWouldCost {
    final answer = readiness;
    if (answer == null ||
        answer.ready ||
        takesAPrompt ||
        readinessIsAboutTheName ||
        readinessIsAboutTheRepository) {
      return null;
    }
    return 'This will start a container you will have to clear up: the agent cannot '
        'authenticate, and a run that fails is kept rather than removed.';
  }

  /// Why work cannot be started in this project, or null when it can.
  static String? whyNot(Project? project) {
    if (project == null) return 'no project is selected';
    if (!project.canBeActedOn) {
      return '${project.name} is not a project this machine follows';
    }
    return null;
  }

  /// Why this task cannot be continued, or null when it can.
  ///
  /// Continuing means starting the next run with the last one's prompt, extended. Three things
  /// have to be true and each of them is a different reason to say no.
  static String? whyNotContinue(Task? task) {
    if (task == null) return 'no work is selected';
    if (task.running) return 'it is still running';
    if (task.mode != Mode.unattended) {
      return 'only an unattended run is continued with a prompt';
    }
    if (task.prompt.isEmpty) {
      return 'nothing recorded what it was asked to do';
    }
    return null;
  }

  /// Opens it on a project, prefilled from a recurring job somebody named.
  ///
  /// The prompt is put in the box rather than sent as it stands: a template carries the shape of
  /// a job, and the one thing that changes between two runs of the same job is what it is asked
  /// to do this time.
  Future<void> openFrom(
    FleetBackend backend,
    Project project,
    Template template,
  ) async {
    this.project = project;
    // Where the job was named to start — unless the project no longer has that repository, when
    // it is chosen again rather than sent to be refused.
    repository = project.repositories.contains(template.repository) ? template.repository : null;
    continuing = null;
    from = template;
    templateName = template.name;
    agent = template.agent;
    mode = template.mode;
    prompt = template.prompt;
    name = '';
    problem = null;
    notifyListeners();
    await _reading(backend);
  }

  /// Opens it on a project, and reads what agents the machine has.
  Future<void> open(FleetBackend backend, Project project) async {
    this.project = project;
    repository = null;
    continuing = null;
    from = null;
    templateName = '';
    agent = null;
    mode = null;
    prompt = '';
    name = '';
    problem = null;
    notifyListeners();
    await _reading(backend);
  }

  /// Opens it to continue [task], carrying over what the last run was asked to do.
  ///
  /// The old prompt is put in the box rather than sent as it stands: continuing means asking for
  /// something more, and what that is only a person knows.
  Future<void> continueFrom(FleetBackend backend, Project project, Task task) async {
    this.project = project;
    // Continued where it worked: the same repository, not a new choice.
    repository = project.repositoryOf(task);
    continuing = task;
    from = null;
    templateName = '';
    agent = task.agent.isEmpty ? null : task.agent;
    mode = Mode.unattended;
    prompt = task.prompt;
    name = '';
    problem = null;
    notifyListeners();
    await _reading(backend);
  }

  /// Closes it.
  void close() {
    project = null;
    repository = null;
    continuing = null;
    notifyListeners();
  }

  /// Chooses the agent, and asks again whether work can start with it.
  ///
  /// Asked again rather than kept: what `CanStart` answers turns on which agent was chosen, and
  /// an answer from the previous one is worse than none.
  void chooseAgent(String name) {
    agent = name;
    readiness = null;
    notifyListeners();
    final machine = _machine;
    if (machine != null) unawaited(_askWhetherItCanStart(machine));
  }

  /// Chooses the repository the work starts in.
  void chooseRepository(String name) {
    repository = name;
    readiness = null;
    notifyListeners();
    // Asked again: what the machine answers turns on which repository was chosen.
    final machine = _machine;
    if (machine != null) unawaited(_askWhetherItCanStart(machine));
  }

  /// Chooses how somebody is involved.
  void chooseMode(Mode chosen) {
    mode = chosen;
    notifyListeners();
  }

  /// Takes what was typed as the template's name.
  void callTheTemplate(String typed) {
    templateName = typed.trim();
    notifyListeners();
  }

  /// What would be kept as a template, or null when there is not enough to keep.
  ///
  /// Built from what is on screen rather than from what a template was opened with, so keeping a
  /// job after editing it keeps what was edited.
  Template? get asTemplate {
    final where = project;
    final which = agent;
    final how = mode;
    if (where == null || which == null || how == null || templateName.isEmpty) return null;
    return Template(
      name: templateName,
      project: where.name,
      agent: which,
      mode: how,
      prompt: takesAPrompt ? prompt.trim() : '',
      repository: repository ?? '',
    );
  }

  /// Takes what was typed as the name, and asks the machine about it once nothing here objects.
  void callIt(String typed) {
    name = typed.trim();
    notifyListeners();
    final machine = _machine;
    if (machine != null && _localNameProblem == null) unawaited(_askWhetherItCanStart(machine));
  }

  /// Takes what was typed as the thing to ask for.
  void ask(String typed) {
    prompt = typed;
    notifyListeners();
  }

  /// What to call the operation this starts, for somebody reading the list an hour later.
  String get title => switch (mode) {
        Mode.unattended when continuing != null => 'Continue ${continuing!.name}',
        Mode.unattended => 'Run ${agent ?? 'an agent'} in ${project?.name ?? ''}',
        _ => 'Start work in ${project?.name ?? ''}',
      };

  /// The stream the operation is built on. Empty when there is not enough to start with.
  Stream<String> begin(FleetBackend backend) {
    if (!ready) return const Stream<String>.empty();
    return backend.startTask(
      task: name.isEmpty ? null : name,
      project: project!.name,
      agent: agent,
      mode: mode,
      // Only with `UNATTENDED`, and trimmed: a prompt of spaces is not a prompt.
      prompt: takesAPrompt ? prompt.trim() : null,
      repository: repository,
    );
  }

  /// The machine this was opened against, so choosing an agent can ask it again.
  FleetBackend? _machine;

  /// The name the last answer was about, or null when none was sent.
  String? _readinessName;

  /// Counts the questions, so an answer to an earlier one never overwrites a later one.
  int _asked = 0;

  /// Asks the daemon whether work can start, without starting anything.
  ///
  /// **The name goes with it only when nothing here objects to it**: a name refused on this side is
  /// already said, and asking about it would only put the machine's copy of the same sentence
  /// beside it.
  Future<void> _askWhetherItCanStart(FleetBackend backend) async {
    final where = project;
    if (where == null || !where.canBeActedOn) return;
    final asking = ++_asked;
    final about = name.isEmpty || _localNameProblem != null ? null : name;
    try {
      final answer =
          await backend.canStart(project: where.name, agent: agent, task: about, repository: repository);
      // Typing moves faster than a machine answers.
      if (asking != _asked) return;
      readiness = answer;
      _readinessName = about;
    } on VarlinkDisconnected {
      // Nothing to say: the dialog already shows what it could not read, and a second sentence
      // about the same lost connection is noise at the moment somebody is trying to work.
    } on FeatureNotSupported {
      // A backend older than `CanStart`. Nothing is claimed either way, which is what leaving it
      // null means — better than asserting readiness nobody measured.
    }
    notifyListeners();
  }

  Future<void> _reading(FleetBackend backend) async {
    _machine = backend;
    busy = true;
    notifyListeners();
    try {
      final answered = await backend.agentsOn();
      final installed = answered.agents;
      final couldNotBeRead = answered.failures;
      // `Agents` answers one entry per name — they are keyed by name on the daemon side — so
      // this fold is never used. Three lines to keep a broken promise from becoming a crash:
      // `DropdownButtonFormField` asserts on two items sharing a value, which would take the
      // whole dialog down rather than shorten a list.
      final seen = <String>{};
      agents = <Agent>[
        for (final agent in installed)
          if (seen.add(agent.name)) agent,
      ];
      failures = couldNotBeRead;
      // Carried over from a finished run, and the agent may since have been removed. Saying so
      // beats a start that is refused by a name nobody can see is missing.
      if (agent != null && !installed.any((each) => each.name == agent)) {
        problem = '$agent is not installed on this machine any more.';
        agent = null;
      }
      await _askWhetherItCanStart(backend);
    } on VarlinkDisconnected catch (ex) {
      problem = 'Lost contact with the machine: ${ex.message}';
    } on FeatureNotSupported catch (ex) {
      problem = '$ex';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
