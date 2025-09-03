import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveTemperatureData(List<Map<String, dynamic>> data) async {

  final downloadsDir = await getExternalStorageDirectory();

  String name;
  if (data.isEmpty) {
    name = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
  } else if (data.length == 1) {
    final parsed = DateFormat('yyyy-MM-dd HH:mm:ss').parse(data.first['time']);
    name = DateFormat('yyyyMMddHHmmss').format(parsed);
  } else {
    final parsed1 = DateFormat('yyyy-MM-dd HH:mm:ss').parse(data.first['time']);
    final parsed2 = DateFormat('yyyy-MM-dd HH:mm:ss').parse(data.last['time']);
    
    final formatted1 = DateFormat('yyyyMMddHHmmss').format(parsed1);
    final formatted2 = DateFormat('yyyyMMddHHmmss').format(parsed2);

    name = '$formatted1 ~ $formatted2';
  }


  final file = File('${downloadsDir?.path}/$name.csv');
  final csv = StringBuffer();
  csv.writeln('time,temperature');
  for (final entry in data) {
    csv.writeln('${entry['time']},${entry['value']}');
  }

  await file.writeAsString(csv.toString());
}

Future<List<FileSystemEntity>> listAppExternalFiles() async {
  final dir = await getExternalStorageDirectory();
  
  if (dir == null || !await dir.exists()) {
    throw Exception('디렉토리를 찾을 수 없습니다.');
  }

  final files = dir.listSync();

  files.sort((a, b) {
    final aStat = a.statSync();
    final bStat = b.statSync();

    return bStat.modified.compareTo(aStat.modified);
  });

  return files;

}