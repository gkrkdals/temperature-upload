import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:temperature_upload/loading_provider.dart';
import 'package:temperature_upload/models/enum/measure_option.dart';
import 'package:temperature_upload/pages/main/pages/write_journal/dialogs/select_measure_mode_dialog.dart';
import 'package:temperature_upload/pages/main/pages/write_journal/widgets/auto_menu_selection.dart';
import 'package:temperature_upload/pages/main/pages/write_journal/widgets/temp_selection.dart';
import 'package:temperature_upload/pages/main/pages/write_journal/widgets/time_selection.dart';
import 'package:temperature_upload/pages/main/providers/ble_provider.dart';
import 'package:temperature_upload/utils/client.dart';
import 'package:temperature_upload/utils/dialogs.dart';
import 'package:temperature_upload/utils/files.dart';
import 'package:temperature_upload/utils/time.dart';

class DeviceControl extends StatefulWidget {
  const DeviceControl({super.key});

  @override
  State<StatefulWidget> createState() => _DeviceControlState();
}

class _DeviceControlState extends State<DeviceControl> {
  bool _taskStarted = false;
  MeasureOption? _selectedOption = MeasureOption.manual;
  MeasureDetailOption _detailOption = MeasureDetailOption.one;
  TextEditingController? _startThresholdController, _endThresholdController;
  TextEditingController? _timeStartController, _timeEndController;

  bool _isTimedMeasurementRunning = false;

  Future<void> startOrStopRecording() async {
    // 🔽 자동 모드이면서, 옵션이 2번 또는 3번일 경우 새로운 로직 실행
    if (_selectedOption == MeasureOption.auto &&
        (_detailOption == MeasureDetailOption.two || _detailOption == MeasureDetailOption.three)) {
      await _startTimedMeasurement();
    }
    // 🔽 그 외의 경우(수동, 자동 1/4번)는 기존 로직 실행
    else {
      await _manualStartStop();
    }
  }

  // ✨ 기존 시작/종료 로직을 별도 함수로 분리
  Future<void> _manualStartStop() async {
    if (_selectedOption == MeasureOption.manual) {
      if (_taskStarted) {
        final lp = context.read<LoadingProvider>();
        context.read<BLEProvider>().stopRecording();

        lp.startLoading();
        await submit();
        lp.stopLoading();

        setState(() { _taskStarted = false; });
      } else {
        context.read<BLEProvider>().startRecording();
        setState(() {
          _taskStarted = true;
        });
      }
    } else {
      if (!_taskStarted) {
        context.read<BLEProvider>().startRecording();
        setState(() => _taskStarted = true);
      } else {
        final lp = context.read<LoadingProvider>();
        context.read<BLEProvider>().stopRecording();

        lp.startLoading();
        await submit();
        lp.stopLoading();

        setState(() => _taskStarted = false);
      }
    }
  }

  // ✨ 옵션 2, 3번을 위한 새로운 시간 기반 측정 함수
  Future<void> _startTimedMeasurement() async {
    final timeValue = int.tryParse(_timeStartController?.text ?? '');
    if (timeValue == null || timeValue <= 0) {
      showAlertDialog(context, "측정 시간을 올바르게 입력해주세요.");
      return;
    }

    // 측정 시작, 버튼 비활성화
    setState(() => _isTimedMeasurementRunning = true);
    context.read<BLEProvider>().startRecording();

    // 옵션에 따라 시간 단위(초/분)를 결정
    final duration = _detailOption == MeasureDetailOption.two
        ? Duration(seconds: timeValue)
        : Duration(minutes: timeValue);

    // 설정된 시간 후에 자동으로 종료 및 제출 실행
    Timer(duration, () async {
      context.read<BLEProvider>().stopRecording();
      await submit();
      // 측정이 끝나면 버튼 다시 활성화
      if (mounted) {
        setState(() => _isTimedMeasurementRunning = false);
      }
    });
  }

  Future<void> submit() async {
    try {
      context.read<LoadingProvider>().startLoading();
      final data = context.read<BLEProvider>().recordedTemperatures.map((rec) => {
        'time': dateTimeToString(rec['time']),
        'value': rec['value'],
      }).toList();

      // 🔽 옵션에 따라 파라미터를 담을 Map 생성
      final Map<String, dynamic> params = {};

      if (_selectedOption == MeasureOption.auto) {
        if (_detailOption == MeasureDetailOption.two || _detailOption == MeasureDetailOption.three) {
          params['startTemp'] = _startThresholdController?.text;
        } else {
          params['startTemp'] = _startThresholdController?.text;
          params['endTemp'] = _endThresholdController?.text;
        }

        if (_detailOption == MeasureDetailOption.one || _detailOption == MeasureDetailOption.four) {
          params['startTime'] = _timeStartController?.text;
          params['endTime'] = _timeEndController?.text;
        } else {
          params['startTime'] = _timeStartController?.text;
        }
      }

      await Client.post('/api/temperature', body: {
        'type': _selectedOption == MeasureOption.auto ? 'auto' : 'manual',
        'data': data,
        'name': await context.read<BLEProvider>().getCurrentDeviceAlias(),
        'params': params, // 👈 동적으로 구성된 파라미터 추가
      });

      await saveTemperatureData(data);
      if (mounted) {
        context.read<LoadingProvider>().stopLoading();
        await showAlertDialog(context, "데이터 전송 성공");
      }
    } catch (e) {
      if (mounted) {
        context.read<LoadingProvider>().stopLoading();
        showAlertDialog(context, "데이터 전송 실패: $e");
      }
    }
  }

  Future<void> showOptionDialog() async {
    final result = await showDialog<MeasureOption?>(
      context: context,
      builder: (_) => SelectMeasureModeDialog(startOption: _selectedOption)
    );

    if (result != null) {
      setState(() => _selectedOption = result);
    }
  }

  Future<bool> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    } else {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _startThresholdController = TextEditingController();
    _endThresholdController = TextEditingController();
    requestStoragePermission().then((v) {
      if (!v && mounted) {
        showAlertDialog(context, "저장소 권한을 허가해주세요.");
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _startThresholdController?.dispose();
    _endThresholdController?.dispose();
    _timeStartController?.dispose();
    _timeEndController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temperature = context.watch<BLEProvider>().temperature;

    String buttonText = _taskStarted ? "중단" : "시작";
    if (_selectedOption == MeasureOption.auto &&
        (_detailOption == MeasureDetailOption.two || _detailOption == MeasureDetailOption.three)) {
      buttonText = "측정";
    }

    return Column(
      children: [
        Text("${_taskStarted ? "온도 측정 진행 중" : "현재 온도"}: ${temperature ?? 0}"),
        SizedBox(height: 16,),
        if (_selectedOption == MeasureOption.auto)
          TempSelection(
            startThresholdController: _startThresholdController,
            endThresholdController: _endThresholdController,
            taskStarted: _taskStarted,
            measureDetailOption: _detailOption,
          ),
        if (_selectedOption == MeasureOption.auto)
          TimeSelection(
            timeStartController: _timeStartController,
            timeEndController: _timeEndController,
            taskStarted: _taskStarted,
            measureDetailOption: _detailOption
          ),
        if (_selectedOption == MeasureOption.auto)
          AutoMenuSelection(
            value: _detailOption,
            items: MeasureDetailOption.values,
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _detailOption = v;
                });
              }
            },
            label: toNamed
          ),
        ElevatedButton(
          onPressed: _taskStarted || _isTimedMeasurementRunning ? null : showOptionDialog,
          child: Text('측정 모드 선택'),
        ),
        SizedBox(height: 16,),
        ElevatedButton(
          onPressed: _isTimedMeasurementRunning ? null : startOrStopRecording,
          child: Text(buttonText)
        ),
      ],
    );
  }
}