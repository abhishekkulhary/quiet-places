import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the app's SQLite database at a fixed on-device path.
///
/// The same path is opened from both the UI isolate and the geofence background
/// isolate. Our write volume is tiny (a handful of rows per transition), so a
/// plain per-isolate [NativeDatabase] against the shared file is sufficient;
/// `PRAGMA busy_timeout` (drift default) absorbs the rare concurrent write.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'phonesilent.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
