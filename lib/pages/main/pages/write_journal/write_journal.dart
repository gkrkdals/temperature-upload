import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:temperature_upload/loading_provider.dart';
import 'package:temperature_upload/pages/main/dialogs/device_dialog.dart';
import 'package:temperature_upload/pages/main/providers/ble_provider.dart';
import 'package:temperature_upload/pages/main/pages/write_journal/widgets/device_control.dart';
import 'package:temperature_upload/utils/client.dart';
import 'package:temperature_upload/utils/dialogs.dart';

class WriteJournal extends StatefulWidget {
  const WriteJournal({super.key});

  @override
  State<StatefulWidget> createState() => _WriteJournalState();
}

class _WriteJournalState extends State<WriteJournal> {

  Future<void> logout() async {
    try {
      context.read<LoadingProvider>().startLoading();
      await Client.delete('/api/auth/logout');
      await FlutterSecureStorage().delete(key: 'jwt');
      if (mounted) { context.read<LoadingProvider>().startLoading(); }
      if (mounted) { await context.read<BLEProvider>().reset(); }
      if (mounted) { 
        context.read<LoadingProvider>().stopLoading();
        Navigator.pushReplacementNamed(context, '/login'); 
      }
    } catch (e) {
      if (mounted) {
        showAlertDialog(context, "로그아웃 에러");
      }
    }
  }

  /// 권한 확인 요망 다이얼로그
  void showGrantAlert() {
    showAlertDialog(context, "설정 > 애플리케이션 > 온도측정 > 권한에서 블루투스 관련 권한을 허용해주세요.");
  }

  /// 디바이스 검색 시작
  void openSearchDevices(BLEProvider ble) async {
    bool granted = false;

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 31) { // Android 12+
        granted = await Permission.bluetoothScan.request().isGranted &&
            await Permission.bluetoothConnect.request().isGranted;
      } else { // Android 11 and below
        granted = await Permission.locationWhenInUse.request().isGranted;
      }
    } else {
      granted = true;
    }

    if (!granted) {
      if (mounted) showGrantAlert();
      return;
    }

    ble.startScan();
    
    if (mounted) {
      showDialog(
        context: context, 
        builder: (BuildContext ctx) {
          return ChangeNotifierProvider.value(
            value: ble,
            child: DeviceDialog(
              onDeviceTap: (device) async {
                context.read<LoadingProvider>().startLoading();
                await ble.connect(device);
                if(mounted) {
                  context.read<BLEProvider>().stopScan();
                  context.read<LoadingProvider>().stopLoading();
                }
              },
            ),
          );
        }
      );
    }
  }

  @override
  void initState() {
    // TODO: 주석3
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<BLEProvider>().discoverAndListen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();
    final lp = context.read<LoadingProvider>();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        lp.startLoading();
        await ble.reset();
        lp.stopLoading();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("일지 작성"),
        ),
        body: LayoutBuilder(
          builder: (_, constraints) =>
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SafeArea(child: DeviceControl()),
                      ],
                    ),
                  ),
                ),
              ),
            )
        ),
      )
    );
  }
}