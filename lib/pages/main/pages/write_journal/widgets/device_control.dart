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
import 'package:temperature_upload/utils/secure_category_storage.dart';
import 'package:temperature_upload/utils/time.dart';

class DeviceControl extends StatefulWidget {
  const DeviceControl({super.key});

  @override
  State<StatefulWidget> createState() => _DeviceControlState();
}

class _DeviceControlState extends State<DeviceControl> {
  MeasureOption _selectedOption = MeasureOption.manual;
  MeasureDetailOption _detailOption = MeasureDetailOption.one;
  late final TextEditingController _startThresholdController;
  late final TextEditingController _endThresholdController;
  late final TextEditingController _timeStartController;
  late final TextEditingController _timeEndController;
  final storage = SecureCategoryStorage();

  // --- 로직 제어 상태 ---
  bool _taskStarted = false;
  bool _isTimedMeasurementRunning = false;
  Timer? _autoStopTimer;
  StreamSubscription? _tempSubscription;

  // --- 새로운 기능 ---
  Duration _recordingInterval = const Duration(seconds: 1);
  final List<Map<String, dynamic>> _intervalOptions = [
    {'label': '1초', 'duration': const Duration(seconds: 1)},
    {'label': '5초', 'duration': const Duration(seconds: 5)},
    {'label': '10초', 'duration': const Duration(seconds: 10)},
    {'label': '30초', 'duration': const Duration(seconds: 30)},
    {'label': '1분', 'duration': const Duration(minutes: 1)},
    {'label': '5분', 'duration': const Duration(minutes: 5)},
  ];

  Future<void> _requestPermissions() async {
    if (!await Permission.storage.request().isGranted) {
      if (mounted) {
        showAlertDialog(context, "저장소 권한을 허가해주세요.").then((_) => Navigator.of(context).pop());
      }
    }
  }

  void _cancelAllTasks() {
    _autoStopTimer?.cancel();
    _tempSubscription?.cancel();
    _autoStopTimer = null;
    _tempSubscription = null;
  }

  /// 메인 버튼 동작을 모드에 따라 분기
  Future<void> startOrStopRecording() async {
    // 진행 중인 작업이 있으면 중지
    if (_taskStarted || _isTimedMeasurementRunning) {
      await _stopAndSubmit();
      return;
    }

    // 모드에 따라 새로운 작업 시작
    switch (_selectedOption) {
      case MeasureOption.manual:
        _manualStart();
        break;
      case MeasureOption.auto:
        // 측정 시작 전에 값들을 기기에 저장
        await saveValues();

        if (areInputsValid()) {
          switch (_detailOption) {
            case MeasureDetailOption.one:
            case MeasureDetailOption.four:
              _autoStartWithCondition();
              break;
            case MeasureDetailOption.two:
            case MeasureDetailOption.three:
              _autoStartWithTimer();
              break;
          }
        } else {
          if (mounted) { await showAlertDialog(context, "모든 항목을 채워주세요."); }
        }
        break;
    }
  }

  /// 모드 1: 수동 시작
  void _manualStart() {
    context.read<BLEProvider>().startRecording(_recordingInterval);
    setState(() => _taskStarted = true);
  }

  /// 설비-1, 설비-4
  void _autoStartWithCondition() {
    final startTemp = double.tryParse(_startThresholdController.text);
    final maxTime = int.tryParse(_timeEndController.text);

    if (startTemp == null || maxTime == null || maxTime <= 0) {
      showAlertDialog(context, "시작 온도와 최대 시간을 올바르게 입력해주세요.");
      return;
    }

    setState(() => _taskStarted = true);

    _tempSubscription = context.read<BLEProvider>().temperatureStream.listen((currentTemp) {
      if (currentTemp != null && currentTemp >= startTemp) {
        _tempSubscription?.cancel();

        if (mounted) { context.read<BLEProvider>().startRecording(_recordingInterval); }

        final duration = _detailOption == MeasureDetailOption.four
            ? Duration(minutes: maxTime)
            : Duration(seconds: maxTime);

        _autoStopTimer = Timer(duration, () {
          if (mounted && _taskStarted) {
            _stopAndSubmit();
          }
        });
      }
    });
  }

  /// 설비-2, 설비-3
  Future<void> _autoStartWithTimer() async {
    final timeValue = int.tryParse(_timeStartController.text);
    final tempValue = double.tryParse(_startThresholdController.text);
    if (timeValue == null || timeValue <= 0) {
      showAlertDialog(context, "측정 시간을 올바르게 입력해주세요.");
      return;
    }

    setState(() => _isTimedMeasurementRunning = true);

    _tempSubscription = context.read<BLEProvider>().temperatureStream.listen((currentTemp) {
      if (currentTemp != null && tempValue != null && currentTemp >= tempValue) {
        _tempSubscription?.cancel();

        if (mounted) { context.read<BLEProvider>().startRecording(_recordingInterval); }

        final duration = _detailOption == MeasureDetailOption.two
            ? Duration(seconds: timeValue)
            : Duration(minutes: timeValue);

        Timer(duration, () {
          if (mounted && _isTimedMeasurementRunning) {
            _stopAndSubmit();
          }
        });
      }
    });
  }

  /// 공통: 중지 및 제출
  Future<void> _stopAndSubmit() async {
    if (!mounted || (!_taskStarted && !_isTimedMeasurementRunning)) return;

    _cancelAllTasks();
    context.read<BLEProvider>().stopRecording();

    // 상태를 먼저 변경하여 UI가 즉시 반응하도록 함
    setState(() {
      _taskStarted = false;
      _isTimedMeasurementRunning = false;
    });

    await submit();
  }

  /// 공통: 서버 제출 로직
  Future<void> submit() async {
    final lp = context.read<LoadingProvider>();
    try {
      lp.startLoading();
      final data = context.read<BLEProvider>().recordedTemperatures.map((rec) => {
        'time': dateTimeToString(rec['time']),
        'value': rec['value'],
      }).toList();

      final Map<String, dynamic> params = {};
      params['detailOption'] = _detailOption.name;
      if (_selectedOption == MeasureOption.auto) {
        params['startTemp'] = _startThresholdController.text;
        params['startTime'] = _timeStartController.text;

        switch(_detailOption) {
          case MeasureDetailOption.one:
            params['endTemp'] = _endThresholdController.text;
            params['endTime'] = _timeEndController.text;
            break;

          case MeasureDetailOption.two:
            params['endTemp'] = _endThresholdController.text;
            break;

          case MeasureDetailOption.three:
            break;

          case MeasureDetailOption.four:
            params['endTime'] = _timeEndController.text;
        }
      }

      await Client.post('/api/temperature', body: {
        'type': _selectedOption == MeasureOption.auto ? 'auto' : 'manual',
        'data': data,
        'name': await context.read<BLEProvider>().getCurrentDeviceAlias(),
        'params': params,
      });

      await saveTemperatureData(data);
      if (mounted) await showAlertDialog(context, "데이터 전송 성공");
    } catch (e) {
      if (mounted) showAlertDialog(context, "데이터 전송 실패: $e");
    } finally {
      if (mounted) lp.stopLoading();
    }
  }

  Future<void> showOptionDialog() async {
    final result = await showDialog<MeasureOption?>(
      context: context,
      builder: (_) => SelectMeasureModeDialog(startOption: _selectedOption,)
    );

    if (result != null) {
      setState(() => _selectedOption = result);
      if (result == MeasureOption.auto) {
        await loadSavedValues();
      }
    }
  }

  String getAutoMenuSelectionNames(MeasureDetailOption option) {
    switch (option) {
      case MeasureDetailOption.one:
        return "설비-1번";
      case MeasureDetailOption.two:
        return "설비-2번";
      case MeasureDetailOption.three:
        return "설비-3번";
      case MeasureDetailOption.four:
        return "설비-4번";
    }
  }

  bool areInputsValid() {
    isNotEmpty(TextEditingController c) => c.text.isNotEmpty;

    switch (_detailOption) {
      case MeasureDetailOption.one:
        return isNotEmpty(_startThresholdController) &&
            isNotEmpty(_endThresholdController) &&
            isNotEmpty(_timeStartController) &&
            isNotEmpty(_timeEndController);

      case MeasureDetailOption.two:
        return isNotEmpty(_startThresholdController) &&
            isNotEmpty(_endThresholdController) &&
            isNotEmpty(_timeStartController);

      case MeasureDetailOption.three:
        return isNotEmpty(_startThresholdController) &&
            isNotEmpty(_timeStartController);

      case MeasureDetailOption.four:
        return isNotEmpty(_startThresholdController) &&
            isNotEmpty(_timeStartController) &&
            isNotEmpty(_timeEndController);
    }
  }

  Future saveValues() async {
    await storage.saveCategory(getAutoMenuSelectionNames(_detailOption), {
      'startThreshold': _startThresholdController.text,
      'endThreshold': _endThresholdController.text,
      'timeStart': _timeStartController.text,
      'timeEnd': _timeEndController.text,
    });
  }

  Future loadSavedValues() async {
    final loaded = await storage.loadCategory(getAutoMenuSelectionNames(_detailOption));
    _startThresholdController.text = loaded["startThreshold"] ?? '';
    _endThresholdController.text = loaded["endThreshold"] ?? '';
    _timeStartController.text = loaded["timeStart"] ?? '';
    _timeEndController.text = loaded["timeEnd"] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _startThresholdController = TextEditingController();
    _endThresholdController = TextEditingController();
    _timeStartController = TextEditingController();
    _timeEndController = TextEditingController();

    _requestPermissions();
  }

  @override
  void dispose() {
    _startThresholdController.dispose();
    _endThresholdController.dispose();
    _timeStartController.dispose();
    _timeEndController.dispose();
    _cancelAllTasks();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temperature = context.watch<BLEProvider>().temperature;
    final bool isBusy = _taskStarted || _isTimedMeasurementRunning;

    String buttonText = "시작";
    if (isBusy) {
      buttonText = "중단";
    } else if (_selectedOption == MeasureOption.auto && (_detailOption == MeasureDetailOption.two || _detailOption == MeasureDetailOption.three)) {
      buttonText = "측정";
    }

    return Column(
      children: [
        Text(
          "${isBusy ? "온도 측정 진행 중" : "현재 온도"}: ${temperature ?? 0}℃",
          style: TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 30,),

        if (_selectedOption == MeasureOption.auto) ...[
          Text(
            "CCP 한계기준 설정",
            style: TextStyle(fontSize: 16),
          ),
          Text(
            "1. 측정(가열)온도 설정",
            style: TextStyle(fontSize: 20),
          ),
          TempSelection(
            startThresholdController: _startThresholdController,
            endThresholdController: _endThresholdController,
            taskStarted: isBusy,
            measureDetailOption: _detailOption,
          ),
          Text(
            "2. 측정(가열)시간 설정",
            style: TextStyle(fontSize: 20),
          ),
          TimeSelection(
              timeStartController: _timeStartController,
              timeEndController: _timeEndController,
              taskStarted: isBusy,
              measureDetailOption: _detailOption
          ),
          AutoMenuSelection(
            value: _detailOption,
            items: MeasureDetailOption.values,
            onChanged: isBusy ? null : (v) async {
              if (v != null) {
                setState(() => _detailOption = v as MeasureDetailOption);
              }
              await loadSavedValues();
            },
            label: getAutoMenuSelectionNames,
          ),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("기록 간격: "),
            DropdownButton<Duration>(
              value: _recordingInterval,
              onChanged: isBusy ? null : (Duration? newValue) {
                if (newValue != null) {
                  setState(() {
                    _recordingInterval = newValue;
                  });
                }
              },
              items: _intervalOptions.map<DropdownMenuItem<Duration>>((Map<String, dynamic> option) {
                return DropdownMenuItem<Duration>(
                  value: option['duration'],
                  child: Text(option['label']),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 8,),
        ElevatedButton(
          onPressed: isBusy ? null : showOptionDialog,
          child: const Text('측정 모드 선택'),
        ),
        const SizedBox(height: 8,),
        ElevatedButton(
            onPressed: startOrStopRecording,
            child: Text(buttonText)
        ),
      ],
    );
  }
}
