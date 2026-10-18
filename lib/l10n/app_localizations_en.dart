// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Quiet Places';

  @override
  String get statePermissionTitle => 'Location permission is off';

  @override
  String get statePermissionBody => 'Distances and silencing need it.';

  @override
  String get statePermissionAction => 'GRANT';

  @override
  String get stateServicesTitle => 'Location services are off';

  @override
  String get stateServicesBody => 'Turn them on to see distances.';

  @override
  String get stateServicesAction => 'OPEN SETTINGS';

  @override
  String get stateOfflineTitle => 'No connection';

  @override
  String get stateOfflineBody => 'Showing saved map squares.';

  @override
  String get stateErrorAction => 'TRY AGAIN';

  @override
  String get stateLoading => 'Loading';

  @override
  String get homeTitle => 'Your quiet\nplaces';

  @override
  String get homeAddCurrent => 'ADD A QUIET PLACE';

  @override
  String get homeAddCurrentSemantic =>
      'Add a Quiet Place, starting from where you are';

  @override
  String get homeLoadFailed => 'We couldn\'t load your Quiet Places.';

  @override
  String get homeEmptyTitle => 'Nowhere quiet\nyet';

  @override
  String get homeEmptyBody =>
      'Stand somewhere your phone should hush — a cinema, an office, a bedroom — and save the spot.';

  @override
  String get homePaused => 'Silencing is paused';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionRedo => 'Redo';

  @override
  String get actionRetry => 'RETRY';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String get actionOpenSettings => 'OPEN SETTINGS';

  @override
  String get actionAppSettings => 'APP SETTINGS';

  @override
  String get actionEnterManually => 'ENTER MANUALLY';

  @override
  String placeDeleted(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String get undoLabel => 'UNDO';

  @override
  String undoSecondsRemaining(int seconds) {
    return '$seconds seconds to undo';
  }

  @override
  String placeEnabledSemantic(String name) {
    return '$name enabled';
  }

  @override
  String placeCardSemantic(String name, String behaviour, int radius) {
    return '$name, $behaviour, $radius metre radius';
  }

  @override
  String get semanticPositionUncertain => 'position uncertain';

  @override
  String get semanticDisabled => 'disabled';

  @override
  String get distanceUnavailable => 'Distance unavailable';

  @override
  String distanceInsideBy(String distance) {
    return 'inside by $distance';
  }

  @override
  String distanceToEdge(String distance) {
    return '$distance to edge';
  }

  @override
  String get editorTitleNew => 'New Quiet Place';

  @override
  String get editorTitleEdit => 'Edit Quiet Place';

  @override
  String get editorSaveNew => 'SAVE QUIET PLACE';

  @override
  String get editorSaveChanges => 'SAVE CHANGES';

  @override
  String get editorFieldName => 'NAME';

  @override
  String get editorFieldRadius => 'RADIUS';

  @override
  String get editorFieldWhenInside => 'WHEN INSIDE';

  @override
  String get editorUnitMetresShort => 'M';

  @override
  String get editorWaitingForPosition =>
      'Waiting for a position — or place the pin yourself above.';

  @override
  String get editorPlacedManually => 'PLACED MANUALLY';

  @override
  String get editorLocating => 'LOCATING…';

  @override
  String get editorImproving => 'IMPROVING…';

  @override
  String get editorHintMap =>
      'Drag the pin to move it · long-press the map to place it somewhere else · or search an address';

  @override
  String get editorHintDial =>
      'Drag inside the circle to move the pin, or turn on maps to place it visually';

  @override
  String get editorHintEditing =>
      'Drag the edge handle to resize, or use the slider below';

  @override
  String get editorShowMap => 'SHOW A MAP';

  @override
  String get editorShowMapSemantic => 'Show a map here';

  @override
  String get editorSearchHint => 'Search an address or place';

  @override
  String get editorSearchSemantic => 'Search for a place';

  @override
  String editorRadiusSemantic(int radius) {
    return '$radius metres radius';
  }

  @override
  String editorRadiusUnreliable(int threshold) {
    return 'Under $threshold m is unreliable on most hardware — the OS may fire late, or not at all.';
  }

  @override
  String get editorDiscardTitle => 'Discard changes?';

  @override
  String get editorDiscardBody =>
      'This Quiet Place has not been saved. Your edits will be lost.';

  @override
  String get editorDiscardKeep => 'KEEP EDITING';

  @override
  String get editorDiscardConfirm => 'DISCARD';

  @override
  String get editorDefaultName => 'Location';

  @override
  String editorSuggestedName(int number) {
    return 'Location $number';
  }

  @override
  String overlapStricterWins(String names, String winner) {
    return 'This overlaps $names. Where they meet, $winner wins — the stricter setting applies.';
  }

  @override
  String overlapThisWins(String names, String behaviour) {
    return 'This overlaps $names. Where they meet, $behaviour still applies — it is the stricter setting.';
  }

  @override
  String get behaviourVibrate => 'Vibrate';

  @override
  String get behaviourSilent => 'Silent';

  @override
  String get behaviourDnd => 'Do Not Disturb';

  @override
  String get behaviourDndShort => 'DND';

  @override
  String get positionServicesOff => 'Location services are off.';

  @override
  String get positionPermissionNeeded =>
      'Quiet Places needs location permission to use where you are.';

  @override
  String get positionPermissionForever =>
      'Location permission is permanently denied.';

  @override
  String get positionTimeoutWithFix =>
      'Couldn\'t sharpen the fix — showing the best so far.';

  @override
  String get positionTimeoutNoFix =>
      'No GPS fix yet. Indoors this can take a while.';

  @override
  String get positionUnknownFailure => 'Couldn\'t work out where you are.';

  @override
  String mapPreviewSemantic(int radius) {
    return 'Quiet Place preview, $radius metre radius';
  }

  @override
  String get mapPreviewNoPosition => 'Quiet Place preview, no position yet';

  @override
  String get mapCentreSemantic => 'Quiet Place centre, drag to move';

  @override
  String get mapHandleSemantic => 'Radius handle, drag to resize';

  @override
  String get mapRecentre => 'Recentre on me';

  @override
  String get mapAttribution => '© OpenStreetMap contributors';

  @override
  String get consentTitle => 'Turn on maps';

  @override
  String get consentHeading => 'This is the only\npart that uses\nthe internet';

  @override
  String get consentIntro =>
      'Everything else in Quiet Places stays on your phone. Your Quiet Places, their names, your history — none of it is ever sent anywhere, with or without maps.';

  @override
  String get consentSentTitle => 'WHAT GETS SENT';

  @override
  String get consentSentBody =>
      'Requests to OpenStreetMap for the map squares on your screen. Each request is a map square number, not your coordinates — but at street zoom a square is about 600 m across, so the squares you load do reveal roughly where the place you are editing is. We would rather say that than let you find out later.';

  @override
  String get consentSearchTitle => 'SEARCH AND PLACE NAMES';

  @override
  String get consentSearchBody =>
      'If you search for an address, that text is sent to OpenStreetMap\'s search service. When you finish moving the pin, its coordinates are sent once to look up a name to suggest — only when you let go, never continuously, and the answer is reused if you nudge it again. You can always type the name yourself instead.';

  @override
  String get consentNeverTitle => 'WHAT NEVER GETS SENT';

  @override
  String get consentNeverBody =>
      'Your saved places, their names, your entry and exit history, your settings. There is no analytics, no crash reporting, and no account.';

  @override
  String get consentWhoTitle => 'WHO RECEIVES IT';

  @override
  String get consentWhoBody =>
      'The OpenStreetMap Foundation\'s tile and search servers. They see the request and your IP address, as any website would. We send a User-Agent naming this app, which their usage policy requires, and we rate-limit what we send.';

  @override
  String get consentOffTitle => 'YOU CAN TURN IT BACK OFF';

  @override
  String get consentOffBody =>
      'Maps can be switched off again in Settings at any time, and the map cache cleared. With maps off the app makes no network requests at all.';

  @override
  String get consentFallback =>
      'Without maps, the editor still works: you place a Quiet Place from where you are standing, or by typing coordinates, and set the radius on the dial.';

  @override
  String get consentAccept => 'TURN ON MAPS';

  @override
  String get consentDecline => 'KEEP THE APP OFFLINE';

  @override
  String get settingsSectionWhen => 'WHEN TO ACT';

  @override
  String get settingsSectionLocation => 'LOCATION';

  @override
  String get settingsSectionMaps => 'MAPS';

  @override
  String get settingsSectionDevice => 'THIS DEVICE';

  @override
  String get settingsSectionLanguage => 'LANGUAGE';

  @override
  String get settingsLanguageTitle => 'App language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsSectionHistory => 'HISTORY';

  @override
  String get settingsSectionUnits => 'UNITS';

  @override
  String get settingsPauseTitle => 'Pause everything';

  @override
  String get settingsPauseBody => 'Nothing is silenced while this is on';

  @override
  String get settingsSnoozeTitle => 'Snooze for 1 hour';

  @override
  String get settingsSnoozedTitle => 'Snoozed';

  @override
  String get settingsSnoozeBody => 'Temporarily stop silencing';

  @override
  String settingsSnoozeUntil(String time) {
    return 'Resumes at $time';
  }

  @override
  String get settingsSnoozeAction => 'SNOOZE';

  @override
  String get settingsCancel => 'CANCEL';

  @override
  String get settingsWarmTitle => 'Keep GPS warm';

  @override
  String get settingsWarmBody =>
      'Holds a recent fix while the app is open so adding a Quiet Place is instant. Uses a little more battery.';

  @override
  String get settingsManualTitle => 'Add a Quiet Place manually';

  @override
  String get settingsManualBody => 'Drop a pin somewhere you are not standing';

  @override
  String get settingsOpen => 'OPEN';

  @override
  String get settingsMapsTitle => 'Show map tiles';

  @override
  String get settingsMapsOn =>
      'Map squares are fetched from OpenStreetMap as you look at them. Nothing else leaves your phone.';

  @override
  String get settingsMapsOff =>
      'Off — the app makes no network requests at all.';

  @override
  String get settingsCacheTitle => 'Map cache';

  @override
  String settingsCacheBody(String size) {
    return '$size stored · tiles are reused instead of re-downloaded';
  }

  @override
  String get settingsCacheChecking => 'Checking…';

  @override
  String get settingsClear => 'CLEAR';

  @override
  String get settingsCacheCleared => 'Map cache cleared';

  @override
  String get settingsRingerAvailable => 'Ringer control available';

  @override
  String get settingsRingerUnavailable => 'Ringer control unavailable';

  @override
  String get settingsRingerAvailableBody =>
      'Quiet Places can change your ringer on this device.';

  @override
  String get settingsPermissionsTitle => 'Permission setup';

  @override
  String get settingsPermissionsBody => 'Re-run the guided checks';

  @override
  String get settingsReview => 'REVIEW';

  @override
  String get settingsClearLogTitle => 'Clear the log';

  @override
  String get settingsClearLogBody => 'Removes every recorded entry and exit';

  @override
  String get settingsHistoryCleared => 'History cleared';

  @override
  String get settingsUnitsTitle => 'Distance units';

  @override
  String get settingsUnitsMetric => 'Metres and kilometres';

  @override
  String get settingsUnitsImperial => 'Feet and miles';

  @override
  String get historyTitle => 'History';

  @override
  String get historyToday => 'TODAY';

  @override
  String get historyYesterday => 'YESTERDAY';

  @override
  String get historyEmptyTitle => 'Nothing has happened yet';

  @override
  String get historyEmptyBody =>
      'Every time Quiet Places silences or restores your ringer — or decides not to — it will be listed here with the reason.';

  @override
  String get historyLoadFailed => 'We couldn\'t load your history.';

  @override
  String get historySilenced => 'SILENCED';

  @override
  String get historyRestored => 'RINGER RESTORED';

  @override
  String get historySwitched => 'SWITCHED MODE';

  @override
  String get historyNotified => 'NOTIFIED YOU';

  @override
  String get historySkippedPaused => 'SKIPPED — PAUSED';

  @override
  String get historySkippedDisabled => 'SKIPPED — PLACE OFF';

  @override
  String get historySkippedUnsupported => 'SKIPPED — UNSUPPORTED';

  @override
  String get historySkippedOverride => 'SKIPPED — YOU OVERRODE IT';

  @override
  String get historyNoChange => 'NO CHANGE NEEDED';

  @override
  String get historyError => 'ERROR';

  @override
  String get momentSilenced => 'SILENCED';

  @override
  String get momentRestored => 'RESTORED';

  @override
  String momentNowBehaviour(String behaviour) {
    return 'NOW $behaviour';
  }

  @override
  String get momentRestoreExplain =>
      'Your phone will go back to how you had it when you leave.';

  @override
  String momentSemanticApplied(String name, String behaviour) {
    return '$name: phone set to $behaviour';
  }

  @override
  String momentSemanticRestored(String name) {
    return 'Ringer restored on leaving $name';
  }

  @override
  String get onboardingTitle => 'Setup';

  @override
  String get onboardingHeading => 'A few permissions';

  @override
  String get onboardingIntro =>
      'Silencing happens while the app is closed, so Android needs you to grant these explicitly.';

  @override
  String get onboardingDone => 'DONE';

  @override
  String get onboardingSkip => 'SKIP';

  @override
  String get onboardingFinish => 'FINISH SETUP';

  @override
  String get onboardingFinishSemantic => 'Finish setup';

  @override
  String get onboardingGranted => 'granted';

  @override
  String get onboardingNotGranted => 'not granted';

  @override
  String get onboardingGrant => 'Grant';

  @override
  String get onboardingOpenSettings => 'Open settings';

  @override
  String get onboardingRequest => 'Request';

  @override
  String get permLocationTitle => 'Location';

  @override
  String get permLocationBody =>
      'To capture the spot you\'re standing in and detect when you arrive.';

  @override
  String get permBackgroundTitle => 'Location — \"Allow all the time\"';

  @override
  String get permBackgroundBody =>
      'Quiet Places only fire in the background with all-the-time access. Denying this means silencing works only while the app is open.';

  @override
  String get permDndTitle => 'Do Not Disturb access';

  @override
  String get permDndBody =>
      'Required to switch silent/DND modes. This one can\'t be a normal popup — you grant it on a dedicated system screen.';

  @override
  String get permDndAction => 'Open DND settings';

  @override
  String get permNotificationsTitle => 'Notifications';

  @override
  String get permNotificationsBodyIos =>
      'iOS can\'t silence your ringer automatically. Instead we\'ll notify you on arrival so you can do it (or trigger a Shortcuts Focus automation).';

  @override
  String get permNotificationsBodyAndroid =>
      'For the brief foreground notice while changing your ringer.';

  @override
  String get permBatteryTitle => 'Ignore battery optimisation';

  @override
  String get permBatteryBody =>
      'Aggressive battery savers can kill background delivery. Exempting Quiet Places keeps it reliable.';

  @override
  String get noteOemTitle => 'ON XIAOMI / OPPO / VIVO / SAMSUNG';

  @override
  String get noteOemBody =>
      'These brands add their own \"autostart\" or \"protected apps\" controls that stop background apps. Find Quiet Places in your phone\'s Battery or App-management settings and enable Autostart / Allow background activity, or Quiet Places may stop firing.';

  @override
  String get noteIosTitle => 'IOS CANNOT SILENCE AUTOMATICALLY';

  @override
  String get noteIosBody =>
      'Apple provides no API to change the ringer. For a hands-free setup, open Shortcuts → Automation → Create a Location automation for the same place and set it to turn on a Focus mode. Quiet Places still notifies you on arrival as a backup.';

  @override
  String get noteDesktopTitle => 'NO RINGER ON THIS PLATFORM';

  @override
  String get noteDesktopBody =>
      'The app runs here for testing, but automatic silencing is Android-only.';

  @override
  String get unsupportedDesktop =>
      'This platform has no ringer to control. Quiet Places runs, but automatic silencing is available on Android only.';

  @override
  String get unsupportedIos =>
      'iOS has no public API to silence the ringer. Quiet Places will notify you on arrival instead — set up a Shortcuts Focus automation for hands-free silencing.';

  @override
  String get notifChannelMomentName => 'Silenced / restored';

  @override
  String get notifChannelMomentDesc =>
      'When Quiet Places changes or restores your ringer.';

  @override
  String get notifChannelArrivalName => 'Quiet Place arrivals';

  @override
  String get notifChannelArrivalDesc =>
      'Reminders to silence your phone on arrival.';

  @override
  String notifSilencedTitle(String name, String behaviour) {
    return '$name — now $behaviour';
  }

  @override
  String get notifSilencedBody =>
      'Quiet Places will put your ringer back when you leave.';

  @override
  String notifRestoredTitle(String name) {
    return 'Left $name';
  }

  @override
  String get notifRestoredBody => 'Your ringer is back to how you had it.';

  @override
  String notifArrivalTitle(String name) {
    return 'You have arrived at $name';
  }

  @override
  String get notifArrivalBody =>
      'Silence your phone? (iOS cannot do this automatically — tap to open, or set up a Shortcuts Focus automation.)';

  @override
  String debugSimulate(String name) {
    return 'SIMULATE — $name';
  }

  @override
  String get debugSimulateEnter => 'Simulate ENTER';

  @override
  String get debugSimulateExit => 'Simulate EXIT';
}
