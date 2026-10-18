/// The device's audio ringer mode, mirroring Android's `AudioManager` values.
///
/// This is deliberately platform-agnostic: the domain layer reasons about these
/// values without knowing how any platform realises them.
enum RingerMode {
  silent,
  vibrate,
  normal,

  /// The mode could not be determined (e.g. unsupported platform, or the OS
  /// returned an unexpected value). We never *set* this; it only appears when
  /// reading state we could not interpret.
  unknown,
}

/// A snapshot of the device's audio state taken *before* we mutate it, so it can
/// be restored verbatim on exit.
///
/// [RingerMode] and Do-Not-Disturb are independent axes on Android: DND
/// (interruption filter) can be on while the ringer mode is `normal`. We capture
/// both so restoration never has to guess.
class CapturedRingerState {
  final RingerMode ringerMode;
  final bool dndEnabled;

  const CapturedRingerState({
    required this.ringerMode,
    required this.dndEnabled,
  });

  /// A sentinel used on platforms that cannot read ringer state.
  static const unknown = CapturedRingerState(
    ringerMode: RingerMode.unknown,
    dndEnabled: false,
  );

  bool get isKnown => ringerMode != RingerMode.unknown;

  /// A stable string used to detect manual user overrides: if the live device
  /// state no longer matches the signature we last applied, the user changed it.
  String get signature => '${ringerMode.name}:$dndEnabled';

  CapturedRingerState copyWith({RingerMode? ringerMode, bool? dndEnabled}) {
    return CapturedRingerState(
      ringerMode: ringerMode ?? this.ringerMode,
      dndEnabled: dndEnabled ?? this.dndEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CapturedRingerState &&
      other.ringerMode == ringerMode &&
      other.dndEnabled == dndEnabled;

  @override
  int get hashCode => Object.hash(ringerMode, dndEnabled);

  @override
  String toString() => 'CapturedRingerState($signature)';
}
