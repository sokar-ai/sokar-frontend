import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_backend.dart';

/// How a followed repository's commits are to be checked. Chosen, never assumed.
enum Checking {
  /// Against a public key pinned for this project.
  pinned,

  /// Not at all: whoever can push to the repository decides what this machine runs.
  unverified,
}

/// Following a project's repository, which is the only way a project comes to a machine.
///
/// **Nothing about the project is described here.** Its `project.yml` is written where its owner
/// commits, and what is wrong with it comes back from the follow as the named reasons — the machine
/// checks what it is handed, when it is handed it.
class ProjectFollowing extends ChangeNotifier {
  /// The project's name, which must be the one its `project.yml` gives itself.
  String name = '';

  /// Where its repository is: a URL, or a directory on that machine.
  String url = '';

  /// How its commits are checked, or null until somebody chooses.
  Checking? checking;

  /// The public key commits must be signed with, when [checking] is [Checking.pinned].
  String key = '';

  /// What the machine answered, or null before it was asked.
  Followed? answer;

  /// Whether the machine is being asked right now.
  bool busy = false;

  /// Why it could not be asked at all, in words.
  String? problem;

  FleetBackend? _backend;

  /// Opens it empty, for [backend]'s machine.
  void startOn(FleetBackend backend) {
    _backend = backend;
    name = '';
    url = '';
    checking = null;
    key = '';
    answer = null;
    problem = null;
    notifyListeners();
  }

  /// Takes a change to what was typed or chosen. Any answer was about the old values.
  void answerWith(void Function() change) {
    change();
    answer = null;
    problem = null;
    notifyListeners();
  }

  /// Whether everything a follow needs is there, with the checking chosen rather than defaulted.
  bool get ready =>
      name.trim().isNotEmpty &&
      url.trim().isNotEmpty &&
      (checking == Checking.unverified || (checking == Checking.pinned && key.trim().isNotEmpty));

  /// Whether the project is now in force on the machine.
  bool get taken => answer?.inForce ?? false;

  /// Whether the answer is a rewritten history, which only a person may accept.
  bool get rewritten => answer?.outcome == 'REWRITTEN';

  /// Follows it. With [acceptRewrite], a person's answer to a rewritten history — never a retry.
  Future<void> follow({bool acceptRewrite = false}) async {
    final backend = _backend;
    if (backend == null || !ready) return;
    busy = true;
    problem = null;
    notifyListeners();
    try {
      answer = await backend.follow(
        name.trim(),
        url.trim(),
        signedBy: checking == Checking.pinned ? key.trim() : null,
        unverified: checking == Checking.unverified ? true : null,
        acceptRewrite: acceptRewrite ? true : null,
      );
    } on VarlinkException catch (refusal) {
      final said = refusal.parameters['message'];
      problem = said is String && said.isNotEmpty ? said : 'Refused: ${refusal.simpleName}.';
    } on VarlinkDisconnected catch (ex) {
      problem = 'Lost contact with the machine: ${ex.message}';
    } on FeatureNotSupported catch (ex) {
      problem = '$ex';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Puts it away.
  void letItBe() {
    _backend = null;
    answer = null;
    problem = null;
    notifyListeners();
  }
}
