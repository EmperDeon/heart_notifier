import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:heart_notifier/providers/main.dart';
import 'package:heart_notifier/providers/workouts.dart';
import 'package:heart_notifier/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Zone {
  final String label;
  final int min;
  final int max;
  final Color color;

  const Zone(this.label, this.min, this.max, this.color);

  static Color getColor(int ppm) {
    for (final zone in ppmZones) {
      if (ppm > zone.min && zone.max >= ppm) return zone.color;
    }

    return ppmZones.first.color;
  }
}

final ppmZones = [
  const Zone('Rest', 0, 100, Color(0xFF4B5F9B)),
  Zone('Warm up', 100, 120, Colors.blueAccent.shade700),
  Zone('Weight control', 120, 140, Colors.greenAccent.shade700),
  Zone('Cardio', 140, 160, Colors.yellowAccent.shade700),
  Zone('Anaerobic', 160, 180, Colors.orangeAccent.shade700),
  Zone('Maximum', 180, 250, Colors.redAccent.shade700),
];

class ConnectedManager {
  late ProviderDevice device;

  final PropertyValueNotifier<int> lastPpm = PropertyValueNotifier(0);
  late final Command<int, int> notifyAboveBeat = Command.createSync((v) => v, initialValue: 200);

  // Graph
  final PropertyValueNotifier<List<Data>> graphPpm = PropertyValueNotifier([Data(90, 0)]);
  List<int> graphAllPpm = [];
  List<PlotBand> graphBands = [];

  // Timer
  int startedAt = 0;
  int startedAtTick = 0;
  int pausedTicks = 0;
  final PropertyValueNotifier<Workout?> currentWorkout = PropertyValueNotifier(null);

  late final Command<Workout?, void> updateCurrentWorkout = Command.createSyncNoResult(_updateCurrentWorkout);
  late final Command<void, bool> timerPaused = Command.createSyncNoParam(_timerPaused, initialValue: false);

  ConnectedManager();

  Future load(ProviderDevice dev) async {
    device = dev;
    await device.connect();

    device.ppmStream().listen((newPpm) => _ppmUpdated(newPpm));
  }

  _ppmUpdated(int newPpm) {
    lastPpm.value = newPpm;
    lastPpm.notify();

    _timerUpdate();
    _graphUpdate(newPpm);
    _notifUpdate(newPpm);
  }

  void _notifUpdate(int newPpm) async {
    FlutterLocalNotificationsPlugin notif = FlutterLocalNotificationsPlugin();
    if (notifyAboveBeat.value > 50 && newPpm > notifyAboveBeat.value) {
      const android = AndroidNotificationDetails(
        'heart_notifier',
        'heart_notifier',
        channelDescription: 'heart_notifier',
        importance: Importance.high,
        priority: Priority.high,
      );
      const platform = NotificationDetails(android: android);
      await notif.show(
        1,
        'HHR High !',
        '$newPpm',
        platform,
      );
    } else {
      await notif.cancelAll();
    }
  }

  void _graphUpdate(int newPpm) {
    graphAllPpm.add(newPpm);

    graphPpm.value = graphAllPpm.mapIndexed((v, i) => Data(v, i)).toList();
  }

  //
  // Timers
  //

  bool isStarted() => currentWorkout.value != null;

  _updateCurrentWorkout(Workout? newValue) {
    if (isStarted() && graphBands.isNotEmpty) {
      final last = graphBands.last;

      graphBands.last = PlotBand(
        opacity: last.opacity,
        color: last.color,
        start: last.start,
        end: graphPpm.value.length,
      );
    }

    startedAt = 0;
    pausedTicks = 0;
    startedAtTick = graphAllPpm.length;
    timerPaused.value = false;
    currentWorkout.value = newValue;
  }

  String elapsedStr() {
    if (!isStarted()) return '0:00:00';

    return Duration(seconds: startedAt).toSmallString();
  }

  void _timerUpdate() {
    if (isStarted() && timerPaused.value) {
      pausedTicks += 1;
    }

    if (isStarted() && !timerPaused.value) {
      startedAt += 1;

      final (stage, start, end) = currentWorkout.value!.atTime(startedAt);
      final offset = startedAtTick + pausedTicks;

      if (end == 0) {
        updateCurrentWorkout.execute(null);
      } else if (graphBands.isEmpty || graphBands.last.end != (offset + end)) {
        graphBands.add(PlotBand(
          opacity: 0.2,
          color: stage.color,
          start: offset + start,
          end: offset + end,
        ));
      }
    }
  }

  Stage currentStage() {
    if (!isStarted() || timerPaused.value) return Stage('Pause', 0, const Color(0xFF4B5F9B));

    return currentWorkout.value!.atTime(startedAt).$1;
  }

  bool _timerPaused() {
    if (!isStarted()) return false;
    lastPpm.notify();

    if (timerPaused.value) {
      final (stage, _, end) = currentWorkout.value!.atTime(startedAt);
      final offset = startedAtTick + pausedTicks;

      graphBands.add(PlotBand(
        opacity: 0.2,
        color: stage.color,
        start: graphPpm.value.length,
        end: offset + end,
      ));
    } else if (!timerPaused.value && graphBands.isNotEmpty) {
      final last = graphBands.last;

      graphBands.last = PlotBand(
        opacity: last.opacity,
        color: last.color,
        start: last.start,
        end: graphPpm.value.length,
      );
    }

    return !timerPaused.value;
  }
}

class Data {
  int v;
  int i;

  Data(this.v, this.i);
}
