import 'package:flutter/material.dart';

import '../app/logs.dart';
import 'ansi.dart';
import 'panes.dart';
import 'tokens.dart';

/// One of a task's logs, as it is written.
///
/// Inside the interface, deliberately. The alternative — a window per piece of work — does not
/// survive five concurrent runs, which is the number this is for.
class LogView extends StatefulWidget {
  /// Constructor taking what to show and how to leave it.
  const LogView({
    required this.tail,
    required this.logs,
    required this.onClose,
    super.key,
  });

  /// The log being read.
  final LogTail tail;

  /// What is holding it open.
  final Logs logs;

  /// Closes the view. Never stops the reading.
  final VoidCallback onClose;

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final _scroll = ScrollController();
  int _drawn = 0;

  @override
  Widget build(BuildContext context) {
    final tail = widget.tail;
    _keepUp(tail);

    return Column(
      children: <Widget>[
        PaneHeader(
          title: '${tail.log} · ${tail.task}',
          trailing: Row(
            children: <Widget>[
              // Following is a switch and not a scroll position, so reading back cannot turn it
              // off by accident and turning it on again cannot lose what arrived meanwhile.
              Text('Follow', style: Theme.of(context).textTheme.labelMedium),
              Switch(
                key: const Key('follow'),
                value: tail.following,
                onChanged: (following) =>
                    widget.logs.follow(tail, following: following),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close (Esc)',
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
        if (tail.problem != null) _Problem(words: tail.problem!),
        Expanded(child: _lines(context, tail)),
      ],
    );
  }

  Widget _lines(BuildContext context, LogTail tail) {
    if (tail.lines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.loose),
          child: Text(
            tail.problem != null
                ? 'Nothing was read.'
                : 'Nothing has been written to this log yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Scrollbar(
      controller: _scroll,
      child: ListView.builder(
        controller: _scroll,
        primary: false,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.normal,
          vertical: Space.small,
        ),
        itemCount: tail.lines.length,
        itemBuilder: (context, index) => SelectableText.rich(
          TextSpan(
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            children: ansiSpans(tail.lines[index], scheme),
          ),
        ),
      ),
    );
  }

  /// Keeps the newest line in view, but only while following.
  ///
  /// The whole point of suspending is to read back: moving the view under somebody who has just
  /// scrolled up is the same as not having a switch at all.
  void _keepUp(LogTail tail) {
    if (!tail.following || tail.lines.length == _drawn) return;
    _drawn = tail.lines.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.words});

  final String words;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.all(Space.normal),
      child: Text(words, key: const Key('log-problem')),
    );
  }
}

/// Asks which log to read.
///
/// A name typed rather than one chosen, because the contract has no method that lists a task's
/// logs — `Tail` only checks a name against what is there. The names already opened are offered
/// because they are the only ones known to work; the rest is the person's own knowledge, and the
/// dialog says so rather than leaving it to be discovered by naming one that is not there.
Future<String?> askWhichLog(
  BuildContext context, {
  required String task,
  required List<String> known,
}) async {
  final chosen = await showDialog<String>(
    context: context,
    builder: (context) => _WhichLog(task: task, known: known),
  );
  return (chosen == null || chosen.isEmpty) ? null : chosen;
}

class _WhichLog extends StatefulWidget {
  const _WhichLog({required this.task, required this.known});

  final String task;
  final List<String> known;

  @override
  State<_WhichLog> createState() => _WhichLogState();
}

class _WhichLogState extends State<_WhichLog> {
  // Owned by the dialog's own state, because a controller disposed the moment showDialog returns
  // is one the closing animation is still building with.
  final _typed = TextEditingController();

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Read a log of ${widget.task}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _typed,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Log file name',
                  hintText: 'something.log',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (name) => Navigator.of(context).pop(name.trim()),
              ),
              const SizedBox(height: Space.normal),
              Text(
                'This backend cannot list a task\u2019s logs, so the name has to be typed. '
                'A name it does not have is refused, and says so.',
                key: const Key('why-typed'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (widget.known.isNotEmpty) ...<Widget>[
                const SizedBox(height: Space.normal),
                Wrap(
                  spacing: Space.small,
                  children: <Widget>[
                    for (final name in widget.known)
                      ActionChip(
                        label: Text(name),
                        onPressed: () => Navigator.of(context).pop(name),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_typed.text.trim()),
            child: const Text('Read it'),
          ),
        ],
      );

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }
}
