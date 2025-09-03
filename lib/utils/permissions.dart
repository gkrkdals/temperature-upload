import 'package:permission_handler/permission_handler.dart';

Future<bool> requestStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }
  return status.isGranted;
}

Future<bool> requestBluetoothPermission() async {
  var status1 = await Permission.bluetoothScan.status;
  if (!status1.isGranted) {
    status1 = await Permission.bluetoothScan.request();
  }

  var status2 = await Permission.bluetoothConnect.status;
  if (!status2.isGranted) {
    status2 = await Permission.bluetoothConnect.request();
  }

  return status1.isGranted && status2.isGranted;
}