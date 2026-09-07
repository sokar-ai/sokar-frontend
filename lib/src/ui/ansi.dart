import 'package:flutter/material.dart';

/// The character an ANSI escape starts with, spelled out so it survives an editor.
const _escape = '\u001B';

/// Matches one complete colour escape.
final _sgr = RegExp('$_escape\\[[0-9;]*m');

/// Turns a line that may carry ANSI colour into spans that read on either appearance.
///
/// Agents colour their output. A log shown with the escapes left in is unreadable, and one shown
/// with them stripped loses what the colour was carrying — so they are honoured, but never
/// literally: a terminal's black is invisible on a dark background and its bright yellow is
/// invisible on a light one. Each colour is mapped to something from the theme with the same
/// *meaning*, which is what "legible under whatever appearance the person has chosen" asks for.
List<TextSpan> ansiSpans(String line, ColorScheme scheme) {
  final spans = <TextSpan>[];
  var style = const _Sgr();
  var index = 0;

  while (index < line.length) {
    final start = line.indexOf(_escape, index);
    if (start < 0) {
      spans.add(TextSpan(text: line.substring(index), style: style.toStyle(scheme)));
      break;
    }
    if (start > index) {
      spans.add(
          TextSpan(text: line.substring(index, start), style: style.toStyle(scheme)));
    }
    final end = line.indexOf('m', start);
    if (end < 0 || start + 2 > end) {
      // An escape with no terminator is a line cut in half, not a style. `Tail` caps each reply,
      // so that happens. Show it as it came rather than swallowing the rest of the line.
      spans.add(TextSpan(text: line.substring(start), style: style.toStyle(scheme)));
      break;
    }
    style = style.after(line.substring(start + 2, end));
    index = end + 1;
  }

  return spans.isEmpty ? <TextSpan>[TextSpan(text: line)] : spans;
}

/// Whether a line carries any ANSI escape at all.
bool hasAnsi(String line) => line.contains(_escape);

/// Strips ANSI escapes, for somewhere that cannot render them.
String withoutAnsi(String line) => line.replaceAll(_sgr, '');

/// One run of styling, as the escapes so far have set it.
@immutable
class _Sgr {
  const _Sgr({this.colour, this.bold = false, this.faint = false});

  final int? colour;
  final bool bold;
  final bool faint;

  /// Applies the codes in one escape, which may set several things at once.
  _Sgr after(String codes) {
    var next = this;
    for (final part in codes.split(';')) {
      final code = int.tryParse(part.isEmpty ? '0' : part);
      switch (code) {
        case 0:
          next = const _Sgr();
        case 1:
          next = _Sgr(colour: next.colour, bold: true, faint: next.faint);
        case 2:
          next = _Sgr(colour: next.colour, bold: next.bold, faint: true);
        case 22:
          next = _Sgr(colour: next.colour);
        case 39:
          next = _Sgr(bold: next.bold, faint: next.faint);
        default:
          if (code == null) continue;
          // Foreground only, normal (30-37) and bright (90-97). Backgrounds are deliberately
          // ignored: a log that paints its own background cannot stay legible on both
          // appearances, and the person chose the appearance.
          if ((code >= 30 && code <= 37) || (code >= 90 && code <= 97)) {
            next = _Sgr(colour: code % 10, bold: next.bold, faint: next.faint);
          }
      }
    }
    return next;
  }

  /// How this run should be drawn against [scheme].
  TextStyle toStyle(ColorScheme scheme) => TextStyle(
        color: _colourOf(scheme),
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      );

  Color? _colourOf(ColorScheme scheme) {
    if (faint) return scheme.onSurfaceVariant;
    return switch (colour) {
      // Mapped by meaning rather than by name, and taken from the scheme, so each appearance gets
      // a colour that is actually readable against its own background.
      1 => scheme.error, // red: something went wrong
      2 => scheme.primary, // green: something worked
      3 => scheme.tertiary, // yellow: something wants attention
      4 => scheme.secondary, // blue: something said for information
      5 => scheme.tertiary, // magenta
      6 => scheme.secondary, // cyan
      0 || 7 => scheme.onSurface, // black and white: whatever plain is here
      _ => null,
    };
  }
}
