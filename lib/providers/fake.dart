import 'dart:async';
import 'dart:math';

import 'main.dart';

class FakeProviderDevice implements ProviderDevice {
  FakeProviderDevice();
  final _stream = StreamController<int>();

  @override
  Future connect() async {
    int last = 90;

    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      int v = Random().nextInt(11) - 5;
      if (last + v > 100) v = -v.abs();
      if (last - v < 80) v = v.abs();
      last += v;

      _stream.add(last);
    });
  }

  @override
  Stream<int> ppmStream() => _stream.stream;

  @override
  String get id => '00:00:00:00:00';

  @override
  String get name => 'Fake';

  @override
  int get battery => 100;
}

class FakeProvider implements Provider {
  const FakeProvider();

  @override
  Future<List<ProviderDevice>> listPinnedDevices() async {
    return [FakeProviderDevice()];
  }

  @override
  Future<List<ProviderDevice>> listDevices({Duration timeout = const Duration(seconds: 120)}) async {
    return [];
  }
}
