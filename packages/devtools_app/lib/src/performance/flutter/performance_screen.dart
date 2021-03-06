// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:vm_service/vm_service.dart';

import '../../flutter/auto_dispose_mixin.dart';
import '../../flutter/common_widgets.dart';
import '../../flutter/controllers.dart';
import '../../flutter/octicons.dart';
import '../../flutter/screen.dart';
import '../../performance/performance_controller.dart';
import '../../profiler/cpu_profile_model.dart';
import '../../profiler/cpu_profiler_controller.dart';
import '../../profiler/flutter/cpu_profiler.dart';
import '../../ui/flutter/vm_flag_widgets.dart';

class PerformanceScreen extends Screen {
  const PerformanceScreen() : super();

  @visibleForTesting
  static const clearButtonKey = Key('Clear Button');
  @visibleForTesting
  static const recordButtonKey = Key('Record Button');
  @visibleForTesting
  static const stopRecordingButtonKey = Key('Stop Recording Button');
  @visibleForTesting
  static const recordingInstructionsKey = Key('Recording Instructions');
  @visibleForTesting
  static const recordingStatusKey = Key('Recording Status');

  @override
  Widget build(BuildContext context) => PerformanceScreenBody();

  @override
  Widget buildTab(BuildContext context) {
    return const Tab(
      text: 'Performance',
      icon: Icon(Octicons.dashboard),
    );
  }
}

class PerformanceScreenBody extends StatefulWidget {
  @override
  _PerformanceScreenBodyState createState() => _PerformanceScreenBodyState();
}

class _PerformanceScreenBodyState extends State<PerformanceScreenBody>
    with AutoDisposeMixin {
  PerformanceController controller;
  bool recording = false;
  bool processing = false;
  double processingProgress = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = Controllers.of(context).performance;
    if (newController == controller) return;
    controller = newController;

    cancel();
    addAutoDisposeListener(controller.recordingNotifier, () {
      setState(() {
        recording = controller.recordingNotifier.value;
      });
    });
    addAutoDisposeListener(controller.cpuProfilerController.processingNotifier,
        () {
      setState(() {
        processing = controller.cpuProfilerController.processingNotifier.value;
      });
    });
    addAutoDisposeListener(
        controller.cpuProfilerController.transformer.progressNotifier, () {
      setState(() {
        processingProgress =
            controller.cpuProfilerController.transformer.progressNotifier.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Flag>(
      valueListenable: controller.cpuProfilerController.profilerFlagNotifier,
      builder: (context, profilerFlag, _) {
        return profilerFlag.valueAsString == 'true'
            ? _buildPerformanceBody(controller)
            : CpuProfilerDisabled(controller.cpuProfilerController);
      },
    );
  }

  Widget _buildPerformanceBody(PerformanceController controller) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStateControls(controller),
            ProfileGranularityDropdown(),
          ],
        ),
        Expanded(
          child: ValueListenableBuilder<CpuProfileData>(
            valueListenable: controller.cpuProfilerController.dataNotifier,
            builder: (context, cpuProfileData, _) {
              if (cpuProfileData ==
                      CpuProfilerController.baseStateCpuProfileData ||
                  cpuProfileData == null) {
                return _buildRecordingInfo();
              }
              return CpuProfiler(
                data: cpuProfileData,
                controller: controller.cpuProfilerController,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStateControls(PerformanceController controller) {
    const double minIncludeTextWidth = 600;
    return Row(
      children: [
        recordButton(
          key: PerformanceScreen.recordButtonKey,
          recording: recording,
          minIncludeTextWidth: minIncludeTextWidth,
          onPressed: controller.startRecording,
        ),
        stopRecordingButton(
          key: PerformanceScreen.stopRecordingButtonKey,
          recording: recording,
          minIncludeTextWidth: minIncludeTextWidth,
          onPressed: controller.stopRecording,
        ),
        const SizedBox(width: 8.0),
        clearButton(
          key: PerformanceScreen.clearButtonKey,
          minIncludeTextWidth: minIncludeTextWidth,
          onPressed: recording ? null : controller.clear,
        ),
      ],
    );
  }

  Widget _buildRecordingInfo() {
    return recordingInfo(
      instructionsKey: PerformanceScreen.recordingInstructionsKey,
      recordingStatusKey: PerformanceScreen.recordingStatusKey,
      recording: recording,
      processing: processing,
      progressValue: processingProgress,
      recordedObject: 'CPU samples',
    );
  }
}
