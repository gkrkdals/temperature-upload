import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BLEProvider extends ChangeNotifier {
  static const String _dataServiceUuid = 'ba2cc24b-9ba4-4316-a285-6687ffc3b6ae';
  static const String _dataCharacteristicUuid = 'f758e745-300f-4f56-9d66-dabce7cc05a3';

  Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

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

  /// 블루투스가 켜져있는지 확인
  Future<bool> isBluetoothEnabled() async {
    var state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

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
      scanResults = results
          .where((r) => r.device.platformName.startsWith('SP'))
          .toList();
      notifyListeners();
    }, onDone: () {
      isScanning = false;
      notifyListeners();
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
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
      _tempStreamController.add(value);
      notifyListeners(); // UI 업데이트 알림
    } catch (_) {
      // 파싱 실패 시 무시
    }
  }

  void startRecording(Duration interval) {
    recordedTemperatures.clear();

    // 시작 즉시 첫 번째 값 기록
    if (temperature != null) {
      recordedTemperatures.add({
        'time': DateTime.now(),
        'value': temperature!
      });
    }

    // 이후 간격에 따라 주기적으로 기록
    _recordingTimer = Timer.periodic(interval, (_) {
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

    // 마지막 온도 값 추가
    if (temperature != null) {
      // 중복 추가 방지: 마지막 기록 시간과 현재 시간 비교
      if (recordedTemperatures.isEmpty ||
          DateTime.now().difference(recordedTemperatures.last['time']) > const Duration(milliseconds: 500)) {
        recordedTemperatures.add({
          'time': DateTime.now(),
          'value': temperature!
        });
      }
    }
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
    final prefs = await _getPrefs();
    await prefs.setString('ble_device_$id', alias);
  }

  Future<List<Map<String, String>>> loadSavedDevices() async {
    final prefs = await _getPrefs();
    final keys = prefs.getKeys();
    return keys
        .where((key) => key.startsWith('ble_device_'))
        .map((key) => {
              'id': key.replaceFirst('ble_device_', ''),
              'alias': prefs.getString(key) ?? '',
            })
        .toList();
  }

  Future<void> removeDevice(String id) async {
    final prefs = await _getPrefs();
    await prefs.remove('ble_device_$id');
  }

  Future<String?> getCurrentDeviceAlias() async {
    String? id = connectedDevice?.remoteId.str;
    if (id == null) return '';

    final prefs = await _getPrefs();
    return prefs.getString('ble_device_$id');
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
