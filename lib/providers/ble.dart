import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'main.dart';

final HEART_RATE_SERVICE = Guid('0000180D-0000-1000-8000-00805f9b34fb');
final HEART_RATE_CHAR = Guid('00002A37-0000-1000-8000-00805f9b34fb');
final BATTERY_SERVICE = Guid('0000180F-0000-1000-8000-00805f9b34fb');
final BATTERY_CHAR = Guid('00002A19-0000-1000-8000-00805f9b34fb');
const MAC = 'D9:BA:14:D0:01:5C';

class BleProviderDevice implements ProviderDevice {
  final BluetoothDevice _device;
  final _stream = StreamController<int>();
  int _battery = 100;

  BleProviderDevice(this._device);

  static fromMac(String mac, String name) {
    return BleProviderDevice(BluetoothDevice.fromId(mac, name: name));
  }

  @override
  Future connect() async {
    // Ignore errors on connect (May be already connected)
    await _device.connect().catchError((e) => print(e));
    var newServices = await _device.discoverServices();

    var heartRateService = newServices.firstWhere((e) => e.uuid == HEART_RATE_SERVICE);
    var heartRate = heartRateService.characteristics.firstWhere((e) => e.uuid == HEART_RATE_CHAR);
    await heartRate.setNotifyValue(true);

    int last = 90;
    heartRate.value.listen((newBeat) {
      if (newBeat.isNotEmpty && newBeat[0] == 22) {
        last = newBeat[1];
      }
    });

    Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      _stream.add(last);
    });

    // Setup battery
    var batteryService = newServices.firstWhere((e) => e.uuid == BATTERY_SERVICE);
    var battery = batteryService.characteristics.firstWhere((e) => e.uuid == BATTERY_CHAR);
    final batteryInfo = await battery.read();
    _battery = batteryInfo[0];
  }

  @override
  Stream<int> ppmStream() => _stream.stream;

  @override
  String get id => _device.id.toString();

  @override
  String get name => _device.name;

  @override
  int get battery => _battery;
}

class BleProvider implements Provider {
  const BleProvider();

  @override
  Future<List<ProviderDevice>> listPinnedDevices() async {
    return [BleProviderDevice.fromMac(MAC, 'H6M 14002')];
  }

  @override
  Future<List<ProviderDevice>> listDevices({Duration timeout = const Duration(seconds: 120)}) async {
    FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
    flutterBlue.stopScan();

    flutterBlue.startScan(withServices: [HEART_RATE_SERVICE]);

    final List<ProviderDevice> list = [];

    flutterBlue.scanResults.listen((results) {
      for (final ScanResult result in results) {
        print('Append ${result.device}');
        if (result.device.name.isNotEmpty) list.add(BleProviderDevice(result.device));
      }
    });

    await Future.delayed(const Duration(seconds: 10));
    return Future.delayed(timeout, () => list);
  }
}
