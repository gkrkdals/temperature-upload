import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

class FilesDialogs extends StatelessWidget {
  const FilesDialogs({super.key, required this.fileList});

  final List<FileSystemEntity> fileList;

  String convertDateFormat(String dateTimeString) {
    String year = dateTimeString.substring(0, 4);
    String month = dateTimeString.substring(4, 6);
    String day = dateTimeString.substring(6, 8);
    String hour = dateTimeString.substring(8, 10);
    String minute = dateTimeString.substring(10, 12);
    String second = dateTimeString.substring(12);

    return '$year-$month-$day $hour:$minute:$second';
  }

  List<String> _parseFilenameTimeRange(String filename) {
    final nameWithoutExt = filename.replaceAll('.csv', '');
    final tmp = nameWithoutExt.split(' ~ ');

    List<String> retData = <String> [];
    retData.add(convertDateFormat(tmp[0]));

    if (tmp.length > 1) {
      retData.add(convertDateFormat(tmp[1]));
    }

    return retData;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("일지 목록"),
      content: ListView.builder(
        shrinkWrap: true,
        itemCount: fileList.length,
        itemBuilder: (context, index) {
          final file = fileList[index];
          final path = file.path;
          final filename = p.basename(path);
          final times = _parseFilenameTimeRange(filename);
          final start = times[0], end = times.length <= 1 ? '' : times[1];
          
          return Card(
            elevation: 1,
            child: ListTile(
              onTap: () async {
                final result = await OpenFilex.open(path);
                if (result.type != ResultType.done) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("파일을 열 수 없습니다.")),
                    
                  );
                }
              },
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('시작: $start', style: TextStyle(fontSize: 13),),
                  if (end.isNotEmpty) Text('종료: $end', style: TextStyle(fontSize: 13),)
                ],
              ),
            ),
          );
        }
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("닫기"))
      ],
    );
  }
}