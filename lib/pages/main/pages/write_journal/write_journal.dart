import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  void openSearchDevices(BLEProvider ble) {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const DeviceControl(),
            ],
          ),
        ),
      )
    );
  }
}