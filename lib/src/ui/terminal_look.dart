import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import 'tokens.dart';

/// How something that shows what an agent writes looks: like the terminal a person works in, by
/// hand, whatever the window's theme (the operator, walk 9). Its colours are the real terminal's own
/// (`TerminalThemes.defaultTheme`), so the small console on a tile and the session look alike.
abstract final class TerminalLook {
  static const TerminalTheme _theme = TerminalThemes.defaultTheme;

  /// The terminal's background.
  static const Color background = Color(0xFF1E1E1E);

  /// Its plain text.
  static const Color foreground = Color(0xFFCCCCCC);

  /// Its text, monospace, at [size].
  static TextStyle text({double size = Sizes.terminalText}) =>
      TextStyle(fontFamily: 'monospace', fontSize: size, color: foreground, height: Sizes.terminalLineHeight);

  /// The colours an agent's escapes map to, as the terminal draws them; what `ansiSpans` is given.
  static final ColorScheme colours = ColorScheme.dark(
    surface: _theme.background,
    onSurface: _theme.foreground,
    onSurfaceVariant: _theme.brightBlack,
    error: _theme.red,
    primary: _theme.green,
    tertiary: _theme.yellow,
    secondary: _theme.blue,
  );
}
