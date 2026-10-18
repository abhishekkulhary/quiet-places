import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import 'press.dart';

/// The designed states every screen needs.
///
/// Centralised so a screen cannot quietly fall back to a bare spinner or an
/// unstyled exception: there is one place that defines what "empty", "error"
/// and "blocked" look like, and adding a screen means picking from these.
abstract final class StateViews {
  /// Skeleton list, used instead of a spinner while data loads.
  static Widget loadingList({
    int items = 3,
    double itemHeight = Sizes.cardSkeleton,
    double bottomInset = Space.md,
  }) =>
      _LoadingList(
          items: items, itemHeight: itemHeight, bottomInset: bottomInset);

  /// Something failed. Always names what failed and offers a way forward.
  static Widget error({
    required String message,
    String? detail,
    VoidCallback? onRetry,
  }) =>
      _MessageState(
        icon: Icons.error_outline,
        title: message,
        body: detail,
        onAction: onRetry,
        actionIsRetry: true,
      );

  /// Nothing here yet — a designed empty state, not an error.
  static Widget empty({
    required Widget art,
    required String title,
    required String body,
    double bottomInset = Space.xl,
  }) =>
      _EmptyState(
          art: art, title: title, body: body, bottomInset: bottomInset);
}

/// An inline, dismissible-free banner for a blocking condition the user can
/// fix — permission denied, services off, offline.
class StateBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Errors use the error palette; informational conditions use secondary.
  final bool severe;

  const StateBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.severe = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = severe ? scheme.errorContainer : scheme.secondaryContainer;
    final fg = severe ? scheme.onErrorContainer : scheme.onSecondaryContainer;

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title. $body',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(
            Space.gutter, Space.xs, Space.gutter, 0),
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        // Stacked rather than a single Row: at large text scales an action
        // button competing for width with wrapping copy overflows. Letting the
        // action sit below means the banner simply grows taller instead.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: IconSize.md, color: fg),
                const SizedBox(width: Space.xs),
                Expanded(
                  child: Text(title, style: AppType.title.copyWith(color: fg)),
                ),
              ],
            ),
            const SizedBox(height: Space.xxs),
            Text(body, style: AppType.bodySmall.copyWith(color: fg)),
            if (actionLabel != null && onAction != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Haptics.fire(Hap.commit);
                    onAction!();
                  },
                  child: Text(actionLabel!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  final int items;
  final double itemHeight;
  final double bottomInset;
  const _LoadingList({
    required this.items,
    required this.itemHeight,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: L.of(context).stateLoading,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
            Space.gutter, Space.xs, Space.gutter, bottomInset),
        itemCount: items,
        separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
        itemBuilder: (_, _) =>
            Skeleton(height: itemHeight, radius: Radii.cardShape),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final VoidCallback? onAction;
  final bool actionIsRetry;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.body,
    required this.onAction,
    required this.actionIsRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: IconSize.hero, color: scheme.onSurfaceVariant),
            const SizedBox(height: Space.md),
            Text(title,
                textAlign: TextAlign.center,
                style: AppType.headlineSmall.copyWith(color: scheme.onSurface)),
            if (body != null) ...[
              const SizedBox(height: Space.xs),
              Text(body!,
                  textAlign: TextAlign.center,
                  style:
                      AppType.bodySmall.copyWith(color: scheme.onSurfaceVariant)),
            ],
            if (onAction != null) ...[
              const SizedBox(height: Space.md),
              TextButton(
                onPressed: onAction,
                child: Text(l.stateErrorAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Widget art;
  final String title;
  final String body;
  final double bottomInset;

  const _EmptyState({
    required this.art,
    required this.title,
    required this.body,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            Space.xl, Space.xl, Space.xl, bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            art,
            const SizedBox(height: Space.xl),
            Text(title,
                textAlign: TextAlign.center,
                style: AppType.displayMedium.copyWith(color: scheme.onSurface)),
            const SizedBox(height: Space.sm),
            Text(body,
                textAlign: TextAlign.center,
                style: AppType.body.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
