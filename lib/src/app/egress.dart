import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_backend.dart';

/// What one project's work may reach, and the editing of it.
///
/// **The most consequential edit in the product**, so nothing here writes without having shown
/// what it would do first. `dryRun` answers exactly the hosts a real call would open and close,
/// having written nothing, and the preview is the thing somebody agrees to.
class Egress extends ChangeNotifier {
  /// Which project this is about.
  Project? project;

  /// Every host its work may reach, in the order the sources granted them. **Never sorted:** the
  /// first grant wins, so the order is what says which source a host came from.
  List<EgressHost> reachable = const <EgressHost>[];

  /// What an agent asks for and is deliberately not given.
  ///
  /// The distinction a dropped packet cannot make: "we said no" and "nobody added it" look
  /// identical to the firewall, and only one of them is somebody's decision.
  List<String> refused = const <String>[];

  /// The sets installed on this machine, and the directories searched, most specific first.
  List<EgressSet> sets = const <EgressSet>[];

  /// Where the sets were found, in search order.
  List<String> locations = const <String>[];

  /// What the change being considered would do, or null when nothing is being considered.
  EgressChange? preview;

  /// What the last change actually did.
  EgressChange? applied;

  /// Whether something is being asked for right now.
  bool busy = false;

  /// Why it could not be read or changed, in words.
  String? problem;

  /// Whether this project can be asked about at all.
  bool get reachableAtAll => project?.canBeActedOn ?? false;

  /// Reads what a project may reach, and what sets exist to choose from.
  Future<void> lookAt(FleetBackend backend, Project project) async {
    this.project = project;
    preview = null;
    applied = null;
    if (!project.canBeActedOn) {
      reachable = const <EgressHost>[];
      refused = const <String>[];
      problem = 'No project file is recorded for ${project.name}, and every call about its '
          'egress takes one. Running a task with it once records it.';
      notifyListeners();
      return;
    }
    await _asking(() async {
      final (hosts, notGiven) = await backend.egressOf(project.file);
      final (installed, where) = await backend.egressSets();
      reachable = hosts;
      refused = notGiven;
      sets = installed;
      locations = where;
    });
  }

  /// Works out what a change would do, without doing it.
  Future<void> consider(
    FleetBackend backend, {
    List<String>? addSets,
    List<String>? removeSets,
    List<String>? addDomains,
    List<String>? removeDomains,
  }) async {
    final file = project?.file;
    if (file == null || file.isEmpty) return;
    applied = null;
    await _asking(() async {
      preview = await backend.changeEgress(
        file,
        addSets: addSets,
        removeSets: removeSets,
        addDomains: addDomains,
        removeDomains: removeDomains,
        dryRun: true,
      );
    });
  }

  /// Makes the change that was previewed.
  ///
  /// The same arguments, deliberately passed again rather than remembered as a promise: what is
  /// agreed to is the preview, and asking twice with the same words is what makes them the same
  /// change.
  Future<void> apply(
    FleetBackend backend, {
    List<String>? addSets,
    List<String>? removeSets,
    List<String>? addDomains,
    List<String>? removeDomains,
  }) async {
    final file = project?.file;
    if (file == null || file.isEmpty) return;
    await _asking(() async {
      applied = await backend.changeEgress(
        file,
        addSets: addSets,
        removeSets: removeSets,
        addDomains: addDomains,
        removeDomains: removeDomains,
      );
      preview = null;
      if (applied!.outcome.wrote) {
        final (hosts, notGiven) = await backend.egressOf(file);
        reachable = hosts;
        refused = notGiven;
      }
    });
  }

  /// Puts a preview or a result away.
  void letItBe() {
    preview = null;
    applied = null;
    notifyListeners();
  }

  Future<void> _asking(Future<void> Function() ask) async {
    busy = true;
    problem = null;
    notifyListeners();
    try {
      await ask();
    } on VarlinkException catch (refusal) {
      problem = refusal.simpleName == 'ProjectRequired'
          ? 'No project file was given, and every call about egress takes one.'
          : 'Refused: ${refusal.simpleName}.';
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
