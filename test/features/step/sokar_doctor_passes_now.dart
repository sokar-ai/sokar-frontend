import 'package:flutter_test/flutter_test.dart';

import '../support/world.dart';

/// Usage: sokar doctor passes now
Future<void> sokarDoctorPassesNow(WidgetTester tester) async {
  World.setup.doctorRefuses = null;
}
