import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_backend.dart';

/// Starting work: which project, which agent, which way of being involved, and what to ask for.
///
/// The mode is the part worth being careful about. It is not decoration on a start button — it
/// says whether a person is going to be there. `Start` will default it (`UNATTENDED` when a
/// prompt is given, `SHELL` otherwise), and the default is deliberately not relied on here,
/// because F08 asks for work to be started *with* a mode and a screen that quietly picked one
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

  /// What an unattended run is asked to do.
  String prompt = '';

  /// What to call the work, or empty to let the machine name it.
  ///
  /// Optional on purpose: `Start` names a task when nothing else does, and a name somebody had to
  /// invent before they could begin is a question asked at the worst moment.
  String name = '';

  /// The task being continued, or null when this is new work.
  Task? continuing;

  /// Whether the agent list is being read.
  bool busy = false;

  /// Why it could not be read or started, in words.
  String? problem;

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
      (!takesAPrompt || prompt.trim().isNotEmpty);

  /// Why work cannot be started in this project, or null when it can.
  static String? whyNot(Project? project) {
    if (project == null) return 'no project is selected';
    if (!project.canBeActedOn) {
      return 'no project file is recorded for ${project.name}';
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

  /// Opens it on a project, and reads what agents the machine has.
  Future<void> open(FleetBackend backend, Project project) async {
    this.project = project;
    continuing = null;
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
    continuing = task;
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
    continuing = null;
    notifyListeners();
  }

  /// Chooses the agent.
  void chooseAgent(String name) {
    agent = name;
    notifyListeners();
  }

  /// Chooses how somebody is involved.
  void chooseMode(Mode chosen) {
    mode = chosen;
    notifyListeners();
  }

  /// Takes what was typed as the name.
  void callIt(String typed) {
    name = typed.trim();
    notifyListeners();
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
      project: project!.file,
      agent: agent,
      mode: mode,
      // Only with `UNATTENDED`, and trimmed: a prompt of spaces is not a prompt.
      prompt: takesAPrompt ? prompt.trim() : null,
    );
  }

  Future<void> _reading(FleetBackend backend) async {
    busy = true;
    notifyListeners();
    try {
      final (installed, couldNotBeRead) = await backend.agentsOn();
      // One entry per name. Two copies installed under one name would be two choices saying the
      // same thing, and a chooser cannot tell them apart any better than the answer does — the
      // contract says where each was found and not which one runs. Seeing both is what the agent
      // inventory is for.
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
