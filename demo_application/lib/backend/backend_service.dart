import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  bool isLocalHost = false; // 스위치 상태를 저장하는 변수
  String serverAddress = "25.28.228.203"; // 기본 서버 주소
  String port = "9064"; // 기본 포트

  Future<void> connectionSetting() async {
    Uri url;
    if (isLocalHost) {
      print('LocalHost is ON');
      url = Uri.parse("http://localhost:5000/inventory");
    } else {
      print('LocalHost is OFF');
      url = Uri.parse("http://$serverAddress:$port/inventory");
    }

    print('Fetching from URL: $url'); // URL 확인 로그 추가

    try {
      final response = await http.get(url);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<List<Map<String, String>>> fetchInventory() async {
    Uri url;
    if (isLocalHost) {
      url = Uri.parse("http://localhost:5000/inventory");
    } else {
      url = Uri.parse("http://$serverAddress:$port/inventory");
    }

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // JSON 데이터 처리
        return data.entries.map((entry) {
          final item = entry.value;
          return {
            "qr_code": item["qr_code"]?.toString() ?? "Unknown",
            "nickname": item["nickname"]?.toString() ?? "Unknown",
            "lastModified": item["lastModified"]?.toString() ?? "Unknown",
            "x": item["x"]?.toString() ?? "Unknown",
            "y": item["y"]?.toString() ?? "Unknown",
          };
        }).toList();
      } else {
        print('Failed to fetch inventory: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching inventory: $e');
      return [];
    }
  }

  Future<void> uploadItem(Map<String, String> item) async {
    Uri url;
    if (isLocalHost) {
      url = Uri.parse("http://localhost:5000/upload");
    } else {
      url = Uri.parse("http://$serverAddress:$port/upload");
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(item),
      );
      if (response.statusCode == 200) {
        print('Item uploaded successfully');
      } else {
        print('Failed to upload item: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading item: $e');
    }
  }
}
