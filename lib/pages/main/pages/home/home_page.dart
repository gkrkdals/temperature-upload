import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:temperature_upload/loading_provider.dart';
import 'package:temperature_upload/pages/main/pages/home/dialogs/files_dialogs.dart';
import 'package:temperature_upload/pages/main/providers/ble_provider.dart';
import 'package:temperature_upload/utils/dialogs.dart';
import 'package:temperature_upload/utils/client.dart';
import 'package:temperature_upload/utils/files.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? _lastBackPressed;
  bool _canPop = false;

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

  Future<void> selectDevice() async {
    final ble = context.read<BLEProvider>();
    final loading = context.read<LoadingProvider>();

    loading.startLoading();
    final loaded = await ble.loadSavedDevices();
    
    try {
      if (loaded.length == 1) {
        final id = loaded[0]['id']!;
        await ble.connect(BluetoothDevice.fromId(id));
        loading.stopLoading();
        if (mounted) { Navigator.pushNamed(context, '/home/write-journal'); }
      } else if (loaded.length > 1) {
        final id = await showRegisteredDevices(loaded);
        if (id != null) {
          await ble.connect(BluetoothDevice.fromId(id));
          loading.stopLoading();
          if (mounted) { Navigator.pushNamed(context, '/home/write-journal'); }
        }
      } else {
        loading.stopLoading();
        if (mounted) { await showAlertDialog(context, "등록된 기기가 없습니다."); }      
      }
    } catch (_) {
      loading.stopLoading();
      if (mounted) { showAlertDialog(context, "기기 선택 중 오류가 발생하였습니다."); }
    }
  }

  Future<String?> showRegisteredDevices(List<Map<String, String>> loaded) async {
    return showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text("기기 선택"),
        content: ListView.builder(
          shrinkWrap: true,
          itemCount: loaded.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(loaded[index]['alias']!),
              subtitle: Text(loaded[index]['id']!),
              onTap: () => Navigator.of(ctx).pop(loaded[index]['id']),
            );
          }
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text("닫기"))
        ],
      )
    );
  }

  Future<void> showSavedLogs() async {
    final files = await listAppExternalFiles();
    if (mounted) {
      await showDialog(context: context, builder: (_) => FilesDialogs(fileList: files));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now; 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("뒤로 가기 버튼을 한 번 더 누르면 종료됩니다.")),
          );

          setState(() {
            _canPop = true;
          });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _canPop = false;
                _lastBackPressed = null;
              });
            }
          });
        } else {
          setState(() {
            _canPop = true;
          });
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/home/device-register'),
                child: Text("기기 등록"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: selectDevice, child: Text("일지 작성")),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: showSavedLogs, child: Text("일지 목록")),
              const SizedBox(height: 16,),
              ElevatedButton(onPressed: logout, child: const Text('로그아웃'))
            ],
          ),
        ),
      ),
    );
  }
}
