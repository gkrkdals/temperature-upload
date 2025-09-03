import 'package:flutter/material.dart';

class AliasDialog extends StatefulWidget {
  const AliasDialog({super.key});

  @override
  State<StatefulWidget> createState() => _AliasDialogState();
}

class _AliasDialogState extends State<AliasDialog> {

  TextEditingController? _aliasController;

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController();
  }

  @override
  void dispose() {
    _aliasController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("별칭 입력"),
      content: TextField(
        controller: _aliasController,
        decoration: InputDecoration(
          hintText: "별칭"
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), 
          child: Text("닫기"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_aliasController!.text),
          child: Text("등록")
        )
      ],
    );
  }
}