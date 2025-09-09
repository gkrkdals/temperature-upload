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

  MainAxisAlignment getFirstMainAxisAlignment() {
    if (measureDetailOption == MeasureDetailOption.one || measureDetailOption == MeasureDetailOption.four) {
      return MainAxisAlignment.end;
    } else {
      return MainAxisAlignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
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
              controller: timeStartController,
            ),
          ),
          if (measureDetailOption == MeasureDetailOption.one || measureDetailOption == MeasureDetailOption.four) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Text('~', style: TextStyle(fontSize: 20),),
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
                controller: timeEndController,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 5),
              child: Text('${getUnit()}간 가열', style: TextStyle(fontSize: 20),),
            ),
          ]
          else
            Padding(
              padding: EdgeInsets.only(left: 5),
              child: Text('${getUnit()} 이상 가열', style: TextStyle(fontSize: 20),),
            ),

          //
          // Flexible(
          //   child: Row(
          //     mainAxisAlignment: getFirstMainAxisAlignment(),
          //     children: [
          //       Text(getFirstLabel()),
          //       SizedBox(
          //         width: 70,
          //         child: TextField(
          //           decoration: InputDecoration(
          //             border: OutlineInputBorder(),
          //             suffixText: getUnit(),
          //             contentPadding: EdgeInsets.symmetric(horizontal: 10)
          //           ),
          //           keyboardType: TextInputType.number,
          //           readOnly: taskStarted,
          //           controller: timeStartController,
          //         ),
          //       )
          //     ],
          //   )
          // ),
          // if (measureDetailOption == MeasureDetailOption.one || measureDetailOption == MeasureDetailOption.four) ...[
          //   SizedBox(width: 16,),
          //   Flexible(
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.start,
          //         children: [
          //           Text("최대시간: "),
          //           SizedBox(
          //             width: 70,
          //             child: TextField(
          //               decoration: InputDecoration(
          //                   border: OutlineInputBorder(),
          //                   suffixText: getUnit(),
          //                   contentPadding: EdgeInsets.symmetric(horizontal: 10)
          //               ),
          //               keyboardType: TextInputType.number,
          //               readOnly: taskStarted,
          //               controller: timeEndController,
          //             ),
          //           )
          //         ],
          //       )
          //   ),
          // ]
        ],
      ),
    );
  }
}