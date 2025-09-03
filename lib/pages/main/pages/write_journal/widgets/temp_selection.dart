import 'package:flutter/material.dart';
import 'package:temperature_upload/models/enum/measure_option.dart';

class TempSelection extends StatelessWidget {
  const TempSelection({
    super.key,
    required this.startThresholdController,
    required this.endThresholdController,
    required this.taskStarted,
    required this.measureDetailOption,
  });

  final TextEditingController? startThresholdController, endThresholdController;
  final bool taskStarted;
  final MeasureDetailOption measureDetailOption;

  String getFirstLabel() {
    if (measureDetailOption == MeasureDetailOption.one || measureDetailOption == MeasureDetailOption.two) {
      return '최소온도: ';
    } else {
      return '이상: ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return (
      Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(getFirstLabel()),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        suffixText: "℃",
                        contentPadding: EdgeInsets.symmetric(horizontal: 10)
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: taskStarted,
                      controller: startThresholdController,
                    ),
                  ),
                ],
              ),
            ),
            if (measureDetailOption == MeasureDetailOption.one || measureDetailOption == MeasureDetailOption.two) ...[
              SizedBox(width: 16),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("최고온도: "),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            suffixText: "℃",
                            contentPadding: EdgeInsets.symmetric(horizontal: 10)
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: taskStarted,
                        controller: endThresholdController,
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      )
    );
  }
}