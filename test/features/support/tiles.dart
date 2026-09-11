import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tile for one piece of work, matched on its key rather than on text it happens to show.
Finder tileFor(String work) => find.byWidgetPredicate(
    (widget) => widget is Card && '${widget.key}'.contains("'tile ") && '${widget.key}'.endsWith(" $work'>]"));
