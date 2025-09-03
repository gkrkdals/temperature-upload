import 'package:flutter/material.dart';

Future showAlertDialog(BuildContext context, String content, [List<Widget>? actions]) async {
  showDialog(
    context: context, 
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text(content),
        actions: actions ?? [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("닫기"))
        ],
      );
    }
  );
}