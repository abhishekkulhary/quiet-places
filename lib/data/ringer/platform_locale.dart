import 'dart:ui' show Locale, PlatformDispatcher;

import '../../l10n/app_localizations.dart';

/// The user's chosen language, or null to follow the device.
///
/// Cached per isolate rather than read from the database on every call, because
/// the callers include synchronous getters. Each isolate is responsible for
/// seeding it from settings: the UI does so as the settings stream emits, and
/// the geofence background isolate does so before it announces anything. An
/// isolate that never seeds it simply follows the device, which is the same
/// behaviour as before the setting existed.
String? _preferredLanguage;

/// Records the user's language choice for [platformL] in this isolate.
void setPreferredLanguage(String? code) => _preferredLanguage = code;

/// The languages offered in Settings. Null is "follow the device".
///
/// Deliberately a hand-maintained list rather than
/// `L.supportedLocales`: that includes every locale the generator produces,
/// and the picker needs a name written *in* each language, which the
/// localisations cannot supply for a language the user is not currently using.
const supportedLanguages = <({String code, String name})>[
  (code: 'en', name: 'English'),
  (code: 'de', name: 'Deutsch'),
];

/// Translations for strings produced outside the widget tree.
///
/// The ringer controllers and the notification service both run without a
/// BuildContext -- the latter from the geofence background isolate -- so they
/// cannot use `L.of(context)`. The generated lookup is synchronous and takes a
/// plain Locale, and falls back to English for anything we do not ship.
L platformL() {
  final code =
      _preferredLanguage ?? PlatformDispatcher.instance.locale.languageCode;
  try {
    return lookupL(Locale(code));
  } catch (_) {
    return lookupL(const Locale('en'));
  }
}
