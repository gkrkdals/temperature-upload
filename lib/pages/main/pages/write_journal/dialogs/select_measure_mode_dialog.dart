import 'package:flutter/material.dart';
import 'package:temperature_upload/models/enum/measure_option.dart';

class SelectMeasureModeDialog extends StatefulWidget {
  const SelectMeasureModeDialog({
    super.key,
    required this.startOption,
  });

  final MeasureOption? startOption;

  @override
  State<StatefulWidget> createState() => _SelectMeasureModeDialogState();
}

class _SelectMeasureModeDialogState extends State<SelectMeasureModeDialog> {

  MeasureOption? _opt;

  @override
  void initState() {
    super.initState();
    _opt = widget.startOption;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("측정 모드 선택"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text("수동"),
            leading: Radio<MeasureOption>(
              value: MeasureOption.manual,
              groupValue: _opt,
              onChanged: (value) => setState(() => _opt = value),
            ),
            onTap: () => setState(() => _opt = MeasureOption.manual),
          ),
          ListTile(
            title: Text("자동"),
            leading: Radio<MeasureOption>(
              value: MeasureOption.auto,
              groupValue: _opt,
              onChanged: (value) => setState(() => _opt = value),
            ),
            onTap: () => setState(() => _opt = MeasureOption.auto),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(_opt), child: Text("닫기")),
      ],
    );
  }
}