import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sokar_frontend/client.dart';
import 'package:xterm/xterm.dart';

import 'machines.dart';
import 'pty.dart';

/// How a terminal is opened. Injectable, so everything above it runs without a process.
typedef OpenTerminal = SessionChannel Function(
  String executable,
  List<String> arguments, {
  int columns,
  int rows,
});

/// Why work cannot be worked in by hand, decided before anything is started.
///
/// **Predicted rather than discovered.** `Task` says whether a task is running and how somebody
/// is meant to be involved with it, so both of these are answerable without asking the machine —
/// which is the difference between an action offered as unavailable with a reason and an action
/// that fails after somebody presses it.
enum WhyNot {
  /// It is not up. The way back is starting it again, which keeps the workspace it had.
  notRunning,

  /// Its main process is the agent, not a shell, so there is nothing to attach to. What somebody
  /// wants here is the log.
  drivenByAnAgent;

  /// What to say, in a sentence somebody can act on.
  String get words => switch (this) {
        WhyNot.notRunning =>
          'This is not running. Starting it again brings back the workspace, the branch and the '
              'commits it had — and a session with it.',
        WhyNot.drivenByAnAgent =>
          'An agent is what runs in this, not a shell, so there is no session to join. What it is '
              'doing is in its log.',
      };
}

/// Where one session has got to.
enum SessionState {
  /// The way in is being opened.
  opening,

  /// It is open, and what is typed reaches it.
  live,

  /// The far end is gone. [Session.problem] says whether that was ordinary or not.
  over,
}

/// One session against one piece of work.
///
/// **The session is not this object and does not end with it.** What is being drawn here is a way
/// in to `tmux new-session -A -s sokar` inside the container: closing this window leaves that
/// running, and opening it again finds the same session rather than a new one. Everything on
/// screen has to keep saying so, because the opposite assumption — that leaving ends things — is
/// what stops people leaving.
class Session extends ChangeNotifier {
  /// Opens one against [task] on [machine].
  Session({
    required this.task,
    required this.machine,
    OpenTerminal? open,
    int columns = 80,
    int rows = 24,
  }) : _open = open ?? Pty.start {
    terminal = Terminal(maxLines: _scrollback)
      ..onOutput = _typed
      ..onResize = _resized;
    _start(columns, rows);
  }

  /// Which container, as `List` reports it and as every other method takes it.
  final String task;

  /// Which machine it is on. Named on screen because several sessions can be open at once and
  /// two machines can have a task of the same name.
  final Machine machine;

  final OpenTerminal _open;

  /// What is on the screen at the far end.
  late final Terminal terminal;

  /// Where it has got to.
  SessionState state = SessionState.opening;

  /// What went wrong, in words. Null while nothing has.
  ///
  /// **Never a rewording of what the far end said.** `sokar` and `ssh` both say why in their own
  /// sentences, and those are already on the terminal where somebody can read them; what this
  /// adds is what kind of ending it was, which the terminal cannot say.
  String? problem;

  SessionChannel? _channel;
  StreamSubscription<List<int>>? _reading;

  /// Whether this has been left. An ending that arrives afterwards is not news.
  bool _gone = false;

  /// Whether it is open and can be typed into.
  bool get live => state == SessionState.live;

  /// What the command line would be. Public so a test and a person can read the same thing.
  ///
  /// **`ssh -t`, because the far end has to be a terminal.** For a machine somebody else forwards
  /// — a socket path and no host — there is nothing to ssh to, so the verb is run here. Both are
  /// the same command with a different way of reaching it.
  ///
  /// There is deliberately **no `BatchMode=yes` here**, and the tunnel deliberately has one. A
  /// forward has no terminal, so a prompt there is a hang; this *is* a terminal, so a passphrase
  /// or an unknown host key can be answered by the person sitting in front of it.
  List<String> get command => machine.needsATunnel
      ? <String>['ssh', '-t', machine.host, 'sokar', 'task', 'attach', task]
      : <String>['sokar', 'task', 'attach', task];

  /// Sends what somebody typed. Does nothing once it is over, rather than throwing into a widget.
  void type(String input) {
    if (!live) return;
    _channel?.send(input);
  }

  /// Ends this way in.
  ///
  /// **The work inside is untouched.** The multiplexer is a process in the container, so this
  /// closes the channel and the session it reaches carries on — which is why nothing here says
  /// *stop*.
  Future<void> leave() async {
    _gone = true;
    // **The cancel is not waited on and the close is.** Cancelling a subscription to a broadcast
    // stream settles a turn later, and waiting for it put the closing of the channel behind the
    // frame that had already reported the session gone — a window that says it has left while
    // the far end is still attached.
    unawaited(_reading?.cancel());
    _reading = null;
    final channel = _channel;
    _channel = null;
    await channel?.close();
  }

  @override
  void dispose() {
    unawaited(leave());
    super.dispose();
  }

  void _start(int columns, int rows) {
    try {
      final channel = _open(command.first, command.skip(1).toList(),
          columns: columns, rows: rows);
      _channel = channel;
      state = SessionState.live;
      // Decoded as a stream: a chunk can end in the middle of a character, and a decoder per
      // chunk would put a replacement mark on screen every few kilobytes of anything but ASCII.
      _reading = channel.output.listen(
        (bytes) => terminal.write(const Utf8Decoder(allowMalformed: true).convert(bytes)),
      );
      unawaited(channel.ended.then(_itEnded));
    } on PtyRefused catch (refused) {
      state = SessionState.over;
      problem = machine.needsATunnel
          ? 'The way in could not be opened: ${refused.words}.'
          : 'The way in could not be opened: ${refused.words}. A session lives in the container, '
              'so it is reachable only from the machine the daemon runs on.';
    }
    notifyListeners();
  }

  void _typed(String data) => type(data);

  void _resized(int width, int height, int pixelWidth, int pixelHeight) =>
      _channel?.resize(columns: width, rows: height);

  void _itEnded(int code) {
    // Closing the channel ends the far end, so an exit code arrives *after* somebody has left —
    // by which time this is disposed and notifying would throw into whatever is drawing.
    if (_gone) return;
    state = SessionState.over;
    problem = switch (code) {
      0 => null,
      _refused => 'The machine would not open a session here. What it said is above.',
      _sshFailed => 'The connection to ${machine.name} failed. What ssh said is above.',
      _hungUp => null,
      _ => 'The session ended with $code. What it said is above.',
    };
    notifyListeners();
  }

  /// What `sokar task attach` refuses with, for both of its reasons.
  static const int _refused = 69;

  /// ssh's own code for "the connection did not happen".
  static const int _sshFailed = 255;

  /// 128 + SIGHUP: this side closed the channel, which is not a failure.
  static const int _hungUp = 129;

  /// How much a session can show of what happened while nobody was watching.
  ///
  /// **A number, because the criterion is that coming back says what it can show.** This is the
  /// window's own buffer; what a re-attached `tmux` replays is its `history-limit`, which Sokar
  /// pins on its side. Until that figure arrives, nothing here claims one.
  static const int _scrollback = 10000;
}

/// The sessions somebody has open, and the rules about opening one at all.
///
/// **Several at once, each against a different piece of work.** They are kept in the order they
/// were opened and each is named by its task and its machine, because two machines can have a
/// task called the same thing and *"which of these am I typing into"* is the question this list
/// exists to answer.
class Sessions extends ChangeNotifier {
  /// Constructor. [openTerminal] stands in for a real one in tests.
  Sessions({this.openTerminal});

  /// How a terminal is opened. Null means a real pty.
  final OpenTerminal? openTerminal;
  final List<Session> _sessions = <Session>[];

  /// What is open, oldest first.
  List<Session> get all => List<Session>.unmodifiable(_sessions);

  /// Whether anything is open.
  bool get any => _sessions.isNotEmpty;

  /// Why [task] cannot be worked in by hand, or null when it can.
  ///
  /// A task whose mode nothing recorded — every task started before the field existed — is
  /// **offered**. Refusing on a blank would take the action away from work that has a shell in it,
  /// on the strength of not knowing; the far end decides, and says why, if it will not.
  static WhyNot? whyNot(Task task) {
    if (!task.running) return WhyNot.notRunning;
    // Compared as values rather than strings, and **only the two that are known**. A mode this
    // build has never heard of is offered: the far end decides what it will not do, and refusing
    // on an unrecognised name would take the action away from work a later release added.
    if (task.mode == Mode.agent || task.mode == Mode.unattended) {
      return WhyNot.drivenByAnAgent;
    }
    return null;
  }

  /// The session against [task] on [machine], opening one if there is none.
  ///
  /// **Opening the same work twice returns what is already there.** One container holds one
  /// session, so a second way in to it would draw the same screen twice and let somebody type
  /// into either — which is the confusion the criterion about telling sessions apart is about.
  Session openOn(String task, Machine machine) {
    final already = find(task, machine);
    if (already != null) return already;
    final session = Session(task: task, machine: machine, open: openTerminal);
    _sessions.add(session);
    session.addListener(notifyListeners);
    notifyListeners();
    return session;
  }

  /// The session against [task] on [machine], or null.
  Session? find(String task, Machine machine) {
    for (final session in _sessions) {
      if (session.task == task && session.machine == machine) return session;
    }
    return null;
  }

  /// Closes one way in. The work it reached carries on.
  Future<void> leave(Session session) async {
    _sessions.remove(session);
    session.removeListener(notifyListeners);
    await session.leave();
    session.dispose();
    notifyListeners();
  }

  /// Closes every way in, for a window that is being shut.
  Future<void> leaveAll() async {
    for (final session in List<Session>.of(_sessions)) {
      await leave(session);
    }
  }
}
