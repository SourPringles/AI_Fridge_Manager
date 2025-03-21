import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _isSwitchOn = false; // 스위치 상태를 저장하는 변수

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Uri url;
                  if (_isSwitchOn) {
                    print('LocalHost is ON');
                    url = Uri.parse("http://localhost:5000/inventory");
                  } else {
                    print('LocalHost is OFF');
                    url = Uri.parse("http://25.28.228.203:9064/inventory");
                  }

                  try {
                    final response = await http.get(url);
                    print('Response status: ${response.statusCode}');
                    print('Response body: ${response.body}');
                  } catch (e) {
                    print('Error: $e');
                  }
                },
                child: const Text('Click Me'),
              ),
              const SizedBox(height: 20), // 버튼과 스위치 사이 간격
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('IsLocalHost: '),
                  Switch(
                    value: _isSwitchOn,
                    onChanged: (bool value) {
                      setState(() {
                        _isSwitchOn = value; // 스위치 상태 업데이트
                      });
                      print('Switch is now: ${value ? "ON" : "OFF"}');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
