import 'package:heart_notifier/providers/fake.dart';

import 'ble.dart';

abstract interface class ProviderDevice {
  // Should initialize stream and wait for first value
  Future connect();

  Stream<int> ppmStream();

  String get id;
  String get name;
  int get battery;
}

abstract interface class Provider {
  Future<List<ProviderDevice>> listPinnedDevices();
  Future<List<ProviderDevice>> listDevices({Duration timeout = const Duration(seconds: 120)});
}

const List<Provider> providers = [
  BleProvider(),
  FakeProvider(),
];
