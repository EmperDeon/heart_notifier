import 'package:flutter/material.dart';

class Workout {
  final IconData icon;
  final bool repeatable;
  final List<Stage> stages;

  Workout(this.icon, this.repeatable, this.stages);

  (Stage, int, int) atTime(int seconds) {
    if (!repeatable && seconds > stages.first.length) return (stages.first, 0, 0);

    final List<(Stage, int)> stageStartAt = [];
    final full = stages.fold(0, (v, stage) {
      stageStartAt.add((stage, v));
      return v + stage.length;
    });
    final cycles = seconds ~/ full;
    final mod = seconds.remainder(full);

    for (final (stage, startAt) in stageStartAt) {
      if (mod >= startAt && mod <= (startAt + stage.length)) {
        return (stage, cycles * full + startAt, cycles * full + startAt + stage.length);
      }
    }

    return (stages.first, 0, 0);
  }
}

class Stage {
  final String label;
  final int length;
  final Color color;

  Stage(this.label, this.length, this.color);
}

final workouts = [
  Workout(Icons.directions_bike, true, [
    Stage('Rest', 150, Colors.blueAccent.shade700),
    Stage('Go', 150, Colors.greenAccent.shade700),
  ]),
  Workout(Icons.ac_unit, false, [
    Stage('Cooldown', 240, Colors.blueAccent.shade700),
  ]),
];
