import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:heart_notifier/providers/main.dart';

import 'manager.dart';

class Devices extends StatefulWidget {
  const Devices({Key? key}) : super(key: key);

  @override
  DevicesState createState() => DevicesState();
}

class DevicesState extends State<Devices> with TickerProviderStateMixin {
  late final DevicesManager _manager = DevicesManager();

  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat(reverse: false);

  // Create an animation with value of type "double"
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.linear,
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _manager.refresh,
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _manager.pinnedDevices,
        builder: (_, pinnedDevices, __) => ValueListenableBuilder(
          valueListenable: _manager.refresh,
          builder: (_, devices, __) => ListView(
            children: [
                  ListTile(
                      title: Text(
                    'Pinned devices:',
                    style: text.labelLarge!.copyWith(fontVariations: [const FontVariation('wght', 600.0)]),
                  ))
                ] +
                pinnedDevices.map((v) => createTile(v, text)).toList() +
                [
                  ListTile(
                    title: Text(
                      'Scanned devices:',
                      style: text.labelLarge!.copyWith(fontVariations: [const FontVariation('wght', 600.0)]),
                    ),
                    subtitle: ValueListenableBuilder(
                      valueListenable: _manager.refresh.isExecuting,
                      builder: (_, updating, __) => Text(
                          updating ? 'Scanning devices...' : (devices.isEmpty ? 'Press refresh to start scan' : '')),
                    ),
                    trailing: ValueListenableBuilder(
                        valueListenable: _manager.refresh.errors,
                        builder: (_, errors, __) {
                          SchedulerBinding.instance.addPostFrameCallback(
                            (_) {
                              if (errors != null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $errors')));
                              }
                            },
                          );

                          return const SizedBox(height: 0.0);
                        }),
                  ),
                ] +
                devices.map((v) => createTile(v, text)).toList(),
          ),
        ),
      ),
    );
  }

  ListTile createTile(ProviderDevice dev, TextTheme text) {
    return ListTile(
      onTap: () => _manager.openDevice(dev),
      title: Text('${dev.name} (${dev.id})', style: text.labelLarge),
      trailing: ValueListenableBuilder(
          valueListenable: _manager.openDevice.isExecuting,
          builder: (_, updating, __) => updating
              ? RotationTransition(
                  turns: _animation,
                  child: const Icon(Icons.refresh),
                )
              : const SizedBox()),
    );
  }
}
