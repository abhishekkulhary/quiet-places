import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the layering rule from the plan: `lib/domain/` is pure Dart and must
/// not import Flutter or any plugin. This is our lightweight substitute for a
/// custom_lint rule — it fails the build if the domain layer reaches for a
/// package it shouldn't.
///
/// Allowed: `dart:` core libs and intra-domain relative imports.
void main() {
  test('domain layer imports no Flutter/plugin packages', () {
    final domainDir = Directory('lib/domain');
    expect(domainDir.existsSync(), isTrue, reason: 'lib/domain must exist');

    final offenders = <String>[];
    final importRe = RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''');

    for (final entity in domainDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (final line in lines) {
        final match = importRe.firstMatch(line);
        if (match == null) continue;
        final uri = match.group(1)!;
        final isDartCore = uri.startsWith('dart:');
        final isRelative = !uri.startsWith('package:') && !isDartCore;
        // Only the app's own domain package would be allowed via package: — but
        // we use relative imports inside domain, so any package: import is a
        // violation.
        if (!isDartCore && !isRelative) {
          offenders.add('${entity.path}: $uri');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'domain/ must not import plugins/Flutter:\n'
          '${offenders.join('\n')}',
    );
  });
}
