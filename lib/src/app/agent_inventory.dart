import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';

import 'fleet_backend.dart';

/// What agents are installed on one machine.
///
/// An agent is installed separately from the thing that runs it, so *what is here* is a real
/// question with a real answer, and the answer is different on every machine. Nothing in this
/// interface names a specific agent: the list is discovered, always.
///
/// **The ones that failed to describe themselves are part of the answer.** An agent that cannot
/// say what it is is installed and unusable, and leaving it out would read as not installed —
/// which is the state somebody would not go looking for.
class AgentInventory extends ChangeNotifier {
  /// What answered, in the order it was given.
  List<Agent> agents = const <Agent>[];

  /// Installed and unusable, by file name, with why.
  Map<String, String> failures = const <String, String>{};

  /// Whether the machine is being asked right now.
  bool busy = false;

  /// Why it could not be read, in words. Null when nothing is wrong.
  String? problem;

  /// Whether anything has been asked yet.
  bool asked = false;

  /// Names that more than one installed copy answers to.
  ///
  /// The contract says where each copy was found and **does not say which one runs**, so this is
  /// as far as the answer goes: two copies exist under one name. Guessing which wins would be a
  /// rule invented here, and the one place it would be read is the place it matters.
  Set<String> get shadowed {
    final seen = <String>{};
    final twice = <String>{};
    for (final agent in agents) {
      if (!seen.add(agent.name)) twice.add(agent.name);
    }
    return twice;
  }

  /// The agents that can be started, one entry per name.
  ///
  /// Two copies under one name would otherwise be two choices that say the same thing, and a
  /// chooser cannot tell them apart any better than this list can.
  List<Agent> get choosable {
    final seen = <String>{};
    return <Agent>[
      for (final agent in agents)
        if (seen.add(agent.name)) agent,
    ];
  }

  /// Asks the machine what it has.
  Future<void> load(FleetBackend backend) async {
    busy = true;
    problem = null;
    notifyListeners();
    try {
      final (installed, couldNotBeRead) = await backend.agentsOn();
      agents = installed;
      failures = couldNotBeRead;
      asked = true;
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
