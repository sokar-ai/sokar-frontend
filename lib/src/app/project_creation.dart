import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_backend.dart';

/// Describing a project, checking it against the machine, and creating it.
///
/// **The checking is the whole reason this is not a form.** Whether a security class is spelled
/// right, whether an egress set exists on that machine, whether the name survives becoming an
/// image tag and an nftables set name — none of that can be answered here. An answer accepted in a
/// dialog and rejected at the first task start is rejected far from where it was given.
///
/// So every change asks the machine with `dryRun`, which **writes nothing**: what comes back is
/// the file as it would be written, plus what is wrong with the answers.
class ProjectCreation extends ChangeNotifier {
  /// Where the project file goes.
  String file = '';

  /// What it is called.
  String name = '';

  /// `offline`, `guarded` or `online`. **Nothing is preselected** — the class decides what work
  /// here may reach, and a default would be a decision nobody made.
  String securityClass = '';

  /// What its image is built from.
  String baseImage = '';

  /// Where an `online` project pushes. Ignored by the other classes.
  String upstream = '';

  /// The egress sets it starts with.
  final Set<String> sets = <String>{};

  /// What the machine last said, or null before it has been asked.
  Created? checked;

  /// What creating it did, or null.
  Created? created;

  /// Whether the machine is being asked right now.
  bool busy = false;

  /// Why it could not be asked, in words.
  String? problem;

  int _asked = 0;
  Timer? _settling;
  FleetBackend? _backend;

  /// Says which machine the answers are checked against.
  ///
  /// **Held rather than passed in at every keystroke**: the checking belongs to one machine for
  /// the whole flow, and a dialog that carried a backend into every field would be handing the
  /// same thing round nine times.
  void startOn(FleetBackend backend) {
    letItBe();
    _backend = backend;
  }

  /// Whether enough has been answered to be worth asking about.
  ///
  /// Asking with half a form would produce a list of complaints about things somebody has not got
  /// to yet, which teaches people to ignore the list.
  bool get worthChecking =>
      file.isNotEmpty && name.isNotEmpty && securityClass.isNotEmpty && baseImage.isNotEmpty;

  /// Whether an `online` project is missing the upstream it needs.
  bool get needsUpstream => securityClass == 'online' && upstream.isEmpty;

  /// Whether it can be created as it stands.
  bool get canBeCreated =>
      worthChecking && !needsUpstream && !(checked?.blocked ?? true);

  /// What the file would contain, for review before anything is written.
  String get content => checked?.content ?? '';

  /// What is wrong and stops it.
  List<Problem> get refusals => checked?.refusals ?? const <Problem>[];

  /// What is wrong and does not stop it.
  ///
  /// Worth showing and not worth blocking on — a base image that is not on the machine yet will
  /// simply be pulled.
  List<Problem> get warnings => checked?.warnings ?? const <Problem>[];

  /// Records an answer and asks the machine about it, once typing has settled.
  void answer(void Function() change) {
    change();
    checked = null;
    created = null;
    notifyListeners();
    _settling?.cancel();
    final backend = _backend;
    if (!worthChecking || backend == null) return;
    // Not on every keystroke: each one is a call, and a project name typed a letter at a time
    // would ask the machine eleven times to be told the same thing.
    _settling = Timer(const Duration(milliseconds: 400), () => check(backend));
  }

  /// Asks the machine what it thinks, writing nothing.
  Future<void> check(FleetBackend backend) async {
    final mine = ++_asked;
    busy = true;
    problem = null;
    notifyListeners();
    try {
      final said = await _ask(backend, dryRun: true);
      if (mine != _asked) return;
      checked = said;
    } on VarlinkDisconnected catch (ex) {
      if (mine != _asked) return;
      problem = 'Lost contact with the machine: ${ex.message}';
    } on FeatureNotSupported catch (ex) {
      if (mine != _asked) return;
      problem = '$ex';
    } finally {
      if (mine == _asked) {
        busy = false;
        notifyListeners();
      }
    }
  }

  /// Creates it.
  Future<void> create(FleetBackend backend) async {
    busy = true;
    problem = null;
    notifyListeners();
    try {
      final said = await _ask(backend);
      created = said;
      checked = said;
    } on VarlinkDisconnected catch (ex) {
      // Deliberately does not say whether the file was written: it may or may not have been, and
      // claiming either sends somebody to the wrong place.
      problem = 'Lost contact with the machine: ${ex.message}. '
          'Whether the file was written is not knowable from here.';
    } on FeatureNotSupported catch (ex) {
      problem = '$ex';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// What to say about what happened, in one line.
  String get words {
    final said = created;
    if (said == null) return '';
    return switch (said.outcome) {
      'CREATED' => '$name is created. Nothing is built yet — preparing its environment takes '
          'minutes, and starting work here would otherwise spend them.',
      // **A refusal and never an overwrite.** The file may be somebody's whole configuration, and
      // this is the one operation that would replace it with nothing to restore from.
      'ALREADY_EXISTS' => 'There is already a project file at $file. Nothing was written.',
      'INVALID' => 'The machine will not take these answers. Nothing was written.',
      'FAILED' => 'It could not be created. ${said.detail}'.trim(),
      _ => '${said.outcome}. ${said.detail}'.trim(),
    };
  }

  /// Forgets everything, for a flow somebody walked away from.
  ///
  /// **Nothing is half-created**: every check ran with `dryRun`, so until the last press there is
  /// nothing on that machine to leave behind.
  void letItBe() {
    _settling?.cancel();
    file = '';
    name = '';
    securityClass = '';
    baseImage = '';
    upstream = '';
    sets.clear();
    checked = null;
    created = null;
    problem = null;
    notifyListeners();
  }

  Future<Created> _ask(FleetBackend backend, {bool? dryRun}) => backend.createProject(
        file: file,
        name: name,
        securityClass: securityClass,
        baseImage: baseImage,
        upstream: upstream.isEmpty ? null : upstream,
        sets: sets.toList(),
        dryRun: dryRun,
      );

  @override
  void dispose() {
    _settling?.cancel();
    super.dispose();
  }
}
