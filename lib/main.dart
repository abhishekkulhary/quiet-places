import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dev/perf_probe.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/position_providers.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'data/ringer/platform_locale.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Hold the native splash until the first frame of the real UI is ready, so
  // the transition is a dissolve rather than a white flash.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Draw behind the system bars; SafeArea handles the insets.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  PerfProbe.startFrameStats();
  runApp(const ProviderScope(child: PhoneSilentApp()));
}

class PhoneSilentApp extends ConsumerStatefulWidget {
  const PhoneSilentApp({super.key});

  @override
  ConsumerState<PhoneSilentApp> createState() => _PhoneSilentAppState();
}

class _PhoneSilentAppState extends ConsumerState<PhoneSilentApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Register OS geofences to match the DB and warm the engine, once the first
    // frame is up so we don't block startup.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // The UI has painted; let the native splash go.
      FlutterNativeSplash.remove();
      try {
        // Start the low-power GPS warm-up so "Add current location" begins from
        // a recent fix rather than a cold acquisition. Lifecycle-aware: it stops
        // itself on background.
        unawaited(ref.read(gpsWarmupProvider.notifier).start());
        await ref.read(coordinatorProvider).initialize();
      } catch (_) {
        // Engine init can fail if permissions aren't granted yet; the
        // onboarding flow handles that. Don't crash startup.
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // A snooze that simply ran out produces no boundary crossing, and the OS
    // does drop the occasional transition. Re-deriving from the real position
    // on resume is the cheap catch-all: it is a no-op unless the device is
    // somewhere it should be silenced and currently isn't.
    unawaited(ref.read(coordinatorProvider).reconcileNow().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsStreamProvider);
    // Keep the out-of-tree copy in step, so notifications posted from this
    // isolate use the chosen language too.
    setPreferredLanguage(settings.valueOrNull?.localeCode);
    return MaterialApp(
      title: 'Quiet Places',
      // Null follows the device; a chosen language overrides it everywhere.
      locale: settings.valueOrNull?.localeCode == null
          ? null
          : Locale(settings.value!.localeCode!),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Dark is the app's designed native state; system preference still wins
      // when the user has explicitly chosen light.
      themeMode: ThemeMode.system,
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: settings.when(
        loading: () => const _Splash(),
        error: (_, _) => const HomeScreen(),
        data: (s) => s.onboardingComplete
            ? const HomeScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
