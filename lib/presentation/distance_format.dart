import 'package:intl/intl.dart';

import '../domain/entities/app_settings.dart';
import '../domain/entities/place_distance.dart';
import '../l10n/app_localizations.dart';

/// A Quiet Place's distance reduced to exactly what the card renders.
///
/// Equality is over the *displayed* strings, not the raw doubles, so a card
/// only rebuilds when the number a user can actually see has changed — which is
/// what keeps a 1 Hz position stream from repainting the whole list.
///
/// Lives in `presentation/` rather than `domain/` because formatting needs
/// `intl` and the translated strings, and the domain layer stays free of both.
class PlaceDistanceDisplay {
  final String placeId;

  /// e.g. "85 m", "1.4 km", "280 ft" — null when position is unknown.
  final String? centre;

  /// e.g. "inside by 40 m" / "85 m to edge" / "Distance unavailable".
  final String detail;

  /// e.g. "±12 m", or null when there is no fix.
  final String? accuracy;

  final DistanceConfidence confidence;
  final BoundarySide? side;

  const PlaceDistanceDisplay({
    required this.placeId,
    required this.centre,
    required this.detail,
    required this.accuracy,
    required this.confidence,
    required this.side,
  });

  factory PlaceDistanceDisplay.from(
    PlaceDistance d, {
    required L l,
    required UnitSystem units,
    String? localeName,
  }) {
    final format = DistanceFormat(units: units, localeName: localeName);

    if (!d.hasPosition) {
      return PlaceDistanceDisplay(
        placeId: d.placeId,
        centre: null,
        detail: l.distanceUnavailable,
        accuracy: null,
        confidence: DistanceConfidence.unknown,
        side: null,
      );
    }

    final edge = roundForDisplay(d.signedEdgeMeters!);
    final edgeText = format.format(edge.abs());
    return PlaceDistanceDisplay(
      placeId: d.placeId,
      centre: format.format(roundForDisplay(d.centreMeters!)),
      detail: d.isInside
          ? l.distanceInsideBy(edgeText)
          : l.distanceToEdge(edgeText),
      accuracy: d.accuracyMeters == null
          ? null
          : '±${format.format(d.accuracyMeters!)}',
      confidence: d.confidence,
      side: d.side,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlaceDistanceDisplay &&
      other.placeId == placeId &&
      other.centre == centre &&
      other.detail == detail &&
      other.accuracy == accuracy &&
      other.confidence == confidence &&
      other.side == side;

  @override
  int get hashCode =>
      Object.hash(placeId, centre, detail, accuracy, confidence, side);
}

/// Formats a metre value for display, in the user's chosen units and locale.
///
/// Numbers go through `intl` so the decimal separator follows the locale — a
/// German user sees "1,4 km", not "1.4 km".
class DistanceFormat {
  static const double _metresPerFoot = 0.3048;
  static const double _feetPerMile = 5280;

  final UnitSystem units;
  final NumberFormat _whole;
  final NumberFormat _oneDecimal;

  DistanceFormat({required this.units, String? localeName})
      : _whole = NumberFormat.decimalPattern(localeName),
        _oneDecimal = NumberFormat('#,##0.0', localeName);

  String format(double meters) => switch (units) {
        UnitSystem.metric => _metric(meters),
        UnitSystem.imperial => _imperial(meters),
      };

  String _metric(double meters) {
    final m = meters.abs();
    if (m < 1000) return '${_whole.format(m.round())} m';
    return '${_oneDecimal.format(m / 1000)} km';
  }

  String _imperial(double meters) {
    final feet = meters.abs() / _metresPerFoot;
    if (feet < 1000) {
      // Mirrors the metric rule: coarser buckets as the number grows, so the
      // readout does not flicker while standing still.
      final step = feet < 300 ? 10 : 25;
      final rounded = (feet / step).round() * step;
      return '${_whole.format(rounded)} ft';
    }
    return '${_oneDecimal.format(feet / _feetPerMile)} mi';
  }
}
