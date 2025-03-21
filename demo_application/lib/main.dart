import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'backend/backend_service.dart';
import 'settings_dialog.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MainPage(),
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
            child: ClipRect(
              // ClipRect를 추가하여 크기 제한을 강제 적용
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final BackendService _backendService =
      BackendService(); // BackendService 인스턴스 생성
  List<Map<String, String>> _items = []; // 서버에서 가져온 데이터 저장
  bool _isFirstLoad = true; // 첫 로드 여부 확인

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSettingsDialog(
        onClose: () {
          _fetchInventory(); // 설정창 닫힌 후 새로고침 수행
        },
      );
    });
  }

  Future<void> _fetchInventory() async {
    final items = await _backendService.fetchInventory();
    setState(() {
      _items = items;
      _isFirstLoad = false; // 첫 로드 완료
    });
  }

  void _showSettingsDialog({VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SettingsDialog(backendService: _backendService);
      },
    ).then((_) {
      if (onClose != null) onClose(); // 설정창 닫힌 후 콜백 실행
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MainPage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInventory, // 새로고침 버튼
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isFirstLoad
                    ? const Center(child: CircularProgressIndicator())
                    : (_items.isEmpty
                        ? const Center(child: Text('No items found'))
                        : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ListTile(
                              title: Text(item["nickname"] ?? ""),
                              subtitle: Text(
                                "QR Code: ${item["qr_code"] ?? ""}\n"
                                "Last Modified: ${item["lastModified"] ?? ""}\n"
                                "Position: (${item["x"]}, ${item["y"]})",
                              ),
                              leading: const Icon(Icons.kitchen),
                              trailing: const Icon(Icons.arrow_forward),
                              onTap: () {
                                print("Tapped on ${item["nickname"]}");
                              },
                            );
                          },
                        )),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LocationPage()),
              );
            },
            child: const Text('물건 위치 보기'),
          ),
        ],
      ),
    );
  }
}

class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('물건 위치 보기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 메인 페이지로 돌아가기
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 설정 버튼 동작
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text('물건 위치를 좌표 기반으로 시각화', textAlign: TextAlign.center),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '빈 화면\n물건 선택 시 해당 QR에 등록된 정보 출력\n(qr_code, nickname, lastModified)',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
