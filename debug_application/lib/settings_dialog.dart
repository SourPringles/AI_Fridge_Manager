import 'package:flutter/material.dart';
import 'service/backend_service.dart';

class SettingsDialog extends StatefulWidget {
  final BackendService backendService;

  const SettingsDialog({super.key, required this.backendService});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _serverController;
  late TextEditingController _portController;
  late TextEditingController _urlController; // URL 입력 필드 컨트롤러
  String _connectionStatus = ""; // 연결 상태 메시지
  bool _isTestingConnection = false; // 연결 테스트 중 상태
  bool _isCloseButtonEnabled = false; // 닫기 버튼 활성화 상태
  late int _selectedInputType; // 0: IP/Port, 1: URL

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController();
    _portController = TextEditingController();
    _urlController = TextEditingController();

    // 이전 설정값을 기반으로 초기화
    if (widget.backendService.url.isNotEmpty) {
      _selectedInputType = 1; // URL이 설정되어 있으면 URL 모드
      _urlController.text = widget.backendService.url;
    } else {
      _selectedInputType = 0; // 그렇지 않으면 IP/Port 모드
      _serverController.text = widget.backendService.serverAddress;
      _portController.text = widget.backendService.port;
    }
  }

  void _updateInputFields() {
    if (_selectedInputType == 0) {
      _serverController.text = widget.backendService.serverAddress;
      _portController.text = widget.backendService.port;
    } else {
      _urlController.text = widget.backendService.url;
    }
  }

  void _applySettings() {
    if (_selectedInputType == 0) {
      widget.backendService.updateServerSettings(
        serverAddress: _serverController.text,
        port: _portController.text,
      );
      widget.backendService.updateUrlSettings(url: ""); // URL 초기화
    } else {
      widget.backendService.updateUrlSettings(url: _urlController.text);
    }
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = ""; // 상태 초기화
      _isCloseButtonEnabled = false; // 닫기 버튼 비활성화
    });

    // 현재 선택된 모드에 따라 설정 적용
    _applySettings();

    final isConnected = await widget.backendService.connectionSetting();

    setState(() {
      _isTestingConnection = false;
      _connectionStatus =
          isConnected ? "Connection Successful" : "Connection Failed";
      _isCloseButtonEnabled = isConnected; // 연결 성공 시 닫기 버튼 활성화
    });
  }

  Future<void> _uploadImageAndFetchInventory(BuildContext context) async {
    final isUploaded = await widget.backendService.uploadImage(context);
    if (isUploaded) {
      await widget.backendService
          .fetchInventory(); // 이미지 업로드 성공 후 fetchInventory 호출
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('설정'),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<int>(
                      title: const Text('IP/Port'),
                      value: 0,
                      groupValue: _selectedInputType,
                      onChanged: (int? value) {
                        setDialogState(() {
                          _selectedInputType = value!;
                          _updateInputFields();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<int>(
                      title: const Text('URL'),
                      value: 1,
                      groupValue: _selectedInputType,
                      onChanged: (int? value) {
                        setDialogState(() {
                          _selectedInputType = value!;
                          _updateInputFields();
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_selectedInputType == 0) ...[
                TextField(
                  controller: _serverController,
                  decoration: const InputDecoration(
                    labelText: 'Server Address',
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      widget.backendService.serverAddress = value;
                    });
                  },
                ),
                TextField(
                  controller: _portController,
                  decoration: const InputDecoration(labelText: 'Port'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setDialogState(() {
                      widget.backendService.port = value;
                    });
                  },
                ),
              ] else ...[
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(labelText: 'URL'),
                  onChanged: (value) {
                    setDialogState(() {
                      widget.backendService.url = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    _isTestingConnection
                        ? null // 비활성화 상태
                        : () async {
                          await _checkConnection(); // 연결 테스트
                        },
                child: Text(_isTestingConnection ? "연결중" : "Test Connection"),
              ),
              if (_connectionStatus.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _connectionStatus,
                    style: TextStyle(
                      color:
                          _connectionStatus == "Connection Successful"
                              ? Colors.green
                              : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed:
              _isCloseButtonEnabled
                  ? () async {
                    _applySettings(); // 설정 적용
                    await widget.backendService
                        .fetchInventory(); // fetchInventory 호출
                    Navigator.pop(context);
                  }
                  : null, // 비활성화 상태
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
