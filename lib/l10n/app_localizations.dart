import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Application name, shown in the home header
  ///
  /// In en, this message translates to:
  /// **'Quiet Places'**
  String get appName;

  /// No description provided for @statePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission is off'**
  String get statePermissionTitle;

  /// No description provided for @statePermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Distances and silencing need it.'**
  String get statePermissionBody;

  /// No description provided for @statePermissionAction.
  ///
  /// In en, this message translates to:
  /// **'GRANT'**
  String get statePermissionAction;

  /// No description provided for @stateServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Location services are off'**
  String get stateServicesTitle;

  /// No description provided for @stateServicesBody.
  ///
  /// In en, this message translates to:
  /// **'Turn them on to see distances.'**
  String get stateServicesBody;

  /// No description provided for @stateServicesAction.
  ///
  /// In en, this message translates to:
  /// **'OPEN SETTINGS'**
  String get stateServicesAction;

  /// No description provided for @stateOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get stateOfflineTitle;

  /// No description provided for @stateOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Showing saved map squares.'**
  String get stateOfflineBody;

  /// No description provided for @stateErrorAction.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get stateErrorAction;

  /// No description provided for @stateLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get stateLoading;

  /// Home screen display heading; the line break is intentional
  ///
  /// In en, this message translates to:
  /// **'Your quiet\nplaces'**
  String get homeTitle;

  /// Primary action. Deliberately not 'add current location' — it opens at where you are, but the editor lets you place it anywhere.
  ///
  /// In en, this message translates to:
  /// **'ADD A QUIET PLACE'**
  String get homeAddCurrent;

  /// No description provided for @homeAddCurrentSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add a Quiet Place, starting from where you are'**
  String get homeAddCurrentSemantic;

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your Quiet Places.'**
  String get homeLoadFailed;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nowhere quiet\nyet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Stand somewhere your phone should hush — a cinema, an office, a bedroom — and save the spot.'**
  String get homeEmptyBody;

  /// No description provided for @homePaused.
  ///
  /// In en, this message translates to:
  /// **'Silencing is paused'**
  String get homePaused;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @actionRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get actionRedo;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get actionRetry;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @actionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get actionDismiss;

  /// No description provided for @actionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'OPEN SETTINGS'**
  String get actionOpenSettings;

  /// No description provided for @actionAppSettings.
  ///
  /// In en, this message translates to:
  /// **'APP SETTINGS'**
  String get actionAppSettings;

  /// No description provided for @actionEnterManually.
  ///
  /// In en, this message translates to:
  /// **'ENTER MANUALLY'**
  String get actionEnterManually;

  /// No description provided for @placeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\"'**
  String placeDeleted(String name);

  /// No description provided for @undoLabel.
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get undoLabel;

  /// No description provided for @undoSecondsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds to undo'**
  String undoSecondsRemaining(int seconds);

  /// No description provided for @placeEnabledSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name} enabled'**
  String placeEnabledSemantic(String name);

  /// No description provided for @placeCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name}, {behaviour}, {radius} metre radius'**
  String placeCardSemantic(String name, String behaviour, int radius);

  /// No description provided for @semanticPositionUncertain.
  ///
  /// In en, this message translates to:
  /// **'position uncertain'**
  String get semanticPositionUncertain;

  /// No description provided for @semanticDisabled.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get semanticDisabled;

  /// No description provided for @distanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Distance unavailable'**
  String get distanceUnavailable;

  /// No description provided for @distanceInsideBy.
  ///
  /// In en, this message translates to:
  /// **'inside by {distance}'**
  String distanceInsideBy(String distance);

  /// No description provided for @distanceToEdge.
  ///
  /// In en, this message translates to:
  /// **'{distance} to edge'**
  String distanceToEdge(String distance);

  /// No description provided for @editorTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New Quiet Place'**
  String get editorTitleNew;

  /// No description provided for @editorTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Quiet Place'**
  String get editorTitleEdit;

  /// No description provided for @editorSaveNew.
  ///
  /// In en, this message translates to:
  /// **'SAVE QUIET PLACE'**
  String get editorSaveNew;

  /// No description provided for @editorSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get editorSaveChanges;

  /// No description provided for @editorFieldName.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get editorFieldName;

  /// No description provided for @editorFieldRadius.
  ///
  /// In en, this message translates to:
  /// **'RADIUS'**
  String get editorFieldRadius;

  /// No description provided for @editorFieldWhenInside.
  ///
  /// In en, this message translates to:
  /// **'WHEN INSIDE'**
  String get editorFieldWhenInside;

  /// No description provided for @editorUnitMetresShort.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get editorUnitMetresShort;

  /// No description provided for @editorWaitingForPosition.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a position — or place the pin yourself above.'**
  String get editorWaitingForPosition;

  /// No description provided for @editorPlacedManually.
  ///
  /// In en, this message translates to:
  /// **'PLACED MANUALLY'**
  String get editorPlacedManually;

  /// No description provided for @editorLocating.
  ///
  /// In en, this message translates to:
  /// **'LOCATING…'**
  String get editorLocating;

  /// No description provided for @editorImproving.
  ///
  /// In en, this message translates to:
  /// **'IMPROVING…'**
  String get editorImproving;

  /// No description provided for @editorHintMap.
  ///
  /// In en, this message translates to:
  /// **'Drag the pin to move it · long-press the map to place it somewhere else · or search an address'**
  String get editorHintMap;

  /// No description provided for @editorHintDial.
  ///
  /// In en, this message translates to:
  /// **'Drag inside the circle to move the pin, or turn on maps to place it visually'**
  String get editorHintDial;

  /// No description provided for @editorHintEditing.
  ///
  /// In en, this message translates to:
  /// **'Drag the edge handle to resize, or use the slider below'**
  String get editorHintEditing;

  /// No description provided for @editorShowMap.
  ///
  /// In en, this message translates to:
  /// **'SHOW A MAP'**
  String get editorShowMap;

  /// No description provided for @editorShowMapSemantic.
  ///
  /// In en, this message translates to:
  /// **'Show a map here'**
  String get editorShowMapSemantic;

  /// No description provided for @editorSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search an address or place'**
  String get editorSearchHint;

  /// No description provided for @editorSearchSemantic.
  ///
  /// In en, this message translates to:
  /// **'Search for a place'**
  String get editorSearchSemantic;

  /// No description provided for @editorRadiusSemantic.
  ///
  /// In en, this message translates to:
  /// **'{radius} metres radius'**
  String editorRadiusSemantic(int radius);

  /// No description provided for @editorRadiusUnreliable.
  ///
  /// In en, this message translates to:
  /// **'Under {threshold} m is unreliable on most hardware — the OS may fire late, or not at all.'**
  String editorRadiusUnreliable(int threshold);

  /// No description provided for @editorDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editorDiscardTitle;

  /// No description provided for @editorDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'This Quiet Place has not been saved. Your edits will be lost.'**
  String get editorDiscardBody;

  /// No description provided for @editorDiscardKeep.
  ///
  /// In en, this message translates to:
  /// **'KEEP EDITING'**
  String get editorDiscardKeep;

  /// No description provided for @editorDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'DISCARD'**
  String get editorDiscardConfirm;

  /// No description provided for @editorDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get editorDefaultName;

  /// No description provided for @editorSuggestedName.
  ///
  /// In en, this message translates to:
  /// **'Location {number}'**
  String editorSuggestedName(int number);

  /// No description provided for @overlapStricterWins.
  ///
  /// In en, this message translates to:
  /// **'This overlaps {names}. Where they meet, {winner} wins — the stricter setting applies.'**
  String overlapStricterWins(String names, String winner);

  /// No description provided for @overlapThisWins.
  ///
  /// In en, this message translates to:
  /// **'This overlaps {names}. Where they meet, {behaviour} still applies — it is the stricter setting.'**
  String overlapThisWins(String names, String behaviour);

  /// No description provided for @behaviourVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get behaviourVibrate;

  /// No description provided for @behaviourSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get behaviourSilent;

  /// No description provided for @behaviourDnd.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb'**
  String get behaviourDnd;

  /// No description provided for @behaviourDndShort.
  ///
  /// In en, this message translates to:
  /// **'DND'**
  String get behaviourDndShort;

  /// No description provided for @positionServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are off.'**
  String get positionServicesOff;

  /// No description provided for @positionPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Quiet Places needs location permission to use where you are.'**
  String get positionPermissionNeeded;

  /// No description provided for @positionPermissionForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied.'**
  String get positionPermissionForever;

  /// No description provided for @positionTimeoutWithFix.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sharpen the fix — showing the best so far.'**
  String get positionTimeoutWithFix;

  /// No description provided for @positionTimeoutNoFix.
  ///
  /// In en, this message translates to:
  /// **'No GPS fix yet. Indoors this can take a while.'**
  String get positionTimeoutNoFix;

  /// No description provided for @positionUnknownFailure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t work out where you are.'**
  String get positionUnknownFailure;

  /// No description provided for @mapPreviewSemantic.
  ///
  /// In en, this message translates to:
  /// **'Quiet Place preview, {radius} metre radius'**
  String mapPreviewSemantic(int radius);

  /// No description provided for @mapPreviewNoPosition.
  ///
  /// In en, this message translates to:
  /// **'Quiet Place preview, no position yet'**
  String get mapPreviewNoPosition;

  /// No description provided for @mapCentreSemantic.
  ///
  /// In en, this message translates to:
  /// **'Quiet Place centre, drag to move'**
  String get mapCentreSemantic;

  /// No description provided for @mapHandleSemantic.
  ///
  /// In en, this message translates to:
  /// **'Radius handle, drag to resize'**
  String get mapHandleSemantic;

  /// No description provided for @mapRecentre.
  ///
  /// In en, this message translates to:
  /// **'Recentre on me'**
  String get mapRecentre;

  /// No description provided for @mapAttribution.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get mapAttribution;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on maps'**
  String get consentTitle;

  /// No description provided for @consentHeading.
  ///
  /// In en, this message translates to:
  /// **'This is the only\npart that uses\nthe internet'**
  String get consentHeading;

  /// No description provided for @consentIntro.
  ///
  /// In en, this message translates to:
  /// **'Everything else in Quiet Places stays on your phone. Your Quiet Places, their names, your history — none of it is ever sent anywhere, with or without maps.'**
  String get consentIntro;

  /// No description provided for @consentSentTitle.
  ///
  /// In en, this message translates to:
  /// **'WHAT GETS SENT'**
  String get consentSentTitle;

  /// No description provided for @consentSentBody.
  ///
  /// In en, this message translates to:
  /// **'Requests to OpenStreetMap for the map squares on your screen. Each request is a map square number, not your coordinates — but at street zoom a square is about 600 m across, so the squares you load do reveal roughly where the place you are editing is. We would rather say that than let you find out later.'**
  String get consentSentBody;

  /// No description provided for @consentSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'SEARCH AND PLACE NAMES'**
  String get consentSearchTitle;

  /// No description provided for @consentSearchBody.
  ///
  /// In en, this message translates to:
  /// **'If you search for an address, that text is sent to OpenStreetMap\'s search service. When you finish moving the pin, its coordinates are sent once to look up a name to suggest — only when you let go, never continuously, and the answer is reused if you nudge it again. You can always type the name yourself instead.'**
  String get consentSearchBody;

  /// No description provided for @consentNeverTitle.
  ///
  /// In en, this message translates to:
  /// **'WHAT NEVER GETS SENT'**
  String get consentNeverTitle;

  /// No description provided for @consentNeverBody.
  ///
  /// In en, this message translates to:
  /// **'Your saved places, their names, your entry and exit history, your settings. There is no analytics, no crash reporting, and no account.'**
  String get consentNeverBody;

  /// No description provided for @consentWhoTitle.
  ///
  /// In en, this message translates to:
  /// **'WHO RECEIVES IT'**
  String get consentWhoTitle;

  /// No description provided for @consentWhoBody.
  ///
  /// In en, this message translates to:
  /// **'The OpenStreetMap Foundation\'s tile and search servers. They see the request and your IP address, as any website would. We send a User-Agent naming this app, which their usage policy requires, and we rate-limit what we send.'**
  String get consentWhoBody;

  /// No description provided for @consentOffTitle.
  ///
  /// In en, this message translates to:
  /// **'YOU CAN TURN IT BACK OFF'**
  String get consentOffTitle;

  /// No description provided for @consentOffBody.
  ///
  /// In en, this message translates to:
  /// **'Maps can be switched off again in Settings at any time, and the map cache cleared. With maps off the app makes no network requests at all.'**
  String get consentOffBody;

  /// No description provided for @consentFallback.
  ///
  /// In en, this message translates to:
  /// **'Without maps, the editor still works: you place a Quiet Place from where you are standing, or by typing coordinates, and set the radius on the dial.'**
  String get consentFallback;

  /// No description provided for @consentAccept.
  ///
  /// In en, this message translates to:
  /// **'TURN ON MAPS'**
  String get consentAccept;

  /// No description provided for @consentDecline.
  ///
  /// In en, this message translates to:
  /// **'KEEP THE APP OFFLINE'**
  String get consentDecline;

  /// No description provided for @settingsSectionWhen.
  ///
  /// In en, this message translates to:
  /// **'WHEN TO ACT'**
  String get settingsSectionWhen;

  /// No description provided for @settingsSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get settingsSectionLocation;

  /// No description provided for @settingsSectionMaps.
  ///
  /// In en, this message translates to:
  /// **'MAPS'**
  String get settingsSectionMaps;

  /// No description provided for @settingsSectionDevice.
  ///
  /// In en, this message translates to:
  /// **'THIS DEVICE'**
  String get settingsSectionDevice;

  /// Settings section heading for the language picker.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get settingsSectionLanguage;

  /// Label for the language choice.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguageTitle;

  /// Language option meaning follow the device language.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsSectionHistory.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get settingsSectionHistory;

  /// No description provided for @settingsSectionUnits.
  ///
  /// In en, this message translates to:
  /// **'UNITS'**
  String get settingsSectionUnits;

  /// No description provided for @settingsPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause everything'**
  String get settingsPauseTitle;

  /// No description provided for @settingsPauseBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is silenced while this is on'**
  String get settingsPauseBody;

  /// No description provided for @settingsSnoozeTitle.
  ///
  /// In en, this message translates to:
  /// **'Snooze for 1 hour'**
  String get settingsSnoozeTitle;

  /// No description provided for @settingsSnoozedTitle.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get settingsSnoozedTitle;

  /// No description provided for @settingsSnoozeBody.
  ///
  /// In en, this message translates to:
  /// **'Temporarily stop silencing'**
  String get settingsSnoozeBody;

  /// No description provided for @settingsSnoozeUntil.
  ///
  /// In en, this message translates to:
  /// **'Resumes at {time}'**
  String settingsSnoozeUntil(String time);

  /// No description provided for @settingsSnoozeAction.
  ///
  /// In en, this message translates to:
  /// **'SNOOZE'**
  String get settingsSnoozeAction;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get settingsCancel;

  /// No description provided for @settingsWarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep GPS warm'**
  String get settingsWarmTitle;

  /// No description provided for @settingsWarmBody.
  ///
  /// In en, this message translates to:
  /// **'Holds a recent fix while the app is open so adding a Quiet Place is instant. Uses a little more battery.'**
  String get settingsWarmBody;

  /// No description provided for @settingsManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a Quiet Place manually'**
  String get settingsManualTitle;

  /// No description provided for @settingsManualBody.
  ///
  /// In en, this message translates to:
  /// **'Drop a pin somewhere you are not standing'**
  String get settingsManualBody;

  /// No description provided for @settingsOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get settingsOpen;

  /// No description provided for @settingsMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Show map tiles'**
  String get settingsMapsTitle;

  /// No description provided for @settingsMapsOn.
  ///
  /// In en, this message translates to:
  /// **'Map squares are fetched from OpenStreetMap as you look at them. Nothing else leaves your phone.'**
  String get settingsMapsOn;

  /// No description provided for @settingsMapsOff.
  ///
  /// In en, this message translates to:
  /// **'Off — the app makes no network requests at all.'**
  String get settingsMapsOff;

  /// No description provided for @settingsCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Map cache'**
  String get settingsCacheTitle;

  /// No description provided for @settingsCacheBody.
  ///
  /// In en, this message translates to:
  /// **'{size} stored · tiles are reused instead of re-downloaded'**
  String settingsCacheBody(String size);

  /// No description provided for @settingsCacheChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get settingsCacheChecking;

  /// No description provided for @settingsClear.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get settingsClear;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Map cache cleared'**
  String get settingsCacheCleared;

  /// No description provided for @settingsRingerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Ringer control available'**
  String get settingsRingerAvailable;

  /// No description provided for @settingsRingerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Ringer control unavailable'**
  String get settingsRingerUnavailable;

  /// No description provided for @settingsRingerAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'Quiet Places can change your ringer on this device.'**
  String get settingsRingerAvailableBody;

  /// No description provided for @settingsPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission setup'**
  String get settingsPermissionsTitle;

  /// No description provided for @settingsPermissionsBody.
  ///
  /// In en, this message translates to:
  /// **'Re-run the guided checks'**
  String get settingsPermissionsBody;

  /// No description provided for @settingsReview.
  ///
  /// In en, this message translates to:
  /// **'REVIEW'**
  String get settingsReview;

  /// No description provided for @settingsClearLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear the log'**
  String get settingsClearLogTitle;

  /// No description provided for @settingsClearLogBody.
  ///
  /// In en, this message translates to:
  /// **'Removes every recorded entry and exit'**
  String get settingsClearLogBody;

  /// No description provided for @settingsHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get settingsHistoryCleared;

  /// No description provided for @settingsUnitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Distance units'**
  String get settingsUnitsTitle;

  /// No description provided for @settingsUnitsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metres and kilometres'**
  String get settingsUnitsMetric;

  /// No description provided for @settingsUnitsImperial.
  ///
  /// In en, this message translates to:
  /// **'Feet and miles'**
  String get settingsUnitsImperial;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get historyToday;

  /// No description provided for @historyYesterday.
  ///
  /// In en, this message translates to:
  /// **'YESTERDAY'**
  String get historyYesterday;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing has happened yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Every time Quiet Places silences or restores your ringer — or decides not to — it will be listed here with the reason.'**
  String get historyEmptyBody;

  /// No description provided for @historyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your history.'**
  String get historyLoadFailed;

  /// No description provided for @historySilenced.
  ///
  /// In en, this message translates to:
  /// **'SILENCED'**
  String get historySilenced;

  /// No description provided for @historyRestored.
  ///
  /// In en, this message translates to:
  /// **'RINGER RESTORED'**
  String get historyRestored;

  /// No description provided for @historySwitched.
  ///
  /// In en, this message translates to:
  /// **'SWITCHED MODE'**
  String get historySwitched;

  /// No description provided for @historyNotified.
  ///
  /// In en, this message translates to:
  /// **'NOTIFIED YOU'**
  String get historyNotified;

  /// No description provided for @historySkippedPaused.
  ///
  /// In en, this message translates to:
  /// **'SKIPPED — PAUSED'**
  String get historySkippedPaused;

  /// No description provided for @historySkippedDisabled.
  ///
  /// In en, this message translates to:
  /// **'SKIPPED — PLACE OFF'**
  String get historySkippedDisabled;

  /// No description provided for @historySkippedUnsupported.
  ///
  /// In en, this message translates to:
  /// **'SKIPPED — UNSUPPORTED'**
  String get historySkippedUnsupported;

  /// No description provided for @historySkippedOverride.
  ///
  /// In en, this message translates to:
  /// **'SKIPPED — YOU OVERRODE IT'**
  String get historySkippedOverride;

  /// No description provided for @historyNoChange.
  ///
  /// In en, this message translates to:
  /// **'NO CHANGE NEEDED'**
  String get historyNoChange;

  /// No description provided for @historyError.
  ///
  /// In en, this message translates to:
  /// **'ERROR'**
  String get historyError;

  /// No description provided for @momentSilenced.
  ///
  /// In en, this message translates to:
  /// **'SILENCED'**
  String get momentSilenced;

  /// No description provided for @momentRestored.
  ///
  /// In en, this message translates to:
  /// **'RESTORED'**
  String get momentRestored;

  /// No description provided for @momentNowBehaviour.
  ///
  /// In en, this message translates to:
  /// **'NOW {behaviour}'**
  String momentNowBehaviour(String behaviour);

  /// No description provided for @momentRestoreExplain.
  ///
  /// In en, this message translates to:
  /// **'Your phone will go back to how you had it when you leave.'**
  String get momentRestoreExplain;

  /// No description provided for @momentSemanticApplied.
  ///
  /// In en, this message translates to:
  /// **'{name}: phone set to {behaviour}'**
  String momentSemanticApplied(String name, String behaviour);

  /// No description provided for @momentSemanticRestored.
  ///
  /// In en, this message translates to:
  /// **'Ringer restored on leaving {name}'**
  String momentSemanticRestored(String name);

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get onboardingTitle;

  /// No description provided for @onboardingHeading.
  ///
  /// In en, this message translates to:
  /// **'A few permissions'**
  String get onboardingHeading;

  /// No description provided for @onboardingIntro.
  ///
  /// In en, this message translates to:
  /// **'Silencing happens while the app is closed, so Android needs you to grant these explicitly.'**
  String get onboardingIntro;

  /// No description provided for @onboardingDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get onboardingDone;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get onboardingSkip;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'FINISH SETUP'**
  String get onboardingFinish;

  /// No description provided for @onboardingFinishSemantic.
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get onboardingFinishSemantic;

  /// No description provided for @onboardingGranted.
  ///
  /// In en, this message translates to:
  /// **'granted'**
  String get onboardingGranted;

  /// No description provided for @onboardingNotGranted.
  ///
  /// In en, this message translates to:
  /// **'not granted'**
  String get onboardingNotGranted;

  /// No description provided for @onboardingGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get onboardingGrant;

  /// No description provided for @onboardingOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get onboardingOpenSettings;

  /// No description provided for @onboardingRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get onboardingRequest;

  /// No description provided for @permLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permLocationTitle;

  /// No description provided for @permLocationBody.
  ///
  /// In en, this message translates to:
  /// **'To capture the spot you\'re standing in and detect when you arrive.'**
  String get permLocationBody;

  /// No description provided for @permBackgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Location — \"Allow all the time\"'**
  String get permBackgroundTitle;

  /// No description provided for @permBackgroundBody.
  ///
  /// In en, this message translates to:
  /// **'Quiet Places only fire in the background with all-the-time access. Denying this means silencing works only while the app is open.'**
  String get permBackgroundBody;

  /// No description provided for @permDndTitle.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb access'**
  String get permDndTitle;

  /// No description provided for @permDndBody.
  ///
  /// In en, this message translates to:
  /// **'Required to switch silent/DND modes. This one can\'t be a normal popup — you grant it on a dedicated system screen.'**
  String get permDndBody;

  /// No description provided for @permDndAction.
  ///
  /// In en, this message translates to:
  /// **'Open DND settings'**
  String get permDndAction;

  /// No description provided for @permNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permNotificationsTitle;

  /// No description provided for @permNotificationsBodyIos.
  ///
  /// In en, this message translates to:
  /// **'iOS can\'t silence your ringer automatically. Instead we\'ll notify you on arrival so you can do it (or trigger a Shortcuts Focus automation).'**
  String get permNotificationsBodyIos;

  /// No description provided for @permNotificationsBodyAndroid.
  ///
  /// In en, this message translates to:
  /// **'For the brief foreground notice while changing your ringer.'**
  String get permNotificationsBodyAndroid;

  /// No description provided for @permBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Ignore battery optimisation'**
  String get permBatteryTitle;

  /// No description provided for @permBatteryBody.
  ///
  /// In en, this message translates to:
  /// **'Aggressive battery savers can kill background delivery. Exempting Quiet Places keeps it reliable.'**
  String get permBatteryBody;

  /// No description provided for @noteOemTitle.
  ///
  /// In en, this message translates to:
  /// **'ON XIAOMI / OPPO / VIVO / SAMSUNG'**
  String get noteOemTitle;

  /// No description provided for @noteOemBody.
  ///
  /// In en, this message translates to:
  /// **'These brands add their own \"autostart\" or \"protected apps\" controls that stop background apps. Find Quiet Places in your phone\'s Battery or App-management settings and enable Autostart / Allow background activity, or Quiet Places may stop firing.'**
  String get noteOemBody;

  /// No description provided for @noteIosTitle.
  ///
  /// In en, this message translates to:
  /// **'IOS CANNOT SILENCE AUTOMATICALLY'**
  String get noteIosTitle;

  /// No description provided for @noteIosBody.
  ///
  /// In en, this message translates to:
  /// **'Apple provides no API to change the ringer. For a hands-free setup, open Shortcuts → Automation → Create a Location automation for the same place and set it to turn on a Focus mode. Quiet Places still notifies you on arrival as a backup.'**
  String get noteIosBody;

  /// No description provided for @noteDesktopTitle.
  ///
  /// In en, this message translates to:
  /// **'NO RINGER ON THIS PLATFORM'**
  String get noteDesktopTitle;

  /// No description provided for @noteDesktopBody.
  ///
  /// In en, this message translates to:
  /// **'The app runs here for testing, but automatic silencing is Android-only.'**
  String get noteDesktopBody;

  /// Why the ringer cannot be controlled on desktop/web.
  ///
  /// In en, this message translates to:
  /// **'This platform has no ringer to control. Quiet Places runs, but automatic silencing is available on Android only.'**
  String get unsupportedDesktop;

  /// Why the ringer cannot be controlled on iOS.
  ///
  /// In en, this message translates to:
  /// **'iOS has no public API to silence the ringer. Quiet Places will notify you on arrival instead — set up a Shortcuts Focus automation for hands-free silencing.'**
  String get unsupportedIos;

  /// Android notification channel name for silence/restore notices.
  ///
  /// In en, this message translates to:
  /// **'Silenced / restored'**
  String get notifChannelMomentName;

  /// Android notification channel description.
  ///
  /// In en, this message translates to:
  /// **'When Quiet Places changes or restores your ringer.'**
  String get notifChannelMomentDesc;

  /// Android notification channel name for arrival prompts.
  ///
  /// In en, this message translates to:
  /// **'Quiet Place arrivals'**
  String get notifChannelArrivalName;

  /// Android notification channel description for arrival prompts.
  ///
  /// In en, this message translates to:
  /// **'Reminders to silence your phone on arrival.'**
  String get notifChannelArrivalDesc;

  /// No description provided for @notifSilencedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} — now {behaviour}'**
  String notifSilencedTitle(String name, String behaviour);

  /// Body of the silenced notification.
  ///
  /// In en, this message translates to:
  /// **'Quiet Places will put your ringer back when you leave.'**
  String get notifSilencedBody;

  /// No description provided for @notifRestoredTitle.
  ///
  /// In en, this message translates to:
  /// **'Left {name}'**
  String notifRestoredTitle(String name);

  /// Body of the restored notification.
  ///
  /// In en, this message translates to:
  /// **'Your ringer is back to how you had it.'**
  String get notifRestoredBody;

  /// No description provided for @notifArrivalTitle.
  ///
  /// In en, this message translates to:
  /// **'You have arrived at {name}'**
  String notifArrivalTitle(String name);

  /// Body of the iOS arrival prompt.
  ///
  /// In en, this message translates to:
  /// **'Silence your phone? (iOS cannot do this automatically — tap to open, or set up a Shortcuts Focus automation.)'**
  String get notifArrivalBody;

  /// No description provided for @debugSimulate.
  ///
  /// In en, this message translates to:
  /// **'SIMULATE — {name}'**
  String debugSimulate(String name);

  /// No description provided for @debugSimulateEnter.
  ///
  /// In en, this message translates to:
  /// **'Simulate ENTER'**
  String get debugSimulateEnter;

  /// No description provided for @debugSimulateExit.
  ///
  /// In en, this message translates to:
  /// **'Simulate EXIT'**
  String get debugSimulateExit;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return LDe();
    case 'en':
      return LEn();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
