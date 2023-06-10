import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:get_it/get_it.dart';
import 'package:heart_notifier/providers/main.dart';
import 'package:heart_notifier/utils.dart';

import 'connected/manager.dart';
import 'connected/screen.dart';

class DevicesManager {
  late final Command<void, List<ProviderDevice>> refresh = Command.createAsyncNoParam(_refresh, initialValue: []);
  late final Command<ProviderDevice, void> openDevice = Command.createAsyncNoResult(_openDevice);
  final ValueNotifier<List<ProviderDevice>> pinnedDevices = ValueNotifier([]);

  DevicesManager() {
    _refreshPinned();
  }

  // Commands
  Future<List<ProviderDevice>> _refresh() async {
    final list = (await Future.wait(providers.map((e) => e.listDevices(timeout: const Duration(seconds: 10)))))
        .fold(<ProviderDevice>[], (list, e) => list += e);

    list.sort((a, b) => a.name.compareTo(b.name));

    return list;
  }

  Future _openDevice(ProviderDevice dev) async {
    await GetIt.I.get<ConnectedManager>().load(dev);

    GetIt.I.get<NavigationService>().replaceWith((_) => Connected());
  }

  Future _refreshPinned() async {
    final list = (await Future.wait(providers.map((e) => e.listPinnedDevices())))
        .fold(<ProviderDevice>[], (list, e) => list += e);

    list.sort((a, b) => a.name.compareTo(b.name));

    pinnedDevices.value = list;
  }

  static void registerManagers() {
    GetIt.I.registerSingleton(ConnectedManager());
  }
}
