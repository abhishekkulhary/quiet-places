import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces that presentation code resolves its values from the theme.
///
/// This is the lint rule behind "zero hardcoded colours, spacings, durations
/// anywhere outside the theme". It runs in CI, so the consistency pass cannot
/// silently rot the way a one-off manual audit would.
///
/// Scope is deliberate:
///  * only `lib/presentation` — `data/` and `domain/` legitimately hold their
///    own constants (network timeouts, GPS cadence, cache retention), and those
///    are not design tokens;
///  * the theme files themselves are exempt, since that is where the literals
///    are supposed to live;
///  * `lib/dev` is exempt: profiling scaffolding is not shipped UI.
void main() {
  final files = Directory('lib/presentation')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('/theme/'))
      .toList();

  test('presentation sources exist to audit', () {
    expect(files, isNotEmpty);
  });

  /// Strips comments and string literals so prose and copy never trip the
  /// numeric checks.
  List<({int line, String code})> codeLines(File f) {
    final out = <({int line, String code})>[];
    for (final (i, raw) in f.readAsLinesSync().indexed) {
      var line = raw.split('//').first;
      line = line.replaceAll(RegExp(r"'[^']*'"), "''");
      line = line.replaceAll(RegExp(r'"[^"]*"'), '""');
      if (line.trim().isEmpty) continue;
      out.add((line: i + 1, code: line));
    }
    return out;
  }

  void expectNoMatches(
    RegExp pattern,
    String what, {
    bool Function(String match)? allow,
  }) {
    final offenders = <String>[];
    for (final file in files) {
      for (final entry in codeLines(file)) {
        for (final m in pattern.allMatches(entry.code)) {
          final text = m.group(0)!;
          if (allow != null && allow(text)) continue;
          final path = file.path.replaceFirst('lib/presentation/', '');
          offenders.add('$path:${entry.line}  $text');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: '$what must come from lib/presentation/theme:\n'
            '${offenders.join('\n')}');
  }

  test('no hardcoded colours', () {
    expectNoMatches(
      RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)|Colors\.[a-zA-Z]+'),
      'Colours',
      // Fully transparent is a structural value, not a palette choice.
      allow: (m) => m == 'Colors.transparent',
    );
  });

  test('no hardcoded corner radii', () {
    expectNoMatches(
      RegExp(r'BorderRadius\.circular\(\s*\d'),
      'Corner radii',
    );
  });

  test('no ad-hoc font sizes', () {
    expectNoMatches(RegExp(r'fontSize:\s*\d'), 'Font sizes');
  });

  test('no ad-hoc icon sizes', () {
    expectNoMatches(RegExp(r'\b(?:iconSize|size):\s*\d'), 'Icon sizes');
  });

  test('no numeric literals in EdgeInsets', () {
    expectNoMatches(
      RegExp(r'EdgeInsets\.(?:all|symmetric|only|fromLTRB)\([^)]*\b\d+\b[^)]*\)'),
      'Spacing',
      // Space.xxs / 2 is a derived token, not a literal.
      allow: (m) => m.contains('Space.'),
    );
  });

  test('animation durations come from Motion', () {
    expectNoMatches(
      RegExp(r'Duration\(\s*(?:milliseconds|seconds):\s*\d+'),
      'Animation durations',
    );
  });

  _copyAudit();
}

/// Enforces that user-facing copy lives in ARB files, not in widget code.
///
/// This is the second half of "zero hardcoded ... user-facing strings anywhere
/// outside the theme and ARB files". Heuristic by necessity — it flags string
/// literals that read like prose (contain a space and start with a capital, or
/// are ALL CAPS words) while ignoring the many literals that are not copy:
/// asset paths, map URL templates, format patterns, semantic joiners.
void _copyAudit() {
  final files = Directory('lib/presentation')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('/theme/'))
      .toList();

  /// Interpolating a method without calling it is silently legal Dart: every
  /// Object has a toString, so `'$verb'` on a tear-off renders
  /// "Closure: (L) => String from Function '_verb@...'". It shipped to a real
  /// device that way, and neither the analyzer nor the copy audit sees it,
  /// because the result is a perfectly valid interpolation of a real object.
  test('no method tear-offs interpolated into strings', () {
    final offenders = <String>[];
    for (final f in files) {
      final src = f.readAsStringSync();
      // Names declared as methods/functions in this file.
      final methods = RegExp(r'^\s*(?:[\w<>,\s?\[\]]+?)\s+(_?\w+)\s*\([^)]*\)\s*(?:async\s*)?[={]',
              multiLine: true)
          .allMatches(src)
          .map((m) => m.group(1)!)
          .toSet();
      // `$name` not followed by an identifier char or an opening paren, i.e.
      // interpolated rather than called.
      for (final m in RegExp(r'\$(_?\w+)(?![\w(])').allMatches(src)) {
        if (methods.contains(m.group(1))) {
          final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
          offenders.add('${f.path}:$line: \$${m.group(1)}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'interpolate the call, not the tear-off:\n'
            '${offenders.join('\n')}');
  });

  test('no hardcoded user-facing copy', () {
    final prose = RegExp(r"'([A-Z][^'\\]{3,}\s+[^'\\]{2,})'");
    final shouty = RegExp(r"'([A-Z][A-Z ]{4,})'");
    final offenders = <String>[];

    for (final file in files) {
      for (final (i, raw) in file.readAsLinesSync().indexed) {
        // Escaped apostrophes would otherwise hide copy from the patterns
        // below — "Couldn\'t load your places" slipped through exactly that
        // way. Neutralise the escape before matching.
        final line = raw.split('//').first.replaceAll(r"\'", '\u0001');
        if (line.trim().isEmpty) continue;
        // Lines that are obviously not copy.
        if (line.contains('http') ||
            line.contains('assets/') ||
            line.contains('.dart') ||
            line.contains('User-Agent')) {
          continue;
        }
        for (final pattern in [prose, shouty]) {
          for (final m in pattern.allMatches(line)) {
            final text = m.group(1)!;
            // Joiners and separators are structural, not copy.
            if (text.trim().length < 4) continue;
            final path = file.path.replaceFirst('lib/presentation/', '');
            offenders.add('$path:${i + 1}  "$text"');
          }
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'User-facing copy must live in lib/l10n/*.arb:\n'
            '${offenders.join('\n')}');
  });
}
