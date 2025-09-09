import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';

class BLEProvider extends ChangeNotifier {
  static const String _dataServiceUuid = 'ba2cc24b-9ba4-4316-a285-6687ffc3b6ae';
  static const String _dataCharacteristicUuid = 'f758e745-300f-4f56-9d66-dabce7cc05a3';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --- 스캔 관련 상태 ---
  List<ScanResult> scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool isScanning = false;

  // --- 연결 관련 상태 ---
  BluetoothDevice? connectedDevice;

  // --- 온도 데이터 관련 상태 ---
  double? temperature;
  StreamSubscription<List<int>>? _valueSubscription;

  // ✨ 외부에서 온도 변화를 감지할 수 있도록 StreamController와 Stream 추가
  final StreamController<double?> _tempStreamController = StreamController.broadcast();
  Stream<double?> get temperatureStream => _tempStreamController.stream;

  // --- 기록 관련 상태 ---
  Timer? _recordingTimer;
  final List<Map<String, dynamic>> recordedTemperatures = [];

  void startScan() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    } catch(e) {}

    scanResults = [];
    isScanning = true;
    notifyListeners();

    FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withServices: [],
        androidUsesFineLocation: sdkInt <= 30
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    }, onDone: () {
      isScanning = false;
      notifyListeners();
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    if (device.isConnected) {
      connectedDevice = device;
      return;
    }

    await device.connect(autoConnect: false);
    connectedDevice = device;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await connectedDevice?.disconnect();
    connectedDevice = null;
    notifyListeners();
  }


  Future<BluetoothCharacteristic?> _getCharacteristic() async {
    if (connectedDevice != null) {
      List<BluetoothService> services = await connectedDevice!.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == _dataServiceUuid) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString().toLowerCase() == _dataCharacteristicUuid) {
              return c;
            }
          }
        }
      }
    }
    return null;
  }

  Future<void> discoverAndListen() async {
    await stopListening();
    BluetoothCharacteristic? c = await _getCharacteristic();

    if (c != null && c.properties.notify) {
      if (!c.isNotifying) {
        await c.setNotifyValue(true);
      }
      // setNotifyValue 후 안정화를 위한 약간의 지연
      await Future.delayed(const Duration(milliseconds: 200));

      _valueSubscription = c.lastValueStream.listen((value) {
        final ascii = String.fromCharCodes(value);
        _updateTemperature(ascii);
      });
    }
  }

  void _updateTemperature(String ascii) {
    try {
      final value = double.parse(ascii);
      temperature = value;
      _tempStreamController.add(value); // ✨ Stream으로 데이터 전송
      notifyListeners(); // UI 업데이트 알림
    } catch (_) {
      // 파싱 실패 시 무시
    }
  }

  void startRecording() {
    recordedTemperatures.clear();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // TODO: 주석4
      // temperature ??= 0;
      if (temperature != null) {
        recordedTemperatures.add({
          'time': DateTime.now(),
          'value': temperature!
        });
      }
    });
  }

  void stopRecording() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  Future<void> stopListening() async {
    await _valueSubscription?.cancel();
    _valueSubscription = null;

    try {
      final c = await _getCharacteristic();
      if (c != null && c.isNotifying) {
        await c.setNotifyValue(false);
      }
    } catch(e) {
      // 연결이 이미 끊긴 경우 등 예외 발생 가능
    }

    temperature = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tempStreamController.close();
    super.dispose();
  }

  Future<void> saveDevice(String id, String alias) async {
    await _storage.write(key: 'ble_device_$id', value: alias);
  }

  Future<List<Map<String, String>>> loadSavedDevices() async {
    final all = await _storage.readAll();

    final deviceEntries = all.entries
        .where((e) => e.key.startsWith('ble_device_'))
        .map((e) => {
      'id': e.key.replaceFirst('ble_device_', ''),
      'alias': e.value,
    })
        .toList();

    return deviceEntries;
  }

  Future<void> removeDevice(String id) async {
    await _storage.delete(key: 'ble_device_$id');
  }

  Future<String?> getCurrentDeviceAlias() async {
    String? id = connectedDevice?.remoteId.str;
    if (id == null) return '';
    return _storage.read(key: 'ble_device_$id');
  }

  Future<void> reset() async {
    // 1. 진행 중인 스캔 중지
    if (isScanning) {
      await FlutterBluePlus.stopScan();
      isScanning = false;
    }

    // 2. 연결된 기기 해제
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
    }

    // 3. 모든 구독 및 타이머 취소
    await _valueSubscription?.cancel();
    _valueSubscription = null;

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    _recordingTimer?.cancel();
    _recordingTimer = null;

    // 4. 모든 상태 변수 초기화
    scanResults.clear();
    temperature = null;
    recordedTemperatures.clear();

    // 5. 변경사항 UI에 즉시 반영
    notifyListeners();
  }
}