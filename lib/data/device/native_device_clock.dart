import 'package:native_ringer/native_ringer.dart';

import '../../domain/services/device_clock.dart';

/// [DeviceClock] backed by the platform's monotonic since-boot counter.
class NativeDeviceClock implements DeviceClock {
  const NativeDeviceClock();

  @override
  Future<DateTime?> bootTime() async {
    try {
      final elapsed = await NativeRinger.elapsedRealtime();
      if (elapsed == null) return null;
      // Wall clock minus time-since-boot gives the boot instant. Both reads
      // drift slightly, which is why callers compare with a tolerance.
      return DateTime.now().subtract(Duration(milliseconds: elapsed));
    } catch (_) {
      return null;
    }
  }
}
