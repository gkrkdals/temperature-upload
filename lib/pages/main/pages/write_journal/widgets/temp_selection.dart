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

  MainAxisAlignment getFirstMainAxisAlignment() {
    if (measureDetailOption == MeasureDetailOption.one || measureDetailOption == MeasureDetailOption.two) {
      return MainAxisAlignment.end;
    } else {
      return MainAxisAlignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return (
      Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              child: TextField(
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10)
                ),
                keyboardType: TextInputType.number,
                readOnly: taskStarted,
                controller: startThresholdController,
              ),
            ),
            if (measureDetailOption == MeasureDetailOption.one || measureDetailOption == MeasureDetailOption.two) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Text('℃ ~ ', style: TextStyle(fontSize: 20),),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10)
                  ),
                  keyboardType: TextInputType.number,
                  readOnly: taskStarted,
                  controller: endThresholdController,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text('℃', style: TextStyle(fontSize: 20),),
              ),
            ]
            else
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text('℃ 도달하면', style: TextStyle(fontSize: 20),),
              ),
          ],
        ),
      )
    );
  }
}