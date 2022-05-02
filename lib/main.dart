import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:simple_router/simple_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SimpleRouter.getKey(),
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

var HEART_RATE_SERVICE = Guid('0000180D-0000-1000-8000-00805f9b34fb');
var HEART_RATE_CHAR = Guid('00002A37-0000-1000-8000-00805f9b34fb');

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isScanning = false;
  String scanState = 'Start scan';
  Set<BluetoothDevice> devices = {};

  Future<void> startScan() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();
    const MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (isScanning) {
      setState(() {
        scanState = 'Start scan';
      });
      isScanning = !isScanning;

      FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
      flutterBlue.stopScan();
    } else {
      setState(() {
        scanState = 'Stop scan';
      });
      isScanning = !isScanning;

      FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
      flutterBlue.startScan(withServices: [HEART_RATE_SERVICE]);
      var subscription = flutterBlue.scanResults.listen((results) {
        // do something with scan results
        for (ScanResult r in results) {
          setState(() {
            if (r.device.name.isNotEmpty) {
              devices.add(r.device);
            }
          });
        }
      });

      await subscription.asFuture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
                ElevatedButton(onPressed: startScan, child: Text(scanState)),
              ] +
              devices
                  .map((e) => ElevatedButton(
                      onPressed: () =>
                          SimpleRouter.forward(WithDevice(device: e)),
                      child: Text('${e.id} - ${e.name}')))
                  .toList(),
        ),
      ),
    );
  }
}

class WithDevice extends StatefulWidget {
  const WithDevice({Key? key, required this.device}) : super(key: key);

  final BluetoothDevice device;

  @override
  State<WithDevice> createState() => _WithDeviceState();
}

class _WithDeviceState extends State<WithDevice> {
  int currentBeat = 0;
  int maxBeat = 120;
  bool isSubscribed = false;
  List<BluetoothCharacteristic> services = [];

  Future<void> subscribe() async {
    if (isSubscribed) return;

    setState(() {
      isSubscribed = true;
    });

    await widget.device.connect().catchError((e) => print(e));
    var newServices = await widget.device.discoverServices();

    var heartRateService =
        newServices.firstWhere((e) => e.uuid == HEART_RATE_SERVICE);
    var heartRate = heartRateService.characteristics
        .firstWhere((e) => e.uuid == HEART_RATE_CHAR);
    await heartRate.setNotifyValue(true);

    heartRate.value.listen((newBeat) {
      if (newBeat[0] == 22) {
        setNewBeat(newBeat[1]);
      }
    });
  }

  void setNewBeat(int beat) async {
    setState(() {
      currentBeat = beat;
    });

    FlutterLocalNotificationsPlugin notif = FlutterLocalNotificationsPlugin();
    if (maxBeat > 50 && beat > maxBeat) {
      const android = AndroidNotificationDetails(
        'heart_notifier',
        'heart_notifier',
        channelDescription: 'heart_notifier',
        importance: Importance.high,
        priority: Priority.high,
      );
      const platform = NotificationDetails(android: android);
      await notif.show(
        0,
        'HHR High !',
        '$beat',
        platform,
      );
    } else {
      await notif.cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.device.id} - ${widget.device.name}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(),
            if (!isSubscribed)
              ElevatedButton(
                onPressed: subscribe,
                child: const Text('Subscribe'),
              )
            else
              Text(
                'Rate: $currentBeat, Max: $maxBeat',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            const Spacer(),
            const Text('Max: '),
            TextField(
                onChanged: (v) => setState(() {
                      maxBeat =
                          int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ??
                              200;
                    })),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
