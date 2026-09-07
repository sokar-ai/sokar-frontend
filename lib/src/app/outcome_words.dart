import 'package:sokar_frontend/client.dart';

/// What a `Stop` did, in words, named by its consequence.
///
/// Every action reports its outcome and nothing silently appears to succeed — so every value the
/// contract can send has a sentence here, and one it cannot is rendered rather than swallowed.
/// `Outcome` gains entries without that being a breaking change.
String stopWords(String task, Stopped result) {
  final surviving =
      result.surviving == 0 ? '' : ' ${result.surviving} helpers are still alive.';
  // Nothing else records that what the agent installed inside the container ever existed, so a
  // removal that does not mention it is the last chance to know gone. "How much", never "what":
  // there is no list behind the number.
  final discarded = result.discarded == 0
      ? ''
      : ' ${result.discarded} paths it had added went with it.';
  return switch (result.outcome) {
    Outcome.stopped => '$task was stopped and removed.$discarded$surviving',
    Outcome.holdsWork =>
      '$task holds work that never reached the gate, so nothing was touched.',
    Outcome.notATask => '$task is not a task Sokar created. Nothing was touched.',
    Outcome.nothingToStop => 'There was no container or helper called $task.',
    Outcome.nothingKnows =>
      'Nothing could say whether $task holds work, so it was left as it was.',
    Outcome.rescueNeedsItRunning =>
      '$task is already down, so what it holds cannot be read out of it.',
    Outcome.rescueFailed => 'Rescuing $task failed, so nothing was removed. '
        '${result.detail.isEmpty ? '' : result.detail}',
    _ => '$task: ${result.outcome.label}.'
            '${result.detail.isEmpty ? '' : ' ${result.detail}'}'
  };
}

/// What a `Resume` did, in words.
String resumeWords(String task, Resumed result) {
  final drift = result.imageDrift.isEmpty
      ? ''
      : ' The image it was built from has changed since: ${result.imageDrift}';
  return switch (result.outcome) {
    // Fewer started than recorded is a partial resume, and saying "running again" would be a lie.
    Outcome.resumed when result.started < result.recorded =>
      '$task is running again, but only ${result.started} of ${result.recorded} '
          'helpers came back.$drift',
    Outcome.resumed =>
      '$task is running again with ${result.started} helpers.$drift',
    Outcome.alreadyRunning => '$task was already running. Nothing was started.',
    Outcome.noContainer => 'There is no container called $task to start.',
    Outcome.noHelpersRecorded =>
      '$task started, but nothing recorded which helpers it should have.$drift',
    _ => '$task: ${result.outcome.label}.'
  };
}
