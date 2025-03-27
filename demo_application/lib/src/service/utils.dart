import "package:ini/ini.dart";
import 'dart:io';

class IniManager {
  void createConfigFile() {
    File('config.ini').writeAsStringSync('''
[Server]
address = 127.0.0.1
port = 5000
'''); // Create a new file
  }

  // .ini 파일 읽기
  Map<String, String> readConfigFile() {
    try {
      final file = File('config.ini');
      if (!file.existsSync()) {
        throw Exception('Config file not found.');
      }

      final config = Config.fromStrings(file.readAsLinesSync());

      // 특정 섹션과 키의 값 읽기
      final serverAddress = config.get('Server', 'address') ?? 'N/A';
      final serverPort = config.get('Server', 'port') ?? 'N/A';

      return {'Server Address': serverAddress, 'Server Port': serverPort};
    } catch (e) {
      print('first run detected, creating initial files, ${e.toString()}');
      createConfigFile();
      return {};
    }
  }
}
