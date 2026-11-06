import 'package:flutter_modular/flutter_modular.dart';

import 'money/money_formatter.dart';
import 'time/clock.dart';
import 'time/local_calendar.dart';

/// Dependencies shared by every feature. Feature modules list it in
/// `imports` and receive these binds by their interface type.
class CoreModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i
      ..addSingleton<Clock>(SystemClock.new)
      ..addSingleton<LocalCalendar>(DeviceCalendar.new)
      ..addSingleton<MoneyFormatter>(MoneyFormatter.new);
  }
}
