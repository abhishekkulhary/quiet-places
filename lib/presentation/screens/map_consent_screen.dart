import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/press.dart';
import '../../l10n/app_localizations.dart';

/// The gate in front of the only feature that sends anything off the device.
///
/// The wording here is deliberately un-reassuring. It would be easy to write
/// "we only send tile indices, no personal data" — technically true and
/// misleading, because at street zoom the sequence of tiles you request
/// pinpoints the place you are editing. If someone works that out later, the
/// reassuring version is what destroys their trust. So it says it plainly.
class MapConsentScreen extends ConsumerWidget {
  const MapConsentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.consentTitle),
        titleTextStyle:
            AppType.screenTitle.copyWith(color: scheme.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Space.gutter, 0, Space.gutter, Space.xxl),
        children: [
          Text(l.consentHeading,
              style:
                  AppType.displayMedium.copyWith(color: scheme.onSurface)),
          const SizedBox(height: Space.md),
          Text(
            l.consentIntro,
            style: AppType.body.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Space.lg),
          _Point(title: l.consentSentTitle, body: l.consentSentBody),
          _Point(title: l.consentSearchTitle, body: l.consentSearchBody),
          _Point(title: l.consentNeverTitle, body: l.consentNeverBody),
          _Point(title: l.consentWhoTitle, body: l.consentWhoBody),
          _Point(title: l.consentOffTitle, body: l.consentOffBody),
          const SizedBox(height: Space.lg),
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: Radii.cardShape,
              border: Border.all(color: scheme.outline, width: Strokes.hairline),
            ),
            child: Text(
              l.consentFallback,
              style: AppType.bodySmall.copyWith(color: scheme.onSurface),
            ),
          ),
          const SizedBox(height: Space.lg),
          PressableScale(
            semanticLabel: l.consentTitle,
            onPressed: () async {
              await ref.read(coordinatorProvider).setMapsEnabled(true);
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: Container(
              height: Sizes.button,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Text(l.consentAccept,
                  style: AppType.buttonLabel.copyWith(color: scheme.onPrimaryContainer)),
            ),
          ),
          const SizedBox(height: Space.xs),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.consentDecline,
                  style: AppType.label.copyWith(color: accents.accentInk)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final String title;
  final String body;
  const _Point({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppType.label.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: Space.xxs),
          Text(body, style: AppType.body.copyWith(color: scheme.onSurface)),
        ],
      ),
    );
  }
}
