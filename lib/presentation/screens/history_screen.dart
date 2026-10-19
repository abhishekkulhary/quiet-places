import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/trip_log_entry.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/press.dart';
import '../widgets/radar_backdrop.dart';
import '../../l10n/app_localizations.dart';
import '../l10n_extensions.dart';

/// Entry/exit history as a readable timeline rather than a table of log lines:
/// a continuous rail with a node per event, grouped under day headers.
///
/// This is the "why didn't it fire?" screen, so the *reason* is the emphasised
/// text, not the timestamp.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final log = ref.watch(tripLogStreamProvider);
    final scheme = Theme.of(context).colorScheme;

    return QuietScaffold(
      appBar: AppBar(
        title: Text(l.historyTitle),
        titleTextStyle:
            AppType.screenTitle.copyWith(color: scheme.onSurface),
      ),
      body: log.when(
        loading: () => const _LoadingTimeline(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Text('${l.historyLoadFailed}\n$e',
                textAlign: TextAlign.center,
                style: AppType.body.copyWith(color: scheme.error)),
          ),
        ),
        data: (entries) =>
            entries.isEmpty ? const _EmptyHistory() : HistoryTimeline(entries: entries),
      ),
    );
  }
}

/// The history timeline.
///
/// Public so the sticky-header behaviour can be widget-tested directly without
/// standing up the whole screen's providers.
class HistoryTimeline extends StatelessWidget {
  final List<TripLogEntry> entries;
  const HistoryTimeline({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    // Group into days, preserving the newest-first order the query returns.
    final days = <String, List<TripLogEntry>>{};
    for (final e in entries) {
      days.putIfAbsent(_dayKey(e.timestamp, l), () => []).add(e);
    }

    return CustomScrollView(
      slivers: [
        for (final (index, entry) in days.entries.indexed)
          // SliverMainAxisGroup bounds the pinned header to its own day. Without
          // it, every pinned header stacks at the top and you end up reading
          // YESTERDAY's rows under a pile of headers. Grouped, each day's label
          // is pushed off by the next one, so exactly one is ever shown.
          SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _DayHeaderDelegate(
                  label: entry.key,
                  first: index == 0,
                ),
              ),
              SliverList.builder(
                itemCount: entry.value.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                  child: _TimelineRow(
                    entry: entry.value[i],
                    // The rail continues into the next day group, so only the
                    // very last row in the very last group terminates it.
                    isLast: index == days.length - 1 &&
                        i == entry.value.length - 1,
                  ),
                ),
              ),
            ],
          ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
      ],
    );
  }

  static String _dayKey(DateTime t, L l) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(t.year, t.month, t.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return l.historyToday;
    if (diff == 1) return l.historyYesterday;
    return '${that.day}/${that.month}/${that.year}';
  }
}

/// A pinned day header.
///
/// Opaque, because a pinned header scrolls content underneath itself — a
/// translucent one would show the rows sliding through the label.
class _DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String label;
  final bool first;

  const _DayHeaderDelegate({required this.label, required this.first});

  static const double _height = 44;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: _height,
      color: scheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(label,
              style: AppType.label.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(width: Space.xs),
          Expanded(child: Divider(color: scheme.outlineVariant)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_DayHeaderDelegate old) =>
      old.label != label || old.first != first;
}

/// One event: rail + node on the left, reason on the right.
class _TimelineRow extends StatelessWidget {
  final TripLogEntry entry;
  final bool isLast;

  const _TimelineRow({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accents = context.accents;
    final label = entry.action.labelOf(l);
    final highlight = entry.action.changedTheDevice;

    return Semantics(
      label: [
        entry.placeName,
        label,
        entry.transition.name,
        _time(entry.timestamp),
        if (entry.detail != null) entry.detail!,
      ].join(', '),
      child: ExcludeSemantics(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rail
              SizedBox(
                width: 26,
                child: Column(
                  children: [
                    _Node(
                      colour: highlight ? accents.ring : scheme.outline,
                      filled: highlight,
                    ),
                    Expanded(
                      child: Container(
                        width: Strokes.hairline,
                        color: isLast
                            ? Colors.transparent
                            : scheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.placeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.title
                                  .copyWith(color: scheme.onSurface),
                            ),
                          ),
                          Text(_time(entry.timestamp),
                              style: AppType.label
                                  .copyWith(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: AppType.label.copyWith(
                          color: highlight
                              ? accents.accentInk
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      if (entry.detail != null) ...[
                        const SizedBox(height: 2),
                        Text(entry.detail!,
                            style: AppType.bodySmall
                                .copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _Node extends StatelessWidget {
  final Color colour;
  final bool filled;
  const _Node({required this.colour, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.xxs),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? colour : Colors.transparent,
          border: Border.all(color: colour, width: Strokes.ring),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline, size: IconSize.hero, color: scheme.onSurfaceVariant),
            const SizedBox(height: Space.md),
            Text(l.historyEmptyTitle,
                textAlign: TextAlign.center,
                style: AppType.headline.copyWith(color: scheme.onSurface)),
            const SizedBox(height: Space.xs),
            Text(
              l.historyEmptyBody,
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingTimeline extends StatelessWidget {
  const _LoadingTimeline();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          Space.gutter, Space.md, Space.gutter, Space.md),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: Space.md),
      itemBuilder: (_, _) => const Skeleton(height: 48),
    );
  }
}
