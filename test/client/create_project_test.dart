import 'package:flutter_test/flutter_test.dart';
import 'package:sokar_frontend/client.dart';
import 'package:sokar_frontend/src/mock/mock_daemon.dart';

/// `CreateProject` without a file leaves where it goes to the machine (QF22): the parameter is
/// left out, never sent empty, so a daemon that requires one says so in its own words.
void main() {
  late MockDaemon daemon;

  setUp(() async {
    daemon = MockDaemon();
    await daemon.start();
  });

  tearDown(() => daemon.stop());

  Future<Map<String, dynamic>> asked({String? file}) async {
    Map<String, dynamic>? parameters;
    daemon.method('CreateProject', (given) {
      parameters = given;
      return <String, dynamic>{
        'outcome': 'PREVIEWED',
        'file': '/home/somebody/.config/sokar/projects/x/project.yml',
        'content': '',
        'problems': <Object>[],
        'detail': '',
      };
    });
    final client = await SokarClient.connect(Backend(socketPath: daemon.socketPath, label: 'mock'));
    final created = await client.createProject(
        file: file, name: 'x', securityClass: 'guarded', baseImage: 'ubuntu:24.04', dryRun: true);
    expect(created.file, '/home/somebody/.config/sokar/projects/x/project.yml');
    return parameters!;
  }

  test('no file given sends no file at all', () async {
    expect((await asked()).containsKey('file'), isFalse);
  });

  test('a file given is sent as it is', () async {
    expect((await asked(file: '/srv/x/project.yml'))['file'], '/srv/x/project.yml');
  });
}
