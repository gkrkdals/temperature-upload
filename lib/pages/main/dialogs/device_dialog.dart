import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:temperature_upload/pages/main/providers/ble_provider.dart';

class DeviceDialog extends StatelessWidget {
  final Function(BluetoothDevice) onDeviceTap;

  const DeviceDialog({
    super.key,
    required this.onDeviceTap,
  });

  @override
  Widget build(BuildContext context) {
    final results = context.watch<BLEProvider>().scanResults;

    return AlertDialog(
      title: Text("기기 목록"),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];

            return ListTile(
              title: Text(result.device.advName.isNotEmpty ? result.device.advName : '(알 수 없음)'),
              subtitle: Text(result.device.remoteId.str),
              onTap: () => onDeviceTap(result.device),
            );
          }
        )
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<BLEProvider>().stopScan();
            Navigator.of(context).pop();
          },
          child: Text("닫기"),
        )
      ],
    );
  }
}