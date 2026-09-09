import 'package:flutter/material.dart';

import 'package:sokar_frontend/client.dart';

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

/// Asks which of a task's logs to read.
///
/// The list comes from the daemon, never from a set of names held here: which files a task has
/// depends on what it started — one with no gate has no `gate.log` — so a client that knew the
/// names would offer a file that was never going to exist and would never show one a later
/// release adds. Same rule as a prompt's key: derive nothing at this end that the far end knows.
Future<String?> askWhichLog(
  BuildContext context, {
  required String task,
  required Future<List<Log>> logs,
}) =>
    showDialog<String>(
      context: context,
      builder: (context) => _WhichLog(task: task, logs: logs),
    );

class _WhichLog extends StatelessWidget {
  const _WhichLog({required this.task, required this.logs});

  final String task;
  final Future<List<Log>> logs;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Read a log of $task'),
        content: SizedBox(
          width: 460,
          child: FutureBuilder<List<Log>>(
            future: logs,
            builder: (context, asked) {
              if (asked.hasError) {
                return Text('Its logs could not be asked for: ${asked.error}');
              }
              if (!asked.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(Space.loose),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final found = asked.data!;
              if (found.isEmpty) {
                // A normal answer, not a failure: a task whose state directory is gone — which is
                // what stopping with purge does — has no logs at all.
                return const Padding(
                  padding: EdgeInsets.all(Space.normal),
                  child: Text(
                    'This task has no logs. One that has been removed keeps none, and neither '
                    'does a name that is not a Sokar task.',
                    key: Key('no-logs'),
                  ),
                );
              }
              return ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (final log in found)
                    ListTile(
                      dense: true,
                      isThreeLine: log.what != null,
                      title: Text(log.name),
                      // **The name is not always the answer.** `events.jsonl` is what the firewall
                      // blocked — the file to read when a task starts and then does nothing — and
                      // nothing about the name says so. The sentence comes from the machine, so a
                      // file added later arrives explained rather than bare.
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (log.what != null)
                            Text(log.what!, key: const Key('what-the-log-holds')),
                          Text('${_size(log.bytes)} · last written ${log.at}'),
                        ],
                      ),
                      onTap: () => Navigator.of(context).pop(log.name),
                    ),
                ],
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );

  /// Size as a person reads it. What it is *now*: a log being written passes it.
  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} kB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
