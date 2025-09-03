import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';



class BLEProvider extends ChangeNotifier {
  static const String _dataServiceUuid = 'ba2cc24b-9ba4-4316-a285-6687ffc3b6ae';
  static const String _dataCharacteristicUuid = 'f758e745-300f-4f56-9d66-dabce7cc05a3';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<ScanResult> scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool isScanning = false;

  BluetoothDevice? connectedDevice;

  double? temperature;
  StreamSubscription<List<int>>? _temperatureSubscription;

  Timer? _recordingTimer;
  final List<Map<String, dynamic>> recordedTemperatures = [];
  // bool _isRecording = false;

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

  Future<BluetoothCharacteristic?> _getCharasteristic() async {
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
    BluetoothCharacteristic? c = await _getCharasteristic();
    if (c != null && c.properties.notify) {
      if (!c.isNotifying) {
        await c.setNotifyValue(true);
      }
      await Future.delayed(Duration(milliseconds: 200));

      _temperatureSubscription = c.lastValueStream.listen((value) {
        final ascii = String.fromCharCodes(value);
        updateTemperature(ascii);
      });
    }
  }

  void updateTemperature(String ascii) {
    try {
      final value = double.parse(ascii);
      temperature = value;
      notifyListeners();
    } catch (_) {}
  }

  void startRecording() {
    recordedTemperatures.clear();
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (temperature != null) {
        recordedTemperatures.add({
          'time': DateTime.now(),
          'value': temperature!
        });
      }
    });
  }

  void stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  Future<void> stopListening() async {
    await _temperatureSubscription?.cancel();
    _temperatureSubscription = null;

    final c = await _getCharasteristic();
    if (c != null) {
      await c.setNotifyValue(false);
    }
    temperature = null;
    notifyListeners();
  }

  Future<void> reset() async {
    if (isScanning) {
      await FlutterBluePlus.stopScan();
      isScanning = false;
    }

    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
    }

    await _temperatureSubscription?.cancel();
    _temperatureSubscription = null;

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    _recordingTimer?.cancel();
    _recordingTimer = null;

    final c = await _getCharasteristic();
    if (c != null) {
      await c.setNotifyValue(false);
    }

    _recordingTimer?.cancel();
    _recordingTimer = null;

    scanResults.clear();
    temperature = null;
    recordedTemperatures.clear();
    notifyListeners();
  }

  Future<void> connectToSavedDevice(String id, {void Function()? onFailed}) async {
    final device = BluetoothDevice(remoteId: DeviceIdentifier(id));

    try {
      await device.connect();
    } catch (e) {
      if (onFailed != null) {
        onFailed();
      }
    }
  }

  Future<bool> tryConnectAndVerify(String id) async {
    try {
      final device = BluetoothDevice(remoteId: DeviceIdentifier(id));
      await device.connect();
      return true;
    } catch (_) {
      return false;
    }
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

    if (id == null) {
      return '';
    }

    return _storage.read(key: 'ble_device_$id');
  }

}