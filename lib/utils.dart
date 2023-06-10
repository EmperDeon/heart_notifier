import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_command/flutter_command.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(Widget Function(BuildContext) builder) {
    return navigatorKey.currentState!.push(MaterialPageRoute(builder: builder));
  }

  Future<dynamic> replaceWith(Widget Function(BuildContext) builder) {
    return navigatorKey.currentState!.pushReplacement(MaterialPageRoute(builder: builder));
  }

  goBack() {
    return navigatorKey.currentState!.pop();
  }

  popAll() {
    navigatorKey.currentState!.popUntil(ModalRoute.withName('/'));
  }
}

initLicenses() {
  createStream() {
    late final StreamController<LicenseEntry> controller;
    controller = StreamController<LicenseEntry>(
      onListen: () async {
        controller
            .add(LicenseEntryWithLineBreaks(['Raleway Font'], await rootBundle.loadString('fonts/RalewayLicense.txt')));

        await controller.close();
      },
    );

    return controller.stream;
  }

  LicenseRegistry.addLicense(createStream);
}

extension ExtendedIterable<E> on Iterable<E> {
  /// Like Iterable<T>.map but the callback has index as second argument
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }

  void forEachIndexed(void Function(E e, int i) f) {
    var i = 0;
    forEach((e) => f(e, i++));
  }
}

extension Small on Duration {
  String toSmallString() {
    var microseconds = inMicroseconds;
    var negative = microseconds < 0;

    var hours = microseconds ~/ Duration.microsecondsPerHour;
    microseconds = microseconds.remainder(Duration.microsecondsPerHour);

    // Correcting for being negative after first division, instead of before,
    // to avoid negating min-int, -(2^31-1), of a native int64.
    if (negative) {
      hours = 0 - hours; // Not using `-hours` to avoid creating -0.0 on web.
      microseconds = 0 - microseconds;
    }

    var minutes = microseconds ~/ Duration.microsecondsPerMinute;
    microseconds = microseconds.remainder(Duration.microsecondsPerMinute);

    var minutesPadding = minutes < 10 ? "0" : "";

    var seconds = microseconds ~/ Duration.microsecondsPerSecond;
    microseconds = microseconds.remainder(Duration.microsecondsPerSecond);

    var secondsPadding = seconds < 10 ? "0" : "";

    return "$hours:$minutesPadding$minutes:$secondsPadding$seconds";
  }
}

int parseInt(String v) {
  return int.tryParse(v.replaceAll(RegExp('[^0-9]'), '')) ?? 0;
}

class PropertyValueNotifier<T> extends ValueNotifier<T> {
  PropertyValueNotifier(super.value);

  void notify() {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    notifyListeners();
  }
}

extension CommandNotifier<TParam, TResult> on Command<TParam, TResult> {
  void notify() {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    notifyListeners();
  }
}
