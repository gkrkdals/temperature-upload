import 'package:flutter/material.dart';
import 'package:temperature_upload/models/enum/measure_option.dart';

class TimeSelection extends StatelessWidget {
  const TimeSelection({
    super.key,
    required this.timeStartController,
    required this.timeEndController,
    required this.taskStarted,
    required this.measureDetailOption
  });

  final TextEditingController? timeStartController;
  final TextEditingController? timeEndController;
  final bool taskStarted;
  final MeasureDetailOption measureDetailOption;

  String getFirstLabel() {
    if (measureDetailOption == MeasureDetailOption.one || measureDetailOption == MeasureDetailOption.four) {
      return '최소시간: ';
    } else {
      return '이상: ';
    }
  }

  String getUnit() {
    if (measureDetailOption == MeasureDetailOption.one || measureDetailOption == MeasureDetailOption.two) {
      return '초';
    } else {
      return '분';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                      suffixText: getUnit(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10)
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: taskStarted,
                    controller: timeStartController,
                  ),
                )
              ],
            )
          ),
          if (measureDetailOption == MeasureDetailOption.one || measureDetailOption == MeasureDetailOption.four) ...[
            SizedBox(width: 16,),
            Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("최대시간: "),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            suffixText: getUnit(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10)
                        ),
                        keyboardType: TextInputType.number,
                        readOnly: taskStarted,
                        controller: timeEndController,
                      ),
                    )
                  ],
                )
            ),
          ]
        ],
      ),
    );
  }
}