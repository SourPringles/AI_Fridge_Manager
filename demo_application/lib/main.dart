import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'backend/backend_service.dart';
import 'settings_dialog.dart';
import 'backend/location_service.dart';

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
                MaterialPageRoute(
                  builder:
                      (context) => LocationPage(
                        backendService: _backendService, // BackendService 전달
                      ),
                ),
              );
            },
            child: const Text('물건 위치 보기'),
          ),
        ],
      ),
    );
  }
}

class LocationPage extends StatefulWidget {
  final BackendService backendService;

  const LocationPage({super.key, required this.backendService});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late final LocationService _locationService;
  List<Map<String, String>> _items = []; // 서버에서 가져온 데이터 저장
  bool _isLoading = true; // 로딩 상태 확인

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(
      widget.backendService,
    ); // 전달받은 BackendService 사용
    _fetchLocations(); // 페이지 로드 시 데이터 가져오기
  }

  Future<void> _fetchLocations() async {
    final items = await _locationService.fetchLocations();
    setState(() {
      _items = items;
      _isLoading = false; // 로딩 완료
    });
  }

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
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLocations, // 새로고침 버튼
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator()) // 로딩 중 표시
              : Stack(
                children:
                    _items.map((item) {
                      final double x = double.tryParse(item["x"] ?? "0") ?? 0;
                      final double y = double.tryParse(item["y"] ?? "0") ?? 0;
                      return Positioned(
                        left: x,
                        top: y,
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(item["nickname"] ?? "Unknown"),
                                  content: Text(
                                    "QR Code: ${item["qr_code"] ?? "Unknown"}\n"
                                    "Last Modified: ${item["lastModified"] ?? "Unknown"}",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('닫기'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                item["nickname"] ?? "",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
    );
  }
}
