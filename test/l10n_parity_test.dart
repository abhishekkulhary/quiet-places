import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps every translation in step with the English template.
///
/// A missing key silently falls back to English at runtime, and a placeholder
/// typo throws only on the screen that uses it — both are invisible until a
/// German-speaking user hits them.
void main() {
  final dir = Directory('lib/l10n');
  final template =
      jsonDecode(File('${dir.path}/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
  final englishKeys =
      template.keys.where((k) => !k.startsWith('@')).toSet();

  final translations = dir
      .listSync()
      .whereType<File>()
      .where((f) =>
          f.path.endsWith('.arb') && !f.path.endsWith('app_en.arb'))
      .toList();

  Set<String> placeholders(String s) =>
      RegExp(r'\{(\w+)\}').allMatches(s).map((m) => m.group(1)!).toSet();

  test('there is at least one translation to check', () {
    expect(translations, isNotEmpty);
  });

  for (final file in translations) {
    final name = file.uri.pathSegments.last;
    final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final keys = arb.keys.where((k) => !k.startsWith('@')).toSet();

    group(name, () {
      test('declares its locale', () {
        expect(arb['@@locale'], isNotNull);
      });

      test('translates every English key', () {
        expect(englishKeys.difference(keys), isEmpty,
            reason: 'untranslated keys fall back to English');
      });

      test('has no keys the template lacks', () {
        expect(keys.difference(englishKeys), isEmpty,
            reason: 'stale keys left behind after a rename');
      });

      test('uses exactly the placeholders the English string uses', () {
        final mismatched = <String>[];
        for (final k in englishKeys.intersection(keys)) {
          final want = placeholders(template[k] as String);
          final got = placeholders(arb[k] as String);
          if (want.difference(got).isNotEmpty ||
              got.difference(want).isNotEmpty) {
            mismatched.add('$k: expected $want, found $got');
          }
        }
        expect(mismatched, isEmpty, reason: mismatched.join('\n'));
      });

      test('leaves no string identical to English by accident', () {
        // Some strings legitimately match (the app name, "M", "NAME").
        // A large overlap means the file was copied and not translated.
        final identical = englishKeys
            .intersection(keys)
            .where((k) => template[k] == arb[k])
            .toList();
        expect(identical.length / englishKeys.length, lessThan(0.2),
            reason: 'mostly untranslated: ${identical.take(10).join(', ')}');
      });
    });
  }
}
