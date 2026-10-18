import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Lays a screen out as one column on phones and two panes on wide screens.
///
/// Wide means tablets, unfolded foldables, and phones in landscape. The list
/// keeps a fixed width and the detail pane takes the remainder, because a map
/// gains far more from extra width than a list of cards does.
class AdaptivePanes extends StatelessWidget {
  /// The primary content — the Quiet Places list.
  final Widget primary;

  /// Shown beside [primary] only when there is room. Null means single pane.
  final WidgetBuilder? detail;

  const AdaptivePanes({super.key, required this.primary, this.detail});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            Breakpoints.isWide(constraints.maxWidth) && detail != null;
        if (!wide) return primary;

        final scheme = Theme.of(context).colorScheme;
        return Row(
          children: [
            SizedBox(width: Breakpoints.listPaneWidth, child: primary),
            VerticalDivider(
              width: Strokes.hairline,
              thickness: Strokes.hairline,
              color: scheme.outlineVariant,
            ),
            Expanded(child: detail!(context)),
          ],
        );
      },
    );
  }
}
