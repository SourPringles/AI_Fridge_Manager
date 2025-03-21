import 'package:flutter/material.dart';
import 'backend/backend_service.dart';

class SettingsDialog extends StatefulWidget {
  final BackendService backendService;

  const SettingsDialog({super.key, required this.backendService});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _serverController;
  late TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController();
    _portController = TextEditingController();
    _updateInputFields();
  }

  void _updateInputFields() {
    if (widget.backendService.isLocalHost) {
      _serverController.text = "127.0.0.1";
      _portController.text = "5000";
    } else {
      _serverController.text = widget.backendService.serverAddress;
      _portController.text = widget.backendService.port;
    }
  }

  void _applySettings() {
    widget.backendService.updateServerSettings(
      isLocalHost: widget.backendService.isLocalHost,
      serverAddress: _serverController.text,
      port: _portController.text,
    );
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Use LocalHost: '),
                  Switch(
                    value: widget.backendService.isLocalHost,
                    onChanged: (bool value) {
                      setDialogState(() {
                        widget.backendService.isLocalHost = value;
                        _updateInputFields();
                      });
                      setState(() {}); // 다이얼로그 상태 업데이트
                    },
                  ),
                ],
              ),
              TextField(
                controller: _serverController,
                decoration: const InputDecoration(labelText: 'Server Address'),
                enabled: !widget.backendService.isLocalHost,
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
                enabled: !widget.backendService.isLocalHost,
                onChanged: (value) {
                  setDialogState(() {
                    widget.backendService.port = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  _applySettings(); // 설정 적용
                  await widget.backendService.connectionSetting();
                },
                child: const Text('Test Connection'),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            _applySettings(); // 설정 적용
            Navigator.pop(context);
          },
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
