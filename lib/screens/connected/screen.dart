import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:heart_notifier/providers/workouts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'manager.dart';

class Connected extends StatelessWidget {
  Connected({Key? key}) : super(key: key);

  late final ConnectedManager _manager = GetIt.I.get<ConnectedManager>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_manager.device.name} (${_manager.device.id})'),
        actions: <Widget>[
              IconButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Battery is ${_manager.device.battery}'),
                )),
                icon: const Icon(Icons.battery_std),
              ),
              IconButton(
                onPressed: _manager.updateCurrentWorkout,
                icon: const Icon(Icons.replay),
              ),
            ] +
            workouts
                .map((workout) => ValueListenableBuilder(
                      valueListenable: _manager.currentWorkout,
                      builder: (_, current, __) => workout == current
                          ? IconButton(
                              onPressed: _manager.timerPaused,
                              icon: ValueListenableBuilder(
                                valueListenable: _manager.timerPaused,
                                builder: (_, paused, __) =>
                                    paused ? const Icon(Icons.play_arrow) : const Icon(Icons.pause),
                              ),
                            )
                          : IconButton(
                              onPressed: () => _manager.updateCurrentWorkout(workout),
                              icon: Icon(workout.icon),
                            ),
                    ))
                .toList(),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ValueListenableBuilder(
                valueListenable: _manager.lastPpm,
                builder: (_, ppm, __) => TextButton(
                    onPressed: () => showPpmDialog(context),
                    child: Text(
                      '$ppm (Limit: ${_manager.notifyAboveBeat.value})',
                      style: TextStyle(
                        fontSize: 48,
                        color: Zone.getColor(ppm),
                        fontVariations: const [FontVariation('wght', 700.0)],
                      ),
                    )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: ValueListenableBuilder(
                valueListenable: _manager.lastPpm,
                builder: (_, ppm, __) => Row(children: [
                  Text(
                    _manager.elapsedStr(),
                    style: TextStyle(
                      fontSize: 36,
                      color: _manager.currentStage().color,
                      fontVariations: const [FontVariation('wght', 700.0)],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _manager.currentStage().label,
                    style: TextStyle(
                      fontSize: 36,
                      color: _manager.currentStage().color,
                      fontVariations: const [FontVariation('wght', 700.0)],
                    ),
                    textAlign: TextAlign.end,
                  )
                ]),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _manager.graphPpm,
                builder: (_, data, __) => SfCartesianChart(
                  key: const ValueKey('default'),
                  primaryXAxis: NumericAxis(
                    decimalPlaces: 0,
                    plotBands: _manager.graphBands,
                  ),
                  primaryYAxis: NumericAxis(
                    minimum: data.fold<double>(100, (a, b) => min(a, b.v.toDouble())) - 20,
                    maximum: data.fold<double>(100, (a, b) => max(a, b.v.toDouble())) + 20,
                  ),
                  zoomPanBehavior: ZoomPanBehavior(
                    enablePinching: true,
                    enablePanning: true,
                    zoomMode: ZoomMode.x,
                  ),
                  series: <ChartSeries>[
                    // Renders line chart
                    LineSeries<Data, int>(
                      key: const ValueKey('default'),
                      animationDuration: 0.05,
                      dataSource: data,
                      xValueMapper: (Data v, _) => v.i,
                      yValueMapper: (Data v, _) => v.v,
                      pointColorMapper: (v, _) => Zone.getColor(v.v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  showPpmDialog(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (_) {
          return SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                    const ListTile(
                      title: Text('Select zone: '),
                      subtitle: Text('Notifies above selected zone'),
                    )
                  ] +
                  ppmZones
                      .map(
                        (zone) => ListTile(
                          title: Text('${zone.label} (${zone.max})', style: TextStyle(color: zone.color)),
                          onTap: () {
                            Navigator.of(context).pop();
                            _manager.notifyAboveBeat.execute(zone.max);
                          },
                        ),
                      )
                      .toList(),
            ),
          );
        });
  }
}
