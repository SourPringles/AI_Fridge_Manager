import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class BackendService {
  String serverAddress = "25.28.228.203"; // 기본 서버 주소
  String port = "9064"; // 기본 포트
  String url = ""; // URL 저장 변수

  void updateServerSettings({
    required String serverAddress,
    required String port,
  }) {
    this.serverAddress = serverAddress;
    this.port = port;
  }

  void updateUrlSettings({required String url}) {
    this.url = url;
  }

  Uri _buildUri(String endpoint) {
    if (url.isNotEmpty) {
      return Uri.parse("https://$url/$endpoint");
    } else {
      return Uri.parse("http://$serverAddress:$port/$endpoint");
    }
  }

  Future<bool> connectionSetting() async {
    final uri = _buildUri("connectionTest");
    try {
      print(uri);
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  Future<List<Map<String, String>>> fetchInventory() async {
    final uri = _buildUri("inventory");
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

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
    final uri = _buildUri("upload");
    try {
      final response = await http.post(
        uri,
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

  Future<void> updateNickname(String qrCode, String newNickname) async {
    final uri = _buildUri("rename/$qrCode/$newNickname");
    try {
      final response = await http.post(uri);
      if (response.statusCode == 200) {
        print('Nickname updated successfully');
      } else {
        print('Failed to update nickname: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating nickname: $e');
    }
  }

  Future<bool> uploadImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        print('No image selected');
        return false;
      }

      final file = File(pickedFile.path);
      final uri = _buildUri("upload");

      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('curr_image', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        print('Image uploaded successfully');
        return true;
      } else {
        print('Failed to upload image: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return false;
    }
  }
}
