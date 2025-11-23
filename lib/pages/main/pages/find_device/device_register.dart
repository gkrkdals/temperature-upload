import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:temperature_upload/pages/main/dialogs/alias_dialog.dart';
import 'package:temperature_upload/pages/main/providers/ble_provider.dart';
import 'package:temperature_upload/pages/main/dialogs/device_dialog.dart';
import 'package:temperature_upload/utils/dialogs.dart';

class DeviceRegister extends StatefulWidget {
  const DeviceRegister({super.key});

  @override
  State<StatefulWidget> createState() => _DeviceRegisterState();
}

class _DeviceRegisterState extends State<DeviceRegister> {

  List<Map<String, String>> _savedDeviceLists = [];

  
  Future<void> checkAndRequestPermission() async {
    if (!Platform.isAndroid) return;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    bool granted = false;

    if (sdkInt >= 31) {
      granted = await Permission.bluetoothScan.request().isGranted &&
                await Permission.bluetoothConnect.request().isGranted;
      if (!await Permission.locationWhenInUse.isGranted) {
        granted = granted && await Permission.locationWhenInUse.request().isGranted;
      }
    } else if (sdkInt >= 29) {
      granted = await Permission.locationWhenInUse.request().isGranted;
    } else {
      showAlert();
      return;
    }

    if (!granted) {
      showAlert();
    }
  }

  void showAlert() {
    showAlertDialog(context, "설정 > 애플리케이션 > 온도측정 > 권한에서 '기기 찾기' 권한을 허용해주세요.");
  }

  Future<void> reloadDevices() async {
    try {
      if (mounted) {
        final loaded = await context.read<BLEProvider>().loadSavedDevices();
        setState(() => _savedDeviceLists = loaded);
      }
    } catch (e) {
      if (mounted) showAlertDialog(context, e.toString());
    }
  }

  Future<void> removeDevice(int index) async {
    final toBeRemoved = _savedDeviceLists[index];
    await context.read<BLEProvider>().removeDevice(toBeRemoved['id']!);
    await reloadDevices();
  }

  Future<void> saveDevice(String id, String alias) async {
    try {
      await context.read<BLEProvider>().saveDevice(id, alias);

      if (mounted) showAlertDialog(context, "기기가 성공적으로 저장되었습니다.");
    } catch (e) {
      if (mounted) showAlertDialog(context, e.toString());
    }
  }

  Future<void> openDeviceSearchDialog(BLEProvider ble) async {
    ble.startScan();

    if (mounted) {
      String? id = await showDialog<String>(
        context: context, 
        builder: (ctx) {
          return ChangeNotifierProvider.value(
            value: ble,
            child: DeviceDialog(
              onDeviceTap: (device) async {
                context.read<BLEProvider>().stopScan();
                final id = device.remoteId.str;
                Navigator.of(ctx).pop(id);
              },
            ),
          );
        }
      );

      if (id != null) {
        openAliasDialog(id);
      }
    }
    
  }

  Future<void> openAliasDialog(String id) async {
    String? alias = await showDialog<String>(
      context: context,
      builder: (_) => AliasDialog(),
    );

    if (alias == null || alias.isEmpty) {
      final parts = id.split(':');
      final firstPart = parts.isNotEmpty ? parts[0] : id;
      alias = "기기_$firstPart";
    }

    await saveDevice(id, alias);
    await reloadDevices();
  }

  Future<void> openRemoveDialog(int index) async {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        content: Text("해당 기기를 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('닫기')),
          TextButton(onPressed: () { removeDevice(index); Navigator.of(ctx).pop(); }, child: Text('삭제'))
        ],
      )
    );
  }

  Future<void> openAddDialog() async {
    final ble = context.read<BLEProvider>();
    final isBluetoothEnabled = await ble.isBluetoothEnabled();
    if (!mounted) return;
    
    if (!isBluetoothEnabled) {
      await showAlertDialog(context, "기기 등록을 위해 블루투스를 켜주세요.");
      return;
    }

    if (
    !(await Permission.bluetoothScan.request().isGranted) ||
        !(await Permission.bluetoothConnect.request().isGranted)
    ) {
      showAlert();
    } else {
      openDeviceSearchDialog(ble);
    }
  }

  @override
  void initState() {
    super.initState();
    checkAndRequestPermission();
    Future.microtask(() => reloadDevices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("기기 등록"),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기기 목록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8,),
            _savedDeviceLists.isEmpty ? 
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                child: Center(
                  child: Text(
                    "저장된 기기가 없습니다.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ) :
              ListView.builder(
                itemCount: _savedDeviceLists.length,
                shrinkWrap: true,
                itemBuilder: (ctx, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(_savedDeviceLists[index]['alias']!),
                      subtitle: Text(_savedDeviceLists[index]['id']!),
                      trailing: IconButton(
                        onPressed: () => openRemoveDialog(index),
                        icon: const Icon(Icons.delete, color: Colors.red)
                      ),
                    ),
                  );
                }
              ),
            SizedBox(height: 16,),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: openAddDialog,
                child: Text('기기 등록하기')
              ),
            )
          ],
        ),
      )
    );
  }
}