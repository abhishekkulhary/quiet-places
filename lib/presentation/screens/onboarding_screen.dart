import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/press.dart';
import '../widgets/radar_backdrop.dart';
import 'home_screen.dart';
import '../../l10n/app_localizations.dart';

/// Guided permission setup. Several of these grants cannot be obtained from a
/// normal runtime dialog (background location's "Allow all the time", DND policy
/// access, battery-optimisation exemption), so each is explained with its own
/// rationale and a button that opens the right system screen.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// When true this was opened from Settings and should pop back, not replace.
  final bool returnToApp;
  const OnboardingScreen({super.key, this.returnToApp = false});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  bool _fgLocation = false;
  bool _bgLocation = false;
  bool _dndAccess = false;
  bool _notifications = false;
  bool _batteryExempt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check after the user returns from a system settings screen.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final location = ref.read(locationServiceProvider);
    final ringer = ref.read(ringerControllerProvider);
    final fg = await location.hasLocationPermission();
    final bg = await location.hasBackgroundPermission();
    final dnd = await ringer.isDndAccessGranted();
    final notif = await Permission.notification.isGranted;
    final battery = Platform.isAndroid
        ? await Permission.ignoreBatteryOptimizations.isGranted
        : true;
    if (!mounted) return;
    setState(() {
      _fgLocation = fg;
      _bgLocation = bg;
      _dndAccess = dnd;
      _notifications = notif;
      _batteryExempt = battery;
    });
  }

  Future<void> _finish() async {
    await ref.read(coordinatorProvider).markOnboardingComplete();
    try {
      await ref.read(coordinatorProvider).initialize();
    } catch (_) {}
    if (!mounted) return;
    if (widget.returnToApp) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final isAndroid = Platform.isAndroid;
    final ringerSupported = ref.watch(ringerSupportedProvider);

    return QuietScaffold(
      appBar: AppBar(
        title: Text(l.onboardingTitle),
        titleTextStyle: AppType.screenTitle.copyWith(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          TextButton(
            onPressed: _finish,
            child: Text(widget.returnToApp ? l.onboardingDone : l.onboardingSkip),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Space.gutter, 0, Space.gutter, Space.xxl),
        children: [
          Text(l.onboardingHeading,
              style: AppType.displayMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: Space.xs),
          Text(
              l.onboardingIntro,
              style: AppType.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: Space.lg),

          _PermCard(
            title: l.permLocationTitle,
            granted: _fgLocation,
            rationale: l.permLocationBody,
            actionLabel: l.onboardingGrant,
            onAction: () async {
              await ref.read(locationServiceProvider).requestForeground();
              await _refresh();
            },
          ),
          _PermCard(
            title: l.permBackgroundTitle,
            granted: _bgLocation,
            rationale: l.permBackgroundBody,
            actionLabel: l.onboardingOpenSettings,
            onAction: () async {
              // Background location must be changed in system settings.
              await Permission.locationAlways.request();
              await ref.read(locationServiceProvider).openAppSettings();
            },
          ),

          if (isAndroid && ringerSupported)
            _PermCard(
              title: l.permDndTitle,
              granted: _dndAccess,
              rationale: l.permDndBody,
              actionLabel: l.permDndAction,
              onAction: () async {
                await ref.read(ringerControllerProvider).requestDndAccess();
              },
            ),

          _PermCard(
            title: l.permNotificationsTitle,
            granted: _notifications,
            rationale: Platform.isIOS
                ? l.permNotificationsBodyIos
                : l.permNotificationsBodyAndroid,
            actionLabel: l.onboardingGrant,
            onAction: () async {
              await Permission.notification.request();
              await ref.read(notificationServiceProvider).requestPermission();
              await _refresh();
            },
          ),

          if (isAndroid)
            _PermCard(
              title: l.permBatteryTitle,
              granted: _batteryExempt,
              rationale: l.permBatteryBody,
              actionLabel: l.onboardingRequest,
              onAction: () async {
                await Permission.ignoreBatteryOptimizations.request();
                await _refresh();
              },
            ),

          if (isAndroid) const _OemAutostartCard(),
          if (Platform.isIOS) const _IosShortcutsCard(),
          if (!ringerSupported && !Platform.isIOS)
            const _DesktopCard(),

          const SizedBox(height: Space.lg),
          PressableScale(
            onPressed: _finish,
            semanticLabel: l.onboardingFinishSemantic,
            child: Container(
              height: Sizes.button,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Text(l.onboardingFinish,
                  style: AppType.buttonLabel.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermCard extends StatelessWidget {
  final String title;
  final String rationale;
  final bool granted;
  final String actionLabel;
  final VoidCallback onAction;

  const _PermCard({
    required this.title,
    required this.rationale,
    required this.granted,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;
    return Semantics(
      container: true,
      label: '$title, '
          '${granted ? l.onboardingGranted : l.onboardingNotGranted}',
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.sm),
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: Radii.cardShape,
          border: Border.all(
            color: granted ? accents.ring : scheme.outline,
            width: Strokes.hairline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  granted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: IconSize.md,
                  color: granted ? accents.accentInk : scheme.outline,
                ),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(title,
                      style: AppType.title.copyWith(color: scheme.onSurface)),
                ),
              ],
            ),
            const SizedBox(height: Space.xs),
            Text(rationale,
                style: AppType.bodySmall
                    .copyWith(color: scheme.onSurfaceVariant)),
            if (!granted) ...[
              const SizedBox(height: Space.xxs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Haptics.fire(Hap.commit);
                    onAction();
                  },
                  child: Text(actionLabel.toUpperCase()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OemAutostartCard extends StatelessWidget {
  const _OemAutostartCard();
  @override
  Widget build(BuildContext context) => _NoteCard(
        title: L.of(context).noteOemTitle,
        body: L.of(context).noteOemBody,
      );
}

/// Shared note card so the informational blocks match the setting cards.
class _NoteCard extends StatelessWidget {
  final String title;
  final String body;
  const _NoteCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: Radii.cardShape,
        border: Border.all(color: scheme.outline, width: Strokes.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppType.label.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: Space.xs),
          Text(body,
              style: AppType.bodySmall.copyWith(color: scheme.onSurface)),
        ],
      ),
    );
  }
}

class _IosShortcutsCard extends StatelessWidget {
  const _IosShortcutsCard();
  @override
  Widget build(BuildContext context) => _NoteCard(
        title: L.of(context).noteIosTitle,
        body: L.of(context).noteIosBody,
      );
}

class _DesktopCard extends StatelessWidget {
  const _DesktopCard();
  @override
  Widget build(BuildContext context) => _NoteCard(
        title: L.of(context).noteDesktopTitle,
        body: L.of(context).noteDesktopBody,
      );
}
