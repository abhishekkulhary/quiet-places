import 'package:flutter/material.dart';

import '../domain/entities/place_distance.dart';
import '../domain/entities/quiet_place_behaviour.dart';
import '../domain/entities/trip_log_entry.dart';
import '../l10n/app_localizations.dart';

/// Maps domain enums onto translated strings.
///
/// This lives in `presentation/` rather than on the enums themselves because
/// the generated localisations import Flutter, and the domain layer must stay
/// free of it. The enums keep an untranslated English [QuietPlaceBehaviour.label]
/// for logs and for the background isolate, which has no BuildContext.
extension QuietPlaceBehaviourL10n on QuietPlaceBehaviour {
  /// The one icon mapping for a behaviour, shared by the place cards and the
  /// silencing moment. Kept in a single place because the moment used to draw
  /// a fixed "silent" bell regardless of what was applied, so entering a Do Not
  /// Disturb place announced itself with the Silent icon.
  IconData get icon => switch (this) {
        QuietPlaceBehaviour.vibrate => Icons.vibration,
        QuietPlaceBehaviour.silent => Icons.notifications_off_outlined,
        QuietPlaceBehaviour.dnd => Icons.do_not_disturb_on_outlined,
      };

  String labelOf(L l) => switch (this) {
        QuietPlaceBehaviour.vibrate => l.behaviourVibrate,
        QuietPlaceBehaviour.silent => l.behaviourSilent,
        QuietPlaceBehaviour.dnd => l.behaviourDnd,
      };

  /// Compact form for the segmented picker, where "Do Not Disturb" will not fit.
  String shortLabelOf(L l) => switch (this) {
        QuietPlaceBehaviour.vibrate => l.behaviourVibrate,
        QuietPlaceBehaviour.silent => l.behaviourSilent,
        QuietPlaceBehaviour.dnd => l.behaviourDndShort,
      };
}

extension TripActionL10n on TripAction {
  /// Human wording for the history timeline.
  String labelOf(L l) => switch (this) {
        TripAction.applied => l.historySilenced,
        TripAction.restored => l.historyRestored,
        TripAction.reResolved => l.historySwitched,
        TripAction.notified => l.historyNotified,
        TripAction.skippedPaused => l.historySkippedPaused,
        TripAction.skippedDisabled => l.historySkippedDisabled,
        TripAction.skippedUnsupported => l.historySkippedUnsupported,
        TripAction.skippedOverride => l.historySkippedOverride,
        TripAction.observed => l.historyNoChange,
        TripAction.error => l.historyError,
      };

  /// Whether this event actually changed the device — those are the ones worth
  /// spotting at a glance in the timeline.
  bool get changedTheDevice => switch (this) {
        TripAction.applied ||
        TripAction.restored ||
        TripAction.reResolved =>
          true,
        _ => false,
      };
}

extension BoundarySideL10n on BoundarySide {
  bool get isInside => this == BoundarySide.inside;
}
