// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class LDe extends L {
  LDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Quiet Places';

  @override
  String get statePermissionTitle => 'Standortberechtigung ist aus';

  @override
  String get statePermissionBody =>
      'Entfernungen und Stummschalten brauchen sie.';

  @override
  String get statePermissionAction => 'ERTEILEN';

  @override
  String get stateServicesTitle => 'Standortdienste sind aus';

  @override
  String get stateServicesBody => 'Schalte sie ein, um Entfernungen zu sehen.';

  @override
  String get stateServicesAction => 'EINSTELLUNGEN ÖFFNEN';

  @override
  String get stateOfflineTitle => 'Keine Verbindung';

  @override
  String get stateOfflineBody => 'Gespeicherte Kartenkacheln werden angezeigt.';

  @override
  String get stateErrorAction => 'ERNEUT VERSUCHEN';

  @override
  String get stateLoading => 'Wird geladen';

  @override
  String get homeTitle => 'Deine\nRuheorte';

  @override
  String get homeAddCurrent => 'RUHEORT HINZUFÜGEN';

  @override
  String get homeAddCurrentSemantic =>
      'Ruheort hinzufügen, ausgehend von deinem Standort';

  @override
  String get homeLoadFailed => 'Deine Ruheorte konnten nicht geladen werden.';

  @override
  String get homeEmptyTitle => 'Noch nirgends\nRuhe';

  @override
  String get homeEmptyBody =>
      'Stell dich an einen Ort, an dem dein Handy still sein soll – Kino, Büro, Schlafzimmer – und sichere die Stelle.';

  @override
  String get homePaused => 'Stummschalten ist pausiert';

  @override
  String get navHistory => 'Verlauf';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get actionUndo => 'Rückgängig';

  @override
  String get actionRedo => 'Wiederholen';

  @override
  String get actionRetry => 'ERNEUT';

  @override
  String get actionSearch => 'Suchen';

  @override
  String get actionDismiss => 'Schließen';

  @override
  String get actionOpenSettings => 'EINSTELLUNGEN ÖFFNEN';

  @override
  String get actionAppSettings => 'APP-EINSTELLUNGEN';

  @override
  String get actionEnterManually => 'MANUELL EINGEBEN';

  @override
  String placeDeleted(String name) {
    return '„$name“ gelöscht';
  }

  @override
  String get undoLabel => 'RÜCKGÄNGIG';

  @override
  String undoSecondsRemaining(int seconds) {
    return '$seconds Sekunden zum Rückgängigmachen';
  }

  @override
  String placeEnabledSemantic(String name) {
    return '$name aktiviert';
  }

  @override
  String placeCardSemantic(String name, String behaviour, int radius) {
    return '$name, $behaviour, $radius Meter Radius';
  }

  @override
  String get semanticPositionUncertain => 'Position unsicher';

  @override
  String get semanticDisabled => 'deaktiviert';

  @override
  String get distanceUnavailable => 'Entfernung nicht verfügbar';

  @override
  String distanceInsideBy(String distance) {
    return '$distance innerhalb';
  }

  @override
  String distanceToEdge(String distance) {
    return '$distance bis zum Rand';
  }

  @override
  String get editorTitleNew => 'Neuer Ruheort';

  @override
  String get editorTitleEdit => 'Ruheort bearbeiten';

  @override
  String get editorSaveNew => 'RUHEORT SICHERN';

  @override
  String get editorSaveChanges => 'ÄNDERUNGEN SICHERN';

  @override
  String get editorFieldName => 'NAME';

  @override
  String get editorFieldRadius => 'RADIUS';

  @override
  String get editorFieldWhenInside => 'WENN DU DRIN BIST';

  @override
  String get editorUnitMetresShort => 'M';

  @override
  String get editorWaitingForPosition =>
      'Warte auf eine Position – oder setze die Nadel oben selbst.';

  @override
  String get editorPlacedManually => 'MANUELL GESETZT';

  @override
  String get editorLocating => 'ORTE…';

  @override
  String get editorImproving => 'VERFEINERE…';

  @override
  String get editorHintMap =>
      'Nadel ziehen zum Verschieben · lange auf die Karte tippen, um sie woanders zu setzen · oder eine Adresse suchen';

  @override
  String get editorHintDial =>
      'Zieh im Kreis, um die Nadel zu bewegen, oder schalte Karten ein, um sie visuell zu setzen';

  @override
  String get editorHintEditing =>
      'Zieh am Randgriff, um die Größe zu ändern, oder nutze den Regler unten';

  @override
  String get editorShowMap => 'KARTE ANZEIGEN';

  @override
  String get editorShowMapSemantic => 'Hier eine Karte anzeigen';

  @override
  String get editorSearchHint => 'Adresse oder Ort suchen';

  @override
  String get editorSearchSemantic => 'Nach einem Ort suchen';

  @override
  String editorRadiusSemantic(int radius) {
    return '$radius Meter Radius';
  }

  @override
  String editorRadiusUnreliable(int threshold) {
    return 'Unter $threshold m ist auf den meisten Geräten unzuverlässig – das System löst womöglich spät oder gar nicht aus.';
  }

  @override
  String get editorDiscardTitle => 'Änderungen verwerfen?';

  @override
  String get editorDiscardBody =>
      'Dieser Ruheort wurde nicht gesichert. Deine Änderungen gehen verloren.';

  @override
  String get editorDiscardKeep => 'WEITER BEARBEITEN';

  @override
  String get editorDiscardConfirm => 'VERWERFEN';

  @override
  String get editorDefaultName => 'Ort';

  @override
  String editorSuggestedName(int number) {
    return 'Ort $number';
  }

  @override
  String overlapStricterWins(String names, String winner) {
    return 'Überschneidet sich mit $names. Wo sie sich treffen, gewinnt $winner – die strengere Einstellung gilt.';
  }

  @override
  String overlapThisWins(String names, String behaviour) {
    return 'Überschneidet sich mit $names. Wo sie sich treffen, gilt weiterhin $behaviour – das ist die strengere Einstellung.';
  }

  @override
  String get behaviourVibrate => 'Vibration';

  @override
  String get behaviourSilent => 'Lautlos';

  @override
  String get behaviourDnd => 'Bitte nicht stören';

  @override
  String get behaviourDndShort => 'Nicht stören';

  @override
  String get positionServicesOff => 'Standortdienste sind aus.';

  @override
  String get positionPermissionNeeded =>
      'Quiet Places braucht die Standortberechtigung, um deinen Standort zu nutzen.';

  @override
  String get positionPermissionForever =>
      'Standortberechtigung ist dauerhaft verweigert.';

  @override
  String get positionTimeoutWithFix =>
      'Position ließ sich nicht schärfen – zeige die bisher beste.';

  @override
  String get positionTimeoutNoFix =>
      'Noch keine GPS-Position. Drinnen kann das dauern.';

  @override
  String get positionUnknownFailure =>
      'Dein Standort ließ sich nicht ermitteln.';

  @override
  String mapPreviewSemantic(int radius) {
    return 'Ruheort-Vorschau, $radius Meter Radius';
  }

  @override
  String get mapPreviewNoPosition => 'Ruheort-Vorschau, noch keine Position';

  @override
  String get mapCentreSemantic =>
      'Mittelpunkt des Ruheorts, zum Verschieben ziehen';

  @override
  String get mapHandleSemantic => 'Radiusgriff, zum Ändern der Größe ziehen';

  @override
  String get mapRecentre => 'Auf mich zentrieren';

  @override
  String get mapAttribution => '© OpenStreetMap-Mitwirkende';

  @override
  String get consentTitle => 'Karten einschalten';

  @override
  String get consentHeading => 'Nur dieser Teil\nnutzt das\nInternet';

  @override
  String get consentIntro =>
      'Alles andere in Quiet Places bleibt auf deinem Handy. Deine Ruheorte, ihre Namen, dein Verlauf – nichts davon wird je irgendwohin gesendet, mit oder ohne Karten.';

  @override
  String get consentSentTitle => 'WAS GESENDET WIRD';

  @override
  String get consentSentBody =>
      'Anfragen an OpenStreetMap für die Kartenkacheln auf deinem Bildschirm. Jede Anfrage ist eine Kachelnummer, nicht deine Koordinaten – aber bei Straßenzoom ist eine Kachel rund 600 m breit, die geladenen Kacheln verraten also ungefähr, wo der Ort liegt, den du bearbeitest. Das sagen wir dir lieber, als dass du es später herausfindest.';

  @override
  String get consentSearchTitle => 'SUCHE UND ORTSNAMEN';

  @override
  String get consentSearchBody =>
      'Wenn du nach einer Adresse suchst, wird dieser Text an den Suchdienst von OpenStreetMap gesendet. Wenn du die Nadel loslässt, werden ihre Koordinaten einmal gesendet, um einen Namensvorschlag zu holen – nur beim Loslassen, nie fortlaufend, und die Antwort wird wiederverwendet, wenn du sie erneut leicht verschiebst. Du kannst den Namen jederzeit selbst eintippen.';

  @override
  String get consentNeverTitle => 'WAS NIE GESENDET WIRD';

  @override
  String get consentNeverBody =>
      'Deine gesicherten Orte, ihre Namen, dein Ankunfts- und Abfahrtsverlauf, deine Einstellungen. Es gibt keine Analyse, keine Absturzberichte und kein Konto.';

  @override
  String get consentWhoTitle => 'WER ES EMPFÄNGT';

  @override
  String get consentWhoBody =>
      'Die Kachel- und Suchserver der OpenStreetMap Foundation. Sie sehen die Anfrage und deine IP-Adresse, wie jede Website. Wir senden einen User-Agent mit dem Namen dieser App, wie ihre Nutzungsrichtlinie es verlangt, und begrenzen die Rate.';

  @override
  String get consentOffTitle => 'DU KANNST ES WIEDER AUSSCHALTEN';

  @override
  String get consentOffBody =>
      'Karten lassen sich jederzeit in den Einstellungen wieder ausschalten und der Kartenspeicher leeren. Ohne Karten stellt die App überhaupt keine Netzwerkanfragen.';

  @override
  String get consentFallback =>
      'Ohne Karten funktioniert der Editor weiterhin: Du legst einen Ruheort dort an, wo du stehst, oder über eingetippte Koordinaten, und stellst den Radius am Rad ein.';

  @override
  String get consentAccept => 'KARTEN EINSCHALTEN';

  @override
  String get consentDecline => 'APP OFFLINE LASSEN';

  @override
  String get settingsSectionWhen => 'WANN GEHANDELT WIRD';

  @override
  String get settingsSectionLocation => 'STANDORT';

  @override
  String get settingsSectionMaps => 'KARTEN';

  @override
  String get settingsSectionDevice => 'DIESES GERÄT';

  @override
  String get settingsSectionLanguage => 'SPRACHE';

  @override
  String get settingsLanguageTitle => 'App-Sprache';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsSectionHistory => 'VERLAUF';

  @override
  String get settingsSectionUnits => 'EINHEITEN';

  @override
  String get settingsPauseTitle => 'Alles pausieren';

  @override
  String get settingsPauseBody =>
      'Solange das an ist, wird nichts stummgeschaltet';

  @override
  String get settingsSnoozeTitle => '1 Stunde aussetzen';

  @override
  String get settingsSnoozedTitle => 'Ausgesetzt';

  @override
  String get settingsSnoozeBody => 'Stummschalten vorübergehend stoppen';

  @override
  String settingsSnoozeUntil(String time) {
    return 'Läuft weiter um $time';
  }

  @override
  String get settingsSnoozeAction => 'AUSSETZEN';

  @override
  String get settingsCancel => 'ABBRECHEN';

  @override
  String get settingsWarmTitle => 'GPS warm halten';

  @override
  String get settingsWarmBody =>
      'Hält bei geöffneter App eine aktuelle Position bereit, damit das Hinzufügen eines Ruheorts sofort geht. Braucht etwas mehr Akku.';

  @override
  String get settingsManualTitle => 'Ruheort manuell hinzufügen';

  @override
  String get settingsManualBody =>
      'Setze eine Nadel irgendwo, wo du gerade nicht stehst';

  @override
  String get settingsOpen => 'ÖFFNEN';

  @override
  String get settingsMapsTitle => 'Kartenkacheln anzeigen';

  @override
  String get settingsMapsOn =>
      'Kartenkacheln werden von OpenStreetMap geladen, während du sie ansiehst. Sonst verlässt nichts dein Handy.';

  @override
  String get settingsMapsOff =>
      'Aus – die App stellt überhaupt keine Netzwerkanfragen.';

  @override
  String get settingsCacheTitle => 'Kartenspeicher';

  @override
  String settingsCacheBody(String size) {
    return '$size gespeichert · Kacheln werden wiederverwendet statt neu geladen';
  }

  @override
  String get settingsCacheChecking => 'Wird geprüft…';

  @override
  String get settingsClear => 'LEEREN';

  @override
  String get settingsCacheCleared => 'Kartenspeicher geleert';

  @override
  String get settingsRingerAvailable => 'Klingelton-Steuerung verfügbar';

  @override
  String get settingsRingerUnavailable =>
      'Klingelton-Steuerung nicht verfügbar';

  @override
  String get settingsRingerAvailableBody =>
      'Quiet Places kann auf diesem Gerät deinen Klingelton ändern.';

  @override
  String get settingsPermissionsTitle => 'Berechtigungs-Einrichtung';

  @override
  String get settingsPermissionsBody =>
      'Die geführten Prüfungen erneut durchlaufen';

  @override
  String get settingsReview => 'ANSEHEN';

  @override
  String get settingsClearLogTitle => 'Protokoll leeren';

  @override
  String get settingsClearLogBody =>
      'Entfernt jede aufgezeichnete Ankunft und Abfahrt';

  @override
  String get settingsHistoryCleared => 'Verlauf geleert';

  @override
  String get settingsUnitsTitle => 'Entfernungseinheiten';

  @override
  String get settingsUnitsMetric => 'Meter und Kilometer';

  @override
  String get settingsUnitsImperial => 'Fuß und Meilen';

  @override
  String get historyTitle => 'Verlauf';

  @override
  String get historyToday => 'HEUTE';

  @override
  String get historyYesterday => 'GESTERN';

  @override
  String get historyEmptyTitle => 'Bisher ist nichts passiert';

  @override
  String get historyEmptyBody =>
      'Jedes Mal, wenn Quiet Places deinen Klingelton stummschaltet oder wiederherstellt – oder sich dagegen entscheidet – steht es hier mit Begründung.';

  @override
  String get historyLoadFailed => 'Dein Verlauf konnte nicht geladen werden.';

  @override
  String get historySilenced => 'STUMMGESCHALTET';

  @override
  String get historyRestored => 'KLINGELTON WIEDERHERGESTELLT';

  @override
  String get historySwitched => 'MODUS GEWECHSELT';

  @override
  String get historyNotified => 'DICH BENACHRICHTIGT';

  @override
  String get historySkippedPaused => 'ÜBERSPRUNGEN – PAUSIERT';

  @override
  String get historySkippedDisabled => 'ÜBERSPRUNGEN – ORT AUS';

  @override
  String get historySkippedUnsupported => 'ÜBERSPRUNGEN – NICHT UNTERSTÜTZT';

  @override
  String get historySkippedOverride => 'ÜBERSPRUNGEN – DU HAST ES ÜBERSTIMMT';

  @override
  String get historyNoChange => 'KEINE ÄNDERUNG NÖTIG';

  @override
  String get historyError => 'FEHLER';

  @override
  String get momentSilenced => 'STUMMGESCHALTET';

  @override
  String get momentRestored => 'WIEDERHERGESTELLT';

  @override
  String momentNowBehaviour(String behaviour) {
    return 'JETZT $behaviour';
  }

  @override
  String get momentRestoreExplain =>
      'Beim Verlassen stellt dein Handy wieder her, wie du es hattest.';

  @override
  String momentSemanticApplied(String name, String behaviour) {
    return '$name: Handy auf $behaviour gestellt';
  }

  @override
  String momentSemanticRestored(String name) {
    return 'Klingelton beim Verlassen von $name wiederhergestellt';
  }

  @override
  String get onboardingTitle => 'Einrichtung';

  @override
  String get onboardingHeading => 'Ein paar Berechtigungen';

  @override
  String get onboardingIntro =>
      'Das Stummschalten passiert bei geschlossener App, deshalb musst du diese in Android ausdrücklich erteilen.';

  @override
  String get onboardingDone => 'FERTIG';

  @override
  String get onboardingSkip => 'ÜBERSPRINGEN';

  @override
  String get onboardingFinish => 'EINRICHTUNG ABSCHLIESSEN';

  @override
  String get onboardingFinishSemantic => 'Einrichtung abschließen';

  @override
  String get onboardingGranted => 'erteilt';

  @override
  String get onboardingNotGranted => 'nicht erteilt';

  @override
  String get onboardingGrant => 'Erteilen';

  @override
  String get onboardingOpenSettings => 'Einstellungen öffnen';

  @override
  String get onboardingRequest => 'Anfragen';

  @override
  String get permLocationTitle => 'Standort';

  @override
  String get permLocationBody =>
      'Um die Stelle zu erfassen, an der du stehst, und deine Ankunft zu erkennen.';

  @override
  String get permBackgroundTitle => 'Standort – „Immer zulassen“';

  @override
  String get permBackgroundBody =>
      'Ruheorte lösen im Hintergrund nur mit dauerhaftem Zugriff aus. Ohne ihn funktioniert das Stummschalten nur bei geöffneter App.';

  @override
  String get permDndTitle => 'Zugriff auf „Bitte nicht stören“';

  @override
  String get permDndBody =>
      'Nötig, um zwischen Lautlos und Bitte nicht stören zu wechseln. Das kann kein normales Pop-up sein – du erteilst es auf einem eigenen Systembildschirm.';

  @override
  String get permDndAction => 'Einstellungen für Bitte nicht stören öffnen';

  @override
  String get permNotificationsTitle => 'Benachrichtigungen';

  @override
  String get permNotificationsBodyIos =>
      'iOS kann deinen Klingelton nicht automatisch stummschalten. Stattdessen benachrichtigen wir dich bei der Ankunft, damit du es selbst tun kannst (oder eine Fokus-Automation in Kurzbefehlen auslöst).';

  @override
  String get permNotificationsBodyAndroid =>
      'Für den kurzen Vordergrundhinweis, während dein Klingelton geändert wird.';

  @override
  String get permBatteryTitle => 'Akku-Optimierung ignorieren';

  @override
  String get permBatteryBody =>
      'Aggressive Akkusparfunktionen können die Hintergrundzustellung abwürgen. Eine Ausnahme für Quiet Places hält es zuverlässig.';

  @override
  String get noteOemTitle => 'BEI XIAOMI / OPPO / VIVO / SAMSUNG';

  @override
  String get noteOemBody =>
      'Diese Marken haben eigene Regler für „Autostart“ oder „geschützte Apps“, die Hintergrund-Apps stoppen. Suche Quiet Places in den Akku- oder App-Einstellungen deines Handys und aktiviere Autostart bzw. Hintergrundaktivität zulassen, sonst löst Quiet Places womöglich nicht mehr aus.';

  @override
  String get noteIosTitle => 'IOS KANN NICHT AUTOMATISCH STUMMSCHALTEN';

  @override
  String get noteIosBody =>
      'Apple bietet keine Schnittstelle, um den Klingelton zu ändern. Für eine freihändige Einrichtung öffne Kurzbefehle → Automation → erstelle eine Standort-Automation für denselben Ort und lass sie einen Fokus einschalten. Quiet Places benachrichtigt dich zusätzlich weiterhin bei der Ankunft.';

  @override
  String get noteDesktopTitle =>
      'AUF DIESER PLATTFORM GIBT ES KEINEN KLINGELTON';

  @override
  String get noteDesktopBody =>
      'Die App läuft hier zum Testen, aber automatisches Stummschalten gibt es nur unter Android.';

  @override
  String get unsupportedDesktop =>
      'Diese Plattform hat keinen Klingelton zum Steuern. Quiet Places läuft hier, aber automatisches Stummschalten gibt es nur unter Android.';

  @override
  String get unsupportedIos =>
      'iOS bietet keine öffentliche Schnittstelle, um den Klingelton stummzuschalten. Quiet Places benachrichtigt dich stattdessen bei der Ankunft – richte eine Fokus-Automation in Kurzbefehlen ein, damit es freihändig geht.';

  @override
  String get notifChannelMomentName => 'Stummgeschaltet / wiederhergestellt';

  @override
  String get notifChannelMomentDesc =>
      'Wenn Quiet Places deinen Klingelton ändert oder wiederherstellt.';

  @override
  String get notifChannelArrivalName => 'Ankünfte an Ruheorten';

  @override
  String get notifChannelArrivalDesc =>
      'Erinnerungen, dein Handy bei der Ankunft stummzuschalten.';

  @override
  String notifSilencedTitle(String name, String behaviour) {
    return '$name — jetzt $behaviour';
  }

  @override
  String get notifSilencedBody =>
      'Quiet Places stellt deinen Klingelton beim Verlassen wieder her.';

  @override
  String notifRestoredTitle(String name) {
    return '$name verlassen';
  }

  @override
  String get notifRestoredBody =>
      'Dein Klingelton ist wieder so, wie du ihn hattest.';

  @override
  String notifArrivalTitle(String name) {
    return 'Du bist bei $name angekommen';
  }

  @override
  String get notifArrivalBody =>
      'Handy stummschalten? (iOS kann das nicht automatisch – tippe zum Öffnen oder richte eine Fokus-Automation in Kurzbefehlen ein.)';

  @override
  String debugSimulate(String name) {
    return 'SIMULIEREN – $name';
  }

  @override
  String get debugSimulateEnter => 'EINTRITT simulieren';

  @override
  String get debugSimulateExit => 'AUSTRITT simulieren';
}
