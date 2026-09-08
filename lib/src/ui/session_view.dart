import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../app/session.dart';
import 'panes.dart';
import 'tokens.dart';

/// A shell inside running work, drawn in the window.
///
/// **The window is not the session.** What is at the far end is a multiplexer inside the
/// container, so closing this leaves it running and opening it again finds it as it was. Two of
/// the sentences on this screen exist only to say that, because an interface that people think
/// ends their work when they leave it is one they do not leave.
class SessionView extends StatelessWidget {
  /// Constructor taking the session, the others that are open, and the ways out.
  const SessionView({
    required this.session,
    required this.others,
    required this.focusNode,
    required this.onGoTo,
    required this.onLeave,
    required this.onClose,
    super.key,
  });

  /// The session being typed into.
  final Session session;

  /// Everything else that is open, so it is always clear which is which.
  final List<Session> others;

  /// The frame's keyboard for what is open — **handed to the terminal itself**.
  ///
  /// Every other thing that opens over the frame is read rather than typed into, so the frame
  /// holding the keyboard costs them nothing. A terminal is the opposite: with the frame holding
  /// it, `Escape` closed this pane and never reached the far end, which would have made `vim`
  /// unusable inside a session and was found by asking where the key went rather than by
  /// assuming.
  final FocusNode focusNode;

  /// Goes to another open session.
  final void Function(Session session) onGoTo;

  /// Ends this way in. The work at the far end carries on.
  final VoidCallback onLeave;

  /// Puts the session away without ending it.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: session,
        builder: (context, _) {
          final scheme = Theme.of(context).colorScheme;

          return Column(
            children: <Widget>[
              PaneHeader(
                title: '${session.task} · ${session.machine.name}',
                trailing: Row(
                  children: <Widget>[
                    // "Leave" ends the way in; closing does not. Two different things one press
                    // apart, so both say what they do rather than being an X and an X.
                    TextButton.icon(
                      key: const Key('leave-session'),
                      onPressed: onLeave,
                      icon: const Icon(Icons.logout, size: Sizes.rowIcon),
                      label: const Text('Leave'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Put it away, without leaving it',
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              if (others.length > 1) _Which(sessions: others, here: session, onGoTo: onGoTo),
              if (session.problem != null)
                Container(
                  width: double.infinity,
                  color: scheme.errorContainer,
                  padding: const EdgeInsets.all(Space.normal),
                  child: Text(session.problem!, key: const Key('session-problem')),
                )
              else if (session.state == SessionState.over)
                Container(
                  width: double.infinity,
                  color: scheme.surfaceContainerHighest,
                  padding: const EdgeInsets.all(Space.normal),
                  child: const Text(
                    'This way in is closed. The work is where you left it.',
                    key: Key('session-over'),
                  ),
                ),
              Expanded(
                child: ColoredBox(
                  color: scheme.surfaceContainerLowest,
                  child: TerminalView(
                    session.terminal,
                    key: const Key('terminal'),
                    focusNode: focusNode,
                    autofocus: true,
                    padding: const EdgeInsets.all(Space.small),
                    // Read-only once it is over, so keys typed at a dead session do not look
                    // like they went somewhere.
                    readOnly: !session.live,
                    textStyle: const TerminalStyle(fontSize: 13),
                  ),
                ),
              ),
              // Said under the terminal rather than in a tooltip, because it is the one fact
              // that decides whether somebody dares to close the window at all.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.normal, vertical: Space.tight),
                child: Text(
                  'Closing this window leaves the session running. It ends when the work does.',
                  key: const Key('leaving-is-safe'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      );
}

/// Which sessions are open, and which one this is.
class _Which extends StatelessWidget {
  const _Which({required this.sessions, required this.here, required this.onGoTo});

  final List<Session> sessions;
  final Session here;
  final void Function(Session session) onGoTo;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: Space.normal, vertical: Space.tight),
        child: Wrap(
          spacing: Space.small,
          children: <Widget>[
            for (final session in sessions)
              ChoiceChip(
                key: Key('open-session-${session.task}'),
                selected: session == here,
                onSelected: (_) => onGoTo(session),
                // The machine as well as the task: two machines can have a task of the same
                // name, and this list is the one place that has to be unambiguous.
                label: Text('${session.task} · ${session.machine.name}'),
              ),
          ],
        ),
      );
}
