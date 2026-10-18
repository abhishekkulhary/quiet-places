import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_ringer/native_ringer.dart';

/// Exercises the Dart side of the ringer bridge against a **faked platform
/// channel**, so the wire format (method names, argument keys, wire values) is
/// pinned without needing a device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('native_ringer');
  final calls = <MethodCall>[];
  Object? Function(MethodCall)? responder;

  setUp(() {
    calls.clear();
    responder = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return responder?.call(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isSupported forwards the platform answer', () async {
    responder = (_) => true;
    expect(await NativeRinger.isSupported(), isTrue);

    responder = (_) => false;
    expect(await NativeRinger.isSupported(), isFalse);

    expect(calls.map((c) => c.method), everyElement('isSupported'));
  });

  test('isSupported defaults to false when the platform returns null', () async {
    responder = (_) => null;
    expect(await NativeRinger.isSupported(), isFalse);
  });

  test('capture decodes ringer mode and DND', () async {
    responder = (_) => {'ringerMode': NativeRinger.wireVibrate, 'dndEnabled': true};

    final snap = await NativeRinger.capture();
    expect(snap.ringerMode, NativeRinger.wireVibrate);
    expect(snap.dndEnabled, isTrue);
    expect(calls.single.method, 'capture');
  });

  test('capture degrades to unknown when the platform returns nothing',
      () async {
    responder = (_) => null;
    final snap = await NativeRinger.capture();
    expect(snap.ringerMode, NativeRinger.wireUnknown);
    expect(snap.dndEnabled, isFalse);
  });

  test('applyState sends both axes with the documented argument keys',
      () async {
    responder = (_) => null;
    await NativeRinger.applyState(
        ringerMode: NativeRinger.wireSilent, dndEnabled: true);

    final call = calls.single;
    expect(call.method, 'applyState');
    expect(call.arguments, {
      'ringerMode': NativeRinger.wireSilent,
      'dndEnabled': true,
    });
  });

  test('DND access check and settings trip use the expected methods', () async {
    responder = (call) => call.method == 'isDndAccessGranted' ? true : null;

    expect(await NativeRinger.isDndAccessGranted(), isTrue);
    await NativeRinger.openDndSettings();

    expect(calls.map((c) => c.method).toList(),
        ['isDndAccessGranted', 'openDndSettings']);
  });

  test('a platform error propagates rather than being swallowed', () async {
    // The Android side raises this when DND policy access was never granted;
    // callers must be able to see it.
    responder = (_) => throw PlatformException(code: 'dnd_access_denied');

    expect(
      () => NativeRinger.applyState(
          ringerMode: NativeRinger.wireSilent, dndEnabled: true),
      throwsA(isA<PlatformException>()
          .having((e) => e.code, 'code', 'dnd_access_denied')),
    );
  });

  test('wire constants match the AudioManager contract', () {
    // These must not drift from NativeRingerPlugin.kt.
    expect(NativeRinger.wireSilent, 0);
    expect(NativeRinger.wireVibrate, 1);
    expect(NativeRinger.wireNormal, 2);
    expect(NativeRinger.wireUnknown, -1);
  });
}
