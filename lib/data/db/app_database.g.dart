// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $QuietPlacesTable extends QuietPlaces
    with TableInfo<$QuietPlacesTable, QuietPlaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuietPlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusMetersMeta = const VerificationMeta(
    'radiusMeters',
  );
  @override
  late final GeneratedColumn<double> radiusMeters = GeneratedColumn<double>(
    'radius_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _behaviourMeta = const VerificationMeta(
    'behaviour',
  );
  @override
  late final GeneratedColumn<int> behaviour = GeneratedColumn<int>(
    'behaviour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    latitude,
    longitude,
    radiusMeters,
    behaviour,
    enabled,
    createdAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiet_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuietPlaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('radius_meters')) {
      context.handle(
        _radiusMetersMeta,
        radiusMeters.isAcceptableOrUnknown(
          data['radius_meters']!,
          _radiusMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_radiusMetersMeta);
    }
    if (data.containsKey('behaviour')) {
      context.handle(
        _behaviourMeta,
        behaviour.isAcceptableOrUnknown(data['behaviour']!, _behaviourMeta),
      );
    } else if (isInserting) {
      context.missing(_behaviourMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuietPlaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuietPlaceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      radiusMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius_meters'],
      )!,
      behaviour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}behaviour'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $QuietPlacesTable createAlias(String alias) {
    return $QuietPlacesTable(attachedDatabase, alias);
  }
}

class QuietPlaceRow extends DataClass implements Insertable<QuietPlaceRow> {
  /// Also used as the `native_geofence` region id.
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  /// [QuietPlaceBehaviour] stored as its enum index.
  final int behaviour;
  final bool enabled;
  final int createdAtMs;
  const QuietPlaceRow({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.behaviour,
    required this.enabled,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['radius_meters'] = Variable<double>(radiusMeters);
    map['behaviour'] = Variable<int>(behaviour);
    map['enabled'] = Variable<bool>(enabled);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  QuietPlacesCompanion toCompanion(bool nullToAbsent) {
    return QuietPlacesCompanion(
      id: Value(id),
      name: Value(name),
      latitude: Value(latitude),
      longitude: Value(longitude),
      radiusMeters: Value(radiusMeters),
      behaviour: Value(behaviour),
      enabled: Value(enabled),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory QuietPlaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuietPlaceRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      radiusMeters: serializer.fromJson<double>(json['radiusMeters']),
      behaviour: serializer.fromJson<int>(json['behaviour']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'radiusMeters': serializer.toJson<double>(radiusMeters),
      'behaviour': serializer.toJson<int>(behaviour),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  QuietPlaceRow copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    int? behaviour,
    bool? enabled,
    int? createdAtMs,
  }) => QuietPlaceRow(
    id: id ?? this.id,
    name: name ?? this.name,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radiusMeters: radiusMeters ?? this.radiusMeters,
    behaviour: behaviour ?? this.behaviour,
    enabled: enabled ?? this.enabled,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  QuietPlaceRow copyWithCompanion(QuietPlacesCompanion data) {
    return QuietPlaceRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      radiusMeters: data.radiusMeters.present
          ? data.radiusMeters.value
          : this.radiusMeters,
      behaviour: data.behaviour.present ? data.behaviour.value : this.behaviour,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuietPlaceRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('behaviour: $behaviour, ')
          ..write('enabled: $enabled, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    latitude,
    longitude,
    radiusMeters,
    behaviour,
    enabled,
    createdAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuietPlaceRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.radiusMeters == this.radiusMeters &&
          other.behaviour == this.behaviour &&
          other.enabled == this.enabled &&
          other.createdAtMs == this.createdAtMs);
}

class QuietPlacesCompanion extends UpdateCompanion<QuietPlaceRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> radiusMeters;
  final Value<int> behaviour;
  final Value<bool> enabled;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const QuietPlacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.radiusMeters = const Value.absent(),
    this.behaviour = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuietPlacesCompanion.insert({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required int behaviour,
    this.enabled = const Value.absent(),
    required int createdAtMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       latitude = Value(latitude),
       longitude = Value(longitude),
       radiusMeters = Value(radiusMeters),
       behaviour = Value(behaviour),
       createdAtMs = Value(createdAtMs);
  static Insertable<QuietPlaceRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? radiusMeters,
    Expression<int>? behaviour,
    Expression<bool>? enabled,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusMeters != null) 'radius_meters': radiusMeters,
      if (behaviour != null) 'behaviour': behaviour,
      if (enabled != null) 'enabled': enabled,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuietPlacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? radiusMeters,
    Value<int>? behaviour,
    Value<bool>? enabled,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return QuietPlacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      behaviour: behaviour ?? this.behaviour,
      enabled: enabled ?? this.enabled,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (radiusMeters.present) {
      map['radius_meters'] = Variable<double>(radiusMeters.value);
    }
    if (behaviour.present) {
      map['behaviour'] = Variable<int>(behaviour.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuietPlacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('behaviour: $behaviour, ')
          ..write('enabled: $enabled, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TripLogsTable extends TripLogs
    with TableInfo<$TripLogsTable, TripLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _placeIdMeta = const VerificationMeta(
    'placeId',
  );
  @override
  late final GeneratedColumn<String> placeId = GeneratedColumn<String>(
    'place_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placeNameMeta = const VerificationMeta(
    'placeName',
  );
  @override
  late final GeneratedColumn<String> placeName = GeneratedColumn<String>(
    'place_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transitionMeta = const VerificationMeta(
    'transition',
  );
  @override
  late final GeneratedColumn<int> transition = GeneratedColumn<int>(
    'transition',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<int> action = GeneratedColumn<int>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _behaviourMeta = const VerificationMeta(
    'behaviour',
  );
  @override
  late final GeneratedColumn<int> behaviour = GeneratedColumn<int>(
    'behaviour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMsMeta = const VerificationMeta(
    'timestampMs',
  );
  @override
  late final GeneratedColumn<int> timestampMs = GeneratedColumn<int>(
    'timestamp_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    placeId,
    placeName,
    transition,
    action,
    behaviour,
    detail,
    timestampMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trip_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TripLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('place_id')) {
      context.handle(
        _placeIdMeta,
        placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_placeIdMeta);
    }
    if (data.containsKey('place_name')) {
      context.handle(
        _placeNameMeta,
        placeName.isAcceptableOrUnknown(data['place_name']!, _placeNameMeta),
      );
    } else if (isInserting) {
      context.missing(_placeNameMeta);
    }
    if (data.containsKey('transition')) {
      context.handle(
        _transitionMeta,
        transition.isAcceptableOrUnknown(data['transition']!, _transitionMeta),
      );
    } else if (isInserting) {
      context.missing(_transitionMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('behaviour')) {
      context.handle(
        _behaviourMeta,
        behaviour.isAcceptableOrUnknown(data['behaviour']!, _behaviourMeta),
      );
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('timestamp_ms')) {
      context.handle(
        _timestampMsMeta,
        timestampMs.isAcceptableOrUnknown(
          data['timestamp_ms']!,
          _timestampMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timestampMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TripLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      placeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_id'],
      )!,
      placeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_name'],
      )!,
      transition: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transition'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}action'],
      )!,
      behaviour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}behaviour'],
      ),
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      ),
      timestampMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp_ms'],
      )!,
    );
  }

  @override
  $TripLogsTable createAlias(String alias) {
    return $TripLogsTable(attachedDatabase, alias);
  }
}

class TripLogRow extends DataClass implements Insertable<TripLogRow> {
  final int id;
  final String placeId;
  final String placeName;

  /// [BoundaryTransition] index.
  final int transition;

  /// [TripAction] index.
  final int action;

  /// The behaviour that was in force after this entry, as a
  /// [QuietPlaceBehaviour] index. Null for entries that applied nothing
  /// (skips, errors, dwell). Recorded structurally because [detail] is prose:
  /// a step-down reads "Do Not Disturb → Vibrate", and anything scanning it for
  /// a behaviour name finds the one being *left*, not the one now in force.
  final int? behaviour;
  final String? detail;
  final int timestampMs;
  const TripLogRow({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.transition,
    required this.action,
    this.behaviour,
    this.detail,
    required this.timestampMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['place_id'] = Variable<String>(placeId);
    map['place_name'] = Variable<String>(placeName);
    map['transition'] = Variable<int>(transition);
    map['action'] = Variable<int>(action);
    if (!nullToAbsent || behaviour != null) {
      map['behaviour'] = Variable<int>(behaviour);
    }
    if (!nullToAbsent || detail != null) {
      map['detail'] = Variable<String>(detail);
    }
    map['timestamp_ms'] = Variable<int>(timestampMs);
    return map;
  }

  TripLogsCompanion toCompanion(bool nullToAbsent) {
    return TripLogsCompanion(
      id: Value(id),
      placeId: Value(placeId),
      placeName: Value(placeName),
      transition: Value(transition),
      action: Value(action),
      behaviour: behaviour == null && nullToAbsent
          ? const Value.absent()
          : Value(behaviour),
      detail: detail == null && nullToAbsent
          ? const Value.absent()
          : Value(detail),
      timestampMs: Value(timestampMs),
    );
  }

  factory TripLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripLogRow(
      id: serializer.fromJson<int>(json['id']),
      placeId: serializer.fromJson<String>(json['placeId']),
      placeName: serializer.fromJson<String>(json['placeName']),
      transition: serializer.fromJson<int>(json['transition']),
      action: serializer.fromJson<int>(json['action']),
      behaviour: serializer.fromJson<int?>(json['behaviour']),
      detail: serializer.fromJson<String?>(json['detail']),
      timestampMs: serializer.fromJson<int>(json['timestampMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'placeId': serializer.toJson<String>(placeId),
      'placeName': serializer.toJson<String>(placeName),
      'transition': serializer.toJson<int>(transition),
      'action': serializer.toJson<int>(action),
      'behaviour': serializer.toJson<int?>(behaviour),
      'detail': serializer.toJson<String?>(detail),
      'timestampMs': serializer.toJson<int>(timestampMs),
    };
  }

  TripLogRow copyWith({
    int? id,
    String? placeId,
    String? placeName,
    int? transition,
    int? action,
    Value<int?> behaviour = const Value.absent(),
    Value<String?> detail = const Value.absent(),
    int? timestampMs,
  }) => TripLogRow(
    id: id ?? this.id,
    placeId: placeId ?? this.placeId,
    placeName: placeName ?? this.placeName,
    transition: transition ?? this.transition,
    action: action ?? this.action,
    behaviour: behaviour.present ? behaviour.value : this.behaviour,
    detail: detail.present ? detail.value : this.detail,
    timestampMs: timestampMs ?? this.timestampMs,
  );
  TripLogRow copyWithCompanion(TripLogsCompanion data) {
    return TripLogRow(
      id: data.id.present ? data.id.value : this.id,
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      placeName: data.placeName.present ? data.placeName.value : this.placeName,
      transition: data.transition.present
          ? data.transition.value
          : this.transition,
      action: data.action.present ? data.action.value : this.action,
      behaviour: data.behaviour.present ? data.behaviour.value : this.behaviour,
      detail: data.detail.present ? data.detail.value : this.detail,
      timestampMs: data.timestampMs.present
          ? data.timestampMs.value
          : this.timestampMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripLogRow(')
          ..write('id: $id, ')
          ..write('placeId: $placeId, ')
          ..write('placeName: $placeName, ')
          ..write('transition: $transition, ')
          ..write('action: $action, ')
          ..write('behaviour: $behaviour, ')
          ..write('detail: $detail, ')
          ..write('timestampMs: $timestampMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    placeId,
    placeName,
    transition,
    action,
    behaviour,
    detail,
    timestampMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripLogRow &&
          other.id == this.id &&
          other.placeId == this.placeId &&
          other.placeName == this.placeName &&
          other.transition == this.transition &&
          other.action == this.action &&
          other.behaviour == this.behaviour &&
          other.detail == this.detail &&
          other.timestampMs == this.timestampMs);
}

class TripLogsCompanion extends UpdateCompanion<TripLogRow> {
  final Value<int> id;
  final Value<String> placeId;
  final Value<String> placeName;
  final Value<int> transition;
  final Value<int> action;
  final Value<int?> behaviour;
  final Value<String?> detail;
  final Value<int> timestampMs;
  const TripLogsCompanion({
    this.id = const Value.absent(),
    this.placeId = const Value.absent(),
    this.placeName = const Value.absent(),
    this.transition = const Value.absent(),
    this.action = const Value.absent(),
    this.behaviour = const Value.absent(),
    this.detail = const Value.absent(),
    this.timestampMs = const Value.absent(),
  });
  TripLogsCompanion.insert({
    this.id = const Value.absent(),
    required String placeId,
    required String placeName,
    required int transition,
    required int action,
    this.behaviour = const Value.absent(),
    this.detail = const Value.absent(),
    required int timestampMs,
  }) : placeId = Value(placeId),
       placeName = Value(placeName),
       transition = Value(transition),
       action = Value(action),
       timestampMs = Value(timestampMs);
  static Insertable<TripLogRow> custom({
    Expression<int>? id,
    Expression<String>? placeId,
    Expression<String>? placeName,
    Expression<int>? transition,
    Expression<int>? action,
    Expression<int>? behaviour,
    Expression<String>? detail,
    Expression<int>? timestampMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (placeId != null) 'place_id': placeId,
      if (placeName != null) 'place_name': placeName,
      if (transition != null) 'transition': transition,
      if (action != null) 'action': action,
      if (behaviour != null) 'behaviour': behaviour,
      if (detail != null) 'detail': detail,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
    });
  }

  TripLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? placeId,
    Value<String>? placeName,
    Value<int>? transition,
    Value<int>? action,
    Value<int?>? behaviour,
    Value<String?>? detail,
    Value<int>? timestampMs,
  }) {
    return TripLogsCompanion(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      transition: transition ?? this.transition,
      action: action ?? this.action,
      behaviour: behaviour ?? this.behaviour,
      detail: detail ?? this.detail,
      timestampMs: timestampMs ?? this.timestampMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (placeId.present) {
      map['place_id'] = Variable<String>(placeId.value);
    }
    if (placeName.present) {
      map['place_name'] = Variable<String>(placeName.value);
    }
    if (transition.present) {
      map['transition'] = Variable<int>(transition.value);
    }
    if (action.present) {
      map['action'] = Variable<int>(action.value);
    }
    if (behaviour.present) {
      map['behaviour'] = Variable<int>(behaviour.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (timestampMs.present) {
      map['timestamp_ms'] = Variable<int>(timestampMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripLogsCompanion(')
          ..write('id: $id, ')
          ..write('placeId: $placeId, ')
          ..write('placeName: $placeName, ')
          ..write('transition: $transition, ')
          ..write('action: $action, ')
          ..write('behaviour: $behaviour, ')
          ..write('detail: $detail, ')
          ..write('timestampMs: $timestampMs')
          ..write(')'))
        .toString();
  }
}

class $SettingsRowsTable extends SettingsRows
    with TableInfo<$SettingsRowsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _globalPausedMeta = const VerificationMeta(
    'globalPaused',
  );
  @override
  late final GeneratedColumn<bool> globalPaused = GeneratedColumn<bool>(
    'global_paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("global_paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _snoozeUntilMsMeta = const VerificationMeta(
    'snoozeUntilMs',
  );
  @override
  late final GeneratedColumn<int> snoozeUntilMs = GeneratedColumn<int>(
    'snooze_until_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _onboardingCompleteMeta =
      const VerificationMeta('onboardingComplete');
  @override
  late final GeneratedColumn<bool> onboardingComplete = GeneratedColumn<bool>(
    'onboarding_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _gpsWarmupEnabledMeta = const VerificationMeta(
    'gpsWarmupEnabled',
  );
  @override
  late final GeneratedColumn<bool> gpsWarmupEnabled = GeneratedColumn<bool>(
    'gps_warmup_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("gps_warmup_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _mapsEnabledMeta = const VerificationMeta(
    'mapsEnabled',
  );
  @override
  late final GeneratedColumn<bool> mapsEnabled = GeneratedColumn<bool>(
    'maps_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("maps_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unitsMeta = const VerificationMeta('units');
  @override
  late final GeneratedColumn<int> units = GeneratedColumn<int>(
    'units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localeCodeMeta = const VerificationMeta(
    'localeCode',
  );
  @override
  late final GeneratedColumn<String> localeCode = GeneratedColumn<String>(
    'locale_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    globalPaused,
    snoozeUntilMs,
    onboardingComplete,
    gpsWarmupEnabled,
    mapsEnabled,
    units,
    localeCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('global_paused')) {
      context.handle(
        _globalPausedMeta,
        globalPaused.isAcceptableOrUnknown(
          data['global_paused']!,
          _globalPausedMeta,
        ),
      );
    }
    if (data.containsKey('snooze_until_ms')) {
      context.handle(
        _snoozeUntilMsMeta,
        snoozeUntilMs.isAcceptableOrUnknown(
          data['snooze_until_ms']!,
          _snoozeUntilMsMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_complete')) {
      context.handle(
        _onboardingCompleteMeta,
        onboardingComplete.isAcceptableOrUnknown(
          data['onboarding_complete']!,
          _onboardingCompleteMeta,
        ),
      );
    }
    if (data.containsKey('gps_warmup_enabled')) {
      context.handle(
        _gpsWarmupEnabledMeta,
        gpsWarmupEnabled.isAcceptableOrUnknown(
          data['gps_warmup_enabled']!,
          _gpsWarmupEnabledMeta,
        ),
      );
    }
    if (data.containsKey('maps_enabled')) {
      context.handle(
        _mapsEnabledMeta,
        mapsEnabled.isAcceptableOrUnknown(
          data['maps_enabled']!,
          _mapsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('units')) {
      context.handle(
        _unitsMeta,
        units.isAcceptableOrUnknown(data['units']!, _unitsMeta),
      );
    }
    if (data.containsKey('locale_code')) {
      context.handle(
        _localeCodeMeta,
        localeCode.isAcceptableOrUnknown(data['locale_code']!, _localeCodeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      globalPaused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}global_paused'],
      )!,
      snoozeUntilMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_until_ms'],
      ),
      onboardingComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_complete'],
      )!,
      gpsWarmupEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}gps_warmup_enabled'],
      )!,
      mapsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}maps_enabled'],
      )!,
      units: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}units'],
      )!,
      localeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_code'],
      ),
    );
  }

  @override
  $SettingsRowsTable createAlias(String alias) {
    return $SettingsRowsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final bool globalPaused;
  final int? snoozeUntilMs;
  final bool onboardingComplete;

  /// Added in schema v2. Defaults true so existing installs get the warm-up
  /// behaviour without needing to visit settings.
  final bool gpsWarmupEnabled;

  /// Added in schema v4. Defaults false: the map is opt-in, so an upgrading
  /// install keeps making no network requests until the user says otherwise.
  final bool mapsEnabled;

  /// Added in schema v5. [UnitSystem] index; defaults to metric.
  final int units;

  /// Language override ("en", "de"); null follows the device.
  final String? localeCode;
  const SettingsRow({
    required this.id,
    required this.globalPaused,
    this.snoozeUntilMs,
    required this.onboardingComplete,
    required this.gpsWarmupEnabled,
    required this.mapsEnabled,
    required this.units,
    this.localeCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['global_paused'] = Variable<bool>(globalPaused);
    if (!nullToAbsent || snoozeUntilMs != null) {
      map['snooze_until_ms'] = Variable<int>(snoozeUntilMs);
    }
    map['onboarding_complete'] = Variable<bool>(onboardingComplete);
    map['gps_warmup_enabled'] = Variable<bool>(gpsWarmupEnabled);
    map['maps_enabled'] = Variable<bool>(mapsEnabled);
    map['units'] = Variable<int>(units);
    if (!nullToAbsent || localeCode != null) {
      map['locale_code'] = Variable<String>(localeCode);
    }
    return map;
  }

  SettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingsRowsCompanion(
      id: Value(id),
      globalPaused: Value(globalPaused),
      snoozeUntilMs: snoozeUntilMs == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozeUntilMs),
      onboardingComplete: Value(onboardingComplete),
      gpsWarmupEnabled: Value(gpsWarmupEnabled),
      mapsEnabled: Value(mapsEnabled),
      units: Value(units),
      localeCode: localeCode == null && nullToAbsent
          ? const Value.absent()
          : Value(localeCode),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      globalPaused: serializer.fromJson<bool>(json['globalPaused']),
      snoozeUntilMs: serializer.fromJson<int?>(json['snoozeUntilMs']),
      onboardingComplete: serializer.fromJson<bool>(json['onboardingComplete']),
      gpsWarmupEnabled: serializer.fromJson<bool>(json['gpsWarmupEnabled']),
      mapsEnabled: serializer.fromJson<bool>(json['mapsEnabled']),
      units: serializer.fromJson<int>(json['units']),
      localeCode: serializer.fromJson<String?>(json['localeCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'globalPaused': serializer.toJson<bool>(globalPaused),
      'snoozeUntilMs': serializer.toJson<int?>(snoozeUntilMs),
      'onboardingComplete': serializer.toJson<bool>(onboardingComplete),
      'gpsWarmupEnabled': serializer.toJson<bool>(gpsWarmupEnabled),
      'mapsEnabled': serializer.toJson<bool>(mapsEnabled),
      'units': serializer.toJson<int>(units),
      'localeCode': serializer.toJson<String?>(localeCode),
    };
  }

  SettingsRow copyWith({
    int? id,
    bool? globalPaused,
    Value<int?> snoozeUntilMs = const Value.absent(),
    bool? onboardingComplete,
    bool? gpsWarmupEnabled,
    bool? mapsEnabled,
    int? units,
    Value<String?> localeCode = const Value.absent(),
  }) => SettingsRow(
    id: id ?? this.id,
    globalPaused: globalPaused ?? this.globalPaused,
    snoozeUntilMs: snoozeUntilMs.present
        ? snoozeUntilMs.value
        : this.snoozeUntilMs,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    gpsWarmupEnabled: gpsWarmupEnabled ?? this.gpsWarmupEnabled,
    mapsEnabled: mapsEnabled ?? this.mapsEnabled,
    units: units ?? this.units,
    localeCode: localeCode.present ? localeCode.value : this.localeCode,
  );
  SettingsRow copyWithCompanion(SettingsRowsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      globalPaused: data.globalPaused.present
          ? data.globalPaused.value
          : this.globalPaused,
      snoozeUntilMs: data.snoozeUntilMs.present
          ? data.snoozeUntilMs.value
          : this.snoozeUntilMs,
      onboardingComplete: data.onboardingComplete.present
          ? data.onboardingComplete.value
          : this.onboardingComplete,
      gpsWarmupEnabled: data.gpsWarmupEnabled.present
          ? data.gpsWarmupEnabled.value
          : this.gpsWarmupEnabled,
      mapsEnabled: data.mapsEnabled.present
          ? data.mapsEnabled.value
          : this.mapsEnabled,
      units: data.units.present ? data.units.value : this.units,
      localeCode: data.localeCode.present
          ? data.localeCode.value
          : this.localeCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('globalPaused: $globalPaused, ')
          ..write('snoozeUntilMs: $snoozeUntilMs, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('gpsWarmupEnabled: $gpsWarmupEnabled, ')
          ..write('mapsEnabled: $mapsEnabled, ')
          ..write('units: $units, ')
          ..write('localeCode: $localeCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    globalPaused,
    snoozeUntilMs,
    onboardingComplete,
    gpsWarmupEnabled,
    mapsEnabled,
    units,
    localeCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.globalPaused == this.globalPaused &&
          other.snoozeUntilMs == this.snoozeUntilMs &&
          other.onboardingComplete == this.onboardingComplete &&
          other.gpsWarmupEnabled == this.gpsWarmupEnabled &&
          other.mapsEnabled == this.mapsEnabled &&
          other.units == this.units &&
          other.localeCode == this.localeCode);
}

class SettingsRowsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<bool> globalPaused;
  final Value<int?> snoozeUntilMs;
  final Value<bool> onboardingComplete;
  final Value<bool> gpsWarmupEnabled;
  final Value<bool> mapsEnabled;
  final Value<int> units;
  final Value<String?> localeCode;
  const SettingsRowsCompanion({
    this.id = const Value.absent(),
    this.globalPaused = const Value.absent(),
    this.snoozeUntilMs = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    this.gpsWarmupEnabled = const Value.absent(),
    this.mapsEnabled = const Value.absent(),
    this.units = const Value.absent(),
    this.localeCode = const Value.absent(),
  });
  SettingsRowsCompanion.insert({
    this.id = const Value.absent(),
    this.globalPaused = const Value.absent(),
    this.snoozeUntilMs = const Value.absent(),
    this.onboardingComplete = const Value.absent(),
    this.gpsWarmupEnabled = const Value.absent(),
    this.mapsEnabled = const Value.absent(),
    this.units = const Value.absent(),
    this.localeCode = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<bool>? globalPaused,
    Expression<int>? snoozeUntilMs,
    Expression<bool>? onboardingComplete,
    Expression<bool>? gpsWarmupEnabled,
    Expression<bool>? mapsEnabled,
    Expression<int>? units,
    Expression<String>? localeCode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (globalPaused != null) 'global_paused': globalPaused,
      if (snoozeUntilMs != null) 'snooze_until_ms': snoozeUntilMs,
      if (onboardingComplete != null) 'onboarding_complete': onboardingComplete,
      if (gpsWarmupEnabled != null) 'gps_warmup_enabled': gpsWarmupEnabled,
      if (mapsEnabled != null) 'maps_enabled': mapsEnabled,
      if (units != null) 'units': units,
      if (localeCode != null) 'locale_code': localeCode,
    });
  }

  SettingsRowsCompanion copyWith({
    Value<int>? id,
    Value<bool>? globalPaused,
    Value<int?>? snoozeUntilMs,
    Value<bool>? onboardingComplete,
    Value<bool>? gpsWarmupEnabled,
    Value<bool>? mapsEnabled,
    Value<int>? units,
    Value<String?>? localeCode,
  }) {
    return SettingsRowsCompanion(
      id: id ?? this.id,
      globalPaused: globalPaused ?? this.globalPaused,
      snoozeUntilMs: snoozeUntilMs ?? this.snoozeUntilMs,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      gpsWarmupEnabled: gpsWarmupEnabled ?? this.gpsWarmupEnabled,
      mapsEnabled: mapsEnabled ?? this.mapsEnabled,
      units: units ?? this.units,
      localeCode: localeCode ?? this.localeCode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (globalPaused.present) {
      map['global_paused'] = Variable<bool>(globalPaused.value);
    }
    if (snoozeUntilMs.present) {
      map['snooze_until_ms'] = Variable<int>(snoozeUntilMs.value);
    }
    if (onboardingComplete.present) {
      map['onboarding_complete'] = Variable<bool>(onboardingComplete.value);
    }
    if (gpsWarmupEnabled.present) {
      map['gps_warmup_enabled'] = Variable<bool>(gpsWarmupEnabled.value);
    }
    if (mapsEnabled.present) {
      map['maps_enabled'] = Variable<bool>(mapsEnabled.value);
    }
    if (units.present) {
      map['units'] = Variable<int>(units.value);
    }
    if (localeCode.present) {
      map['locale_code'] = Variable<String>(localeCode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('globalPaused: $globalPaused, ')
          ..write('snoozeUntilMs: $snoozeUntilMs, ')
          ..write('onboardingComplete: $onboardingComplete, ')
          ..write('gpsWarmupEnabled: $gpsWarmupEnabled, ')
          ..write('mapsEnabled: $mapsEnabled, ')
          ..write('units: $units, ')
          ..write('localeCode: $localeCode')
          ..write(')'))
        .toString();
  }
}

class $EngagementRowsTable extends EngagementRows
    with TableInfo<$EngagementRowsTable, EngagementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EngagementRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _activePlaceIdsMeta = const VerificationMeta(
    'activePlaceIds',
  );
  @override
  late final GeneratedColumn<String> activePlaceIds = GeneratedColumn<String>(
    'active_place_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _capturedRingerMeta = const VerificationMeta(
    'capturedRinger',
  );
  @override
  late final GeneratedColumn<int> capturedRinger = GeneratedColumn<int>(
    'captured_ringer',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedDndMeta = const VerificationMeta(
    'capturedDnd',
  );
  @override
  late final GeneratedColumn<bool> capturedDnd = GeneratedColumn<bool>(
    'captured_dnd',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("captured_dnd" IN (0, 1))',
    ),
  );
  static const VerificationMeta _appliedBehaviourMeta = const VerificationMeta(
    'appliedBehaviour',
  );
  @override
  late final GeneratedColumn<int> appliedBehaviour = GeneratedColumn<int>(
    'applied_behaviour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedRingerMeta = const VerificationMeta(
    'appliedRinger',
  );
  @override
  late final GeneratedColumn<int> appliedRinger = GeneratedColumn<int>(
    'applied_ringer',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedDndMeta = const VerificationMeta(
    'appliedDnd',
  );
  @override
  late final GeneratedColumn<bool> appliedDnd = GeneratedColumn<bool>(
    'applied_dnd',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("applied_dnd" IN (0, 1))',
    ),
  );
  static const VerificationMeta _overriddenMeta = const VerificationMeta(
    'overridden',
  );
  @override
  late final GeneratedColumn<bool> overridden = GeneratedColumn<bool>(
    'overridden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("overridden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bootTimeMsMeta = const VerificationMeta(
    'bootTimeMs',
  );
  @override
  late final GeneratedColumn<int> bootTimeMs = GeneratedColumn<int>(
    'boot_time_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activePlaceIds,
    capturedRinger,
    capturedDnd,
    appliedBehaviour,
    appliedRinger,
    appliedDnd,
    overridden,
    bootTimeMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'engagement_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<EngagementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('active_place_ids')) {
      context.handle(
        _activePlaceIdsMeta,
        activePlaceIds.isAcceptableOrUnknown(
          data['active_place_ids']!,
          _activePlaceIdsMeta,
        ),
      );
    }
    if (data.containsKey('captured_ringer')) {
      context.handle(
        _capturedRingerMeta,
        capturedRinger.isAcceptableOrUnknown(
          data['captured_ringer']!,
          _capturedRingerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_capturedRingerMeta);
    }
    if (data.containsKey('captured_dnd')) {
      context.handle(
        _capturedDndMeta,
        capturedDnd.isAcceptableOrUnknown(
          data['captured_dnd']!,
          _capturedDndMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_capturedDndMeta);
    }
    if (data.containsKey('applied_behaviour')) {
      context.handle(
        _appliedBehaviourMeta,
        appliedBehaviour.isAcceptableOrUnknown(
          data['applied_behaviour']!,
          _appliedBehaviourMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appliedBehaviourMeta);
    }
    if (data.containsKey('applied_ringer')) {
      context.handle(
        _appliedRingerMeta,
        appliedRinger.isAcceptableOrUnknown(
          data['applied_ringer']!,
          _appliedRingerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appliedRingerMeta);
    }
    if (data.containsKey('applied_dnd')) {
      context.handle(
        _appliedDndMeta,
        appliedDnd.isAcceptableOrUnknown(data['applied_dnd']!, _appliedDndMeta),
      );
    } else if (isInserting) {
      context.missing(_appliedDndMeta);
    }
    if (data.containsKey('overridden')) {
      context.handle(
        _overriddenMeta,
        overridden.isAcceptableOrUnknown(data['overridden']!, _overriddenMeta),
      );
    }
    if (data.containsKey('boot_time_ms')) {
      context.handle(
        _bootTimeMsMeta,
        bootTimeMs.isAcceptableOrUnknown(
          data['boot_time_ms']!,
          _bootTimeMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EngagementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EngagementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activePlaceIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_place_ids'],
      )!,
      capturedRinger: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}captured_ringer'],
      )!,
      capturedDnd: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}captured_dnd'],
      )!,
      appliedBehaviour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_behaviour'],
      )!,
      appliedRinger: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_ringer'],
      )!,
      appliedDnd: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}applied_dnd'],
      )!,
      overridden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}overridden'],
      )!,
      bootTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}boot_time_ms'],
      ),
    );
  }

  @override
  $EngagementRowsTable createAlias(String alias) {
    return $EngagementRowsTable(attachedDatabase, alias);
  }
}

class EngagementRow extends DataClass implements Insertable<EngagementRow> {
  final int id;

  /// Comma-separated active place ids (ids never contain commas — they are uuids).
  final String activePlaceIds;
  final int capturedRinger;
  final bool capturedDnd;
  final int appliedBehaviour;
  final int appliedRinger;
  final bool appliedDnd;
  final bool overridden;

  /// Added in schema v6. Boot instant when this engagement was written; null
  /// for rows that predate it, which are treated as stale.
  final int? bootTimeMs;
  const EngagementRow({
    required this.id,
    required this.activePlaceIds,
    required this.capturedRinger,
    required this.capturedDnd,
    required this.appliedBehaviour,
    required this.appliedRinger,
    required this.appliedDnd,
    required this.overridden,
    this.bootTimeMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['active_place_ids'] = Variable<String>(activePlaceIds);
    map['captured_ringer'] = Variable<int>(capturedRinger);
    map['captured_dnd'] = Variable<bool>(capturedDnd);
    map['applied_behaviour'] = Variable<int>(appliedBehaviour);
    map['applied_ringer'] = Variable<int>(appliedRinger);
    map['applied_dnd'] = Variable<bool>(appliedDnd);
    map['overridden'] = Variable<bool>(overridden);
    if (!nullToAbsent || bootTimeMs != null) {
      map['boot_time_ms'] = Variable<int>(bootTimeMs);
    }
    return map;
  }

  EngagementRowsCompanion toCompanion(bool nullToAbsent) {
    return EngagementRowsCompanion(
      id: Value(id),
      activePlaceIds: Value(activePlaceIds),
      capturedRinger: Value(capturedRinger),
      capturedDnd: Value(capturedDnd),
      appliedBehaviour: Value(appliedBehaviour),
      appliedRinger: Value(appliedRinger),
      appliedDnd: Value(appliedDnd),
      overridden: Value(overridden),
      bootTimeMs: bootTimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(bootTimeMs),
    );
  }

  factory EngagementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EngagementRow(
      id: serializer.fromJson<int>(json['id']),
      activePlaceIds: serializer.fromJson<String>(json['activePlaceIds']),
      capturedRinger: serializer.fromJson<int>(json['capturedRinger']),
      capturedDnd: serializer.fromJson<bool>(json['capturedDnd']),
      appliedBehaviour: serializer.fromJson<int>(json['appliedBehaviour']),
      appliedRinger: serializer.fromJson<int>(json['appliedRinger']),
      appliedDnd: serializer.fromJson<bool>(json['appliedDnd']),
      overridden: serializer.fromJson<bool>(json['overridden']),
      bootTimeMs: serializer.fromJson<int?>(json['bootTimeMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activePlaceIds': serializer.toJson<String>(activePlaceIds),
      'capturedRinger': serializer.toJson<int>(capturedRinger),
      'capturedDnd': serializer.toJson<bool>(capturedDnd),
      'appliedBehaviour': serializer.toJson<int>(appliedBehaviour),
      'appliedRinger': serializer.toJson<int>(appliedRinger),
      'appliedDnd': serializer.toJson<bool>(appliedDnd),
      'overridden': serializer.toJson<bool>(overridden),
      'bootTimeMs': serializer.toJson<int?>(bootTimeMs),
    };
  }

  EngagementRow copyWith({
    int? id,
    String? activePlaceIds,
    int? capturedRinger,
    bool? capturedDnd,
    int? appliedBehaviour,
    int? appliedRinger,
    bool? appliedDnd,
    bool? overridden,
    Value<int?> bootTimeMs = const Value.absent(),
  }) => EngagementRow(
    id: id ?? this.id,
    activePlaceIds: activePlaceIds ?? this.activePlaceIds,
    capturedRinger: capturedRinger ?? this.capturedRinger,
    capturedDnd: capturedDnd ?? this.capturedDnd,
    appliedBehaviour: appliedBehaviour ?? this.appliedBehaviour,
    appliedRinger: appliedRinger ?? this.appliedRinger,
    appliedDnd: appliedDnd ?? this.appliedDnd,
    overridden: overridden ?? this.overridden,
    bootTimeMs: bootTimeMs.present ? bootTimeMs.value : this.bootTimeMs,
  );
  EngagementRow copyWithCompanion(EngagementRowsCompanion data) {
    return EngagementRow(
      id: data.id.present ? data.id.value : this.id,
      activePlaceIds: data.activePlaceIds.present
          ? data.activePlaceIds.value
          : this.activePlaceIds,
      capturedRinger: data.capturedRinger.present
          ? data.capturedRinger.value
          : this.capturedRinger,
      capturedDnd: data.capturedDnd.present
          ? data.capturedDnd.value
          : this.capturedDnd,
      appliedBehaviour: data.appliedBehaviour.present
          ? data.appliedBehaviour.value
          : this.appliedBehaviour,
      appliedRinger: data.appliedRinger.present
          ? data.appliedRinger.value
          : this.appliedRinger,
      appliedDnd: data.appliedDnd.present
          ? data.appliedDnd.value
          : this.appliedDnd,
      overridden: data.overridden.present
          ? data.overridden.value
          : this.overridden,
      bootTimeMs: data.bootTimeMs.present
          ? data.bootTimeMs.value
          : this.bootTimeMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EngagementRow(')
          ..write('id: $id, ')
          ..write('activePlaceIds: $activePlaceIds, ')
          ..write('capturedRinger: $capturedRinger, ')
          ..write('capturedDnd: $capturedDnd, ')
          ..write('appliedBehaviour: $appliedBehaviour, ')
          ..write('appliedRinger: $appliedRinger, ')
          ..write('appliedDnd: $appliedDnd, ')
          ..write('overridden: $overridden, ')
          ..write('bootTimeMs: $bootTimeMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    activePlaceIds,
    capturedRinger,
    capturedDnd,
    appliedBehaviour,
    appliedRinger,
    appliedDnd,
    overridden,
    bootTimeMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EngagementRow &&
          other.id == this.id &&
          other.activePlaceIds == this.activePlaceIds &&
          other.capturedRinger == this.capturedRinger &&
          other.capturedDnd == this.capturedDnd &&
          other.appliedBehaviour == this.appliedBehaviour &&
          other.appliedRinger == this.appliedRinger &&
          other.appliedDnd == this.appliedDnd &&
          other.overridden == this.overridden &&
          other.bootTimeMs == this.bootTimeMs);
}

class EngagementRowsCompanion extends UpdateCompanion<EngagementRow> {
  final Value<int> id;
  final Value<String> activePlaceIds;
  final Value<int> capturedRinger;
  final Value<bool> capturedDnd;
  final Value<int> appliedBehaviour;
  final Value<int> appliedRinger;
  final Value<bool> appliedDnd;
  final Value<bool> overridden;
  final Value<int?> bootTimeMs;
  const EngagementRowsCompanion({
    this.id = const Value.absent(),
    this.activePlaceIds = const Value.absent(),
    this.capturedRinger = const Value.absent(),
    this.capturedDnd = const Value.absent(),
    this.appliedBehaviour = const Value.absent(),
    this.appliedRinger = const Value.absent(),
    this.appliedDnd = const Value.absent(),
    this.overridden = const Value.absent(),
    this.bootTimeMs = const Value.absent(),
  });
  EngagementRowsCompanion.insert({
    this.id = const Value.absent(),
    this.activePlaceIds = const Value.absent(),
    required int capturedRinger,
    required bool capturedDnd,
    required int appliedBehaviour,
    required int appliedRinger,
    required bool appliedDnd,
    this.overridden = const Value.absent(),
    this.bootTimeMs = const Value.absent(),
  }) : capturedRinger = Value(capturedRinger),
       capturedDnd = Value(capturedDnd),
       appliedBehaviour = Value(appliedBehaviour),
       appliedRinger = Value(appliedRinger),
       appliedDnd = Value(appliedDnd);
  static Insertable<EngagementRow> custom({
    Expression<int>? id,
    Expression<String>? activePlaceIds,
    Expression<int>? capturedRinger,
    Expression<bool>? capturedDnd,
    Expression<int>? appliedBehaviour,
    Expression<int>? appliedRinger,
    Expression<bool>? appliedDnd,
    Expression<bool>? overridden,
    Expression<int>? bootTimeMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activePlaceIds != null) 'active_place_ids': activePlaceIds,
      if (capturedRinger != null) 'captured_ringer': capturedRinger,
      if (capturedDnd != null) 'captured_dnd': capturedDnd,
      if (appliedBehaviour != null) 'applied_behaviour': appliedBehaviour,
      if (appliedRinger != null) 'applied_ringer': appliedRinger,
      if (appliedDnd != null) 'applied_dnd': appliedDnd,
      if (overridden != null) 'overridden': overridden,
      if (bootTimeMs != null) 'boot_time_ms': bootTimeMs,
    });
  }

  EngagementRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? activePlaceIds,
    Value<int>? capturedRinger,
    Value<bool>? capturedDnd,
    Value<int>? appliedBehaviour,
    Value<int>? appliedRinger,
    Value<bool>? appliedDnd,
    Value<bool>? overridden,
    Value<int?>? bootTimeMs,
  }) {
    return EngagementRowsCompanion(
      id: id ?? this.id,
      activePlaceIds: activePlaceIds ?? this.activePlaceIds,
      capturedRinger: capturedRinger ?? this.capturedRinger,
      capturedDnd: capturedDnd ?? this.capturedDnd,
      appliedBehaviour: appliedBehaviour ?? this.appliedBehaviour,
      appliedRinger: appliedRinger ?? this.appliedRinger,
      appliedDnd: appliedDnd ?? this.appliedDnd,
      overridden: overridden ?? this.overridden,
      bootTimeMs: bootTimeMs ?? this.bootTimeMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activePlaceIds.present) {
      map['active_place_ids'] = Variable<String>(activePlaceIds.value);
    }
    if (capturedRinger.present) {
      map['captured_ringer'] = Variable<int>(capturedRinger.value);
    }
    if (capturedDnd.present) {
      map['captured_dnd'] = Variable<bool>(capturedDnd.value);
    }
    if (appliedBehaviour.present) {
      map['applied_behaviour'] = Variable<int>(appliedBehaviour.value);
    }
    if (appliedRinger.present) {
      map['applied_ringer'] = Variable<int>(appliedRinger.value);
    }
    if (appliedDnd.present) {
      map['applied_dnd'] = Variable<bool>(appliedDnd.value);
    }
    if (overridden.present) {
      map['overridden'] = Variable<bool>(overridden.value);
    }
    if (bootTimeMs.present) {
      map['boot_time_ms'] = Variable<int>(bootTimeMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EngagementRowsCompanion(')
          ..write('id: $id, ')
          ..write('activePlaceIds: $activePlaceIds, ')
          ..write('capturedRinger: $capturedRinger, ')
          ..write('capturedDnd: $capturedDnd, ')
          ..write('appliedBehaviour: $appliedBehaviour, ')
          ..write('appliedRinger: $appliedRinger, ')
          ..write('appliedDnd: $appliedDnd, ')
          ..write('overridden: $overridden, ')
          ..write('bootTimeMs: $bootTimeMs')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuietPlacesTable quietPlaces = $QuietPlacesTable(this);
  late final $TripLogsTable tripLogs = $TripLogsTable(this);
  late final $SettingsRowsTable settingsRows = $SettingsRowsTable(this);
  late final $EngagementRowsTable engagementRows = $EngagementRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    quietPlaces,
    tripLogs,
    settingsRows,
    engagementRows,
  ];
}

typedef $$QuietPlacesTableCreateCompanionBuilder =
    QuietPlacesCompanion Function({
      required String id,
      required String name,
      required double latitude,
      required double longitude,
      required double radiusMeters,
      required int behaviour,
      Value<bool> enabled,
      required int createdAtMs,
      Value<int> rowid,
    });
typedef $$QuietPlacesTableUpdateCompanionBuilder =
    QuietPlacesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> radiusMeters,
      Value<int> behaviour,
      Value<bool> enabled,
      Value<int> createdAtMs,
      Value<int> rowid,
    });

class $$QuietPlacesTableFilterComposer
    extends Composer<_$AppDatabase, $QuietPlacesTable> {
  $$QuietPlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get behaviour => $composableBuilder(
    column: $table.behaviour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuietPlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuietPlacesTable> {
  $$QuietPlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get behaviour => $composableBuilder(
    column: $table.behaviour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuietPlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuietPlacesTable> {
  $$QuietPlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get behaviour =>
      $composableBuilder(column: $table.behaviour, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );
}

class $$QuietPlacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuietPlacesTable,
          QuietPlaceRow,
          $$QuietPlacesTableFilterComposer,
          $$QuietPlacesTableOrderingComposer,
          $$QuietPlacesTableAnnotationComposer,
          $$QuietPlacesTableCreateCompanionBuilder,
          $$QuietPlacesTableUpdateCompanionBuilder,
          (
            QuietPlaceRow,
            BaseReferences<_$AppDatabase, $QuietPlacesTable, QuietPlaceRow>,
          ),
          QuietPlaceRow,
          PrefetchHooks Function()
        > {
  $$QuietPlacesTableTableManager(_$AppDatabase db, $QuietPlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuietPlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuietPlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuietPlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> radiusMeters = const Value.absent(),
                Value<int> behaviour = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuietPlacesCompanion(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                behaviour: behaviour,
                enabled: enabled,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double latitude,
                required double longitude,
                required double radiusMeters,
                required int behaviour,
                Value<bool> enabled = const Value.absent(),
                required int createdAtMs,
                Value<int> rowid = const Value.absent(),
              }) => QuietPlacesCompanion.insert(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radiusMeters,
                behaviour: behaviour,
                enabled: enabled,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuietPlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuietPlacesTable,
      QuietPlaceRow,
      $$QuietPlacesTableFilterComposer,
      $$QuietPlacesTableOrderingComposer,
      $$QuietPlacesTableAnnotationComposer,
      $$QuietPlacesTableCreateCompanionBuilder,
      $$QuietPlacesTableUpdateCompanionBuilder,
      (
        QuietPlaceRow,
        BaseReferences<_$AppDatabase, $QuietPlacesTable, QuietPlaceRow>,
      ),
      QuietPlaceRow,
      PrefetchHooks Function()
    >;
typedef $$TripLogsTableCreateCompanionBuilder = TripLogsCompanion Function({
  Value<int> id,
  required String placeId,
  required String placeName,
  required int transition,
  required int action,
  Value<int?> behaviour,
  Value<String?> detail,
  required int timestampMs,
});
typedef $$TripLogsTableUpdateCompanionBuilder = TripLogsCompanion Function({
  Value<int> id,
  Value<String> placeId,
  Value<String> placeName,
  Value<int> transition,
  Value<int> action,
  Value<int?> behaviour,
  Value<String?> detail,
  Value<int> timestampMs,
});

class $$TripLogsTableFilterComposer
    extends Composer<_$AppDatabase, $TripLogsTable> {
  $$TripLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placeId => $composableBuilder(
    column: $table.placeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placeName => $composableBuilder(
    column: $table.placeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transition => $composableBuilder(
    column: $table.transition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get behaviour => $composableBuilder(
    column: $table.behaviour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TripLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripLogsTable> {
  $$TripLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placeId => $composableBuilder(
    column: $table.placeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placeName => $composableBuilder(
    column: $table.placeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transition => $composableBuilder(
    column: $table.transition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get behaviour => $composableBuilder(
    column: $table.behaviour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripLogsTable> {
  $$TripLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get placeId =>
      $composableBuilder(column: $table.placeId, builder: (column) => column);

  GeneratedColumn<String> get placeName =>
      $composableBuilder(column: $table.placeName, builder: (column) => column);

  GeneratedColumn<int> get transition => $composableBuilder(
    column: $table.transition,
    builder: (column) => column,
  );

  GeneratedColumn<int> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<int> get behaviour =>
      $composableBuilder(column: $table.behaviour, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<int> get timestampMs => $composableBuilder(
    column: $table.timestampMs,
    builder: (column) => column,
  );
}

class $$TripLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripLogsTable,
          TripLogRow,
          $$TripLogsTableFilterComposer,
          $$TripLogsTableOrderingComposer,
          $$TripLogsTableAnnotationComposer,
          $$TripLogsTableCreateCompanionBuilder,
          $$TripLogsTableUpdateCompanionBuilder,
          (
            TripLogRow,
            BaseReferences<_$AppDatabase, $TripLogsTable, TripLogRow>,
          ),
          TripLogRow,
          PrefetchHooks Function()
        > {
  $$TripLogsTableTableManager(_$AppDatabase db, $TripLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> placeId = const Value.absent(),
                Value<String> placeName = const Value.absent(),
                Value<int> transition = const Value.absent(),
                Value<int> action = const Value.absent(),
                Value<int?> behaviour = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                Value<int> timestampMs = const Value.absent(),
              }) => TripLogsCompanion(
                id: id,
                placeId: placeId,
                placeName: placeName,
                transition: transition,
                action: action,
                behaviour: behaviour,
                detail: detail,
                timestampMs: timestampMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String placeId,
                required String placeName,
                required int transition,
                required int action,
                Value<int?> behaviour = const Value.absent(),
                Value<String?> detail = const Value.absent(),
                required int timestampMs,
              }) => TripLogsCompanion.insert(
                id: id,
                placeId: placeId,
                placeName: placeName,
                transition: transition,
                action: action,
                behaviour: behaviour,
                detail: detail,
                timestampMs: timestampMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TripLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripLogsTable,
      TripLogRow,
      $$TripLogsTableFilterComposer,
      $$TripLogsTableOrderingComposer,
      $$TripLogsTableAnnotationComposer,
      $$TripLogsTableCreateCompanionBuilder,
      $$TripLogsTableUpdateCompanionBuilder,
      (TripLogRow, BaseReferences<_$AppDatabase, $TripLogsTable, TripLogRow>),
      TripLogRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsRowsTableCreateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<bool> globalPaused,
      Value<int?> snoozeUntilMs,
      Value<bool> onboardingComplete,
      Value<bool> gpsWarmupEnabled,
      Value<bool> mapsEnabled,
      Value<int> units,
      Value<String?> localeCode,
    });
typedef $$SettingsRowsTableUpdateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<bool> globalPaused,
      Value<int?> snoozeUntilMs,
      Value<bool> onboardingComplete,
      Value<bool> gpsWarmupEnabled,
      Value<bool> mapsEnabled,
      Value<int> units,
      Value<String?> localeCode,
    });

class $$SettingsRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get globalPaused => $composableBuilder(
    column: $table.globalPaused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeUntilMs => $composableBuilder(
    column: $table.snoozeUntilMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get gpsWarmupEnabled => $composableBuilder(
    column: $table.gpsWarmupEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mapsEnabled => $composableBuilder(
    column: $table.mapsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get globalPaused => $composableBuilder(
    column: $table.globalPaused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeUntilMs => $composableBuilder(
    column: $table.snoozeUntilMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get gpsWarmupEnabled => $composableBuilder(
    column: $table.gpsWarmupEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mapsEnabled => $composableBuilder(
    column: $table.mapsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get globalPaused => $composableBuilder(
    column: $table.globalPaused,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snoozeUntilMs => $composableBuilder(
    column: $table.snoozeUntilMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingComplete => $composableBuilder(
    column: $table.onboardingComplete,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get gpsWarmupEnabled => $composableBuilder(
    column: $table.gpsWarmupEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get mapsEnabled => $composableBuilder(
    column: $table.mapsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get units =>
      $composableBuilder(column: $table.units, builder: (column) => column);

  GeneratedColumn<String> get localeCode => $composableBuilder(
    column: $table.localeCode,
    builder: (column) => column,
  );
}

class $$SettingsRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsRowsTable,
          SettingsRow,
          $$SettingsRowsTableFilterComposer,
          $$SettingsRowsTableOrderingComposer,
          $$SettingsRowsTableAnnotationComposer,
          $$SettingsRowsTableCreateCompanionBuilder,
          $$SettingsRowsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $SettingsRowsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsRowsTableTableManager(_$AppDatabase db, $SettingsRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> globalPaused = const Value.absent(),
                Value<int?> snoozeUntilMs = const Value.absent(),
                Value<bool> onboardingComplete = const Value.absent(),
                Value<bool> gpsWarmupEnabled = const Value.absent(),
                Value<bool> mapsEnabled = const Value.absent(),
                Value<int> units = const Value.absent(),
                Value<String?> localeCode = const Value.absent(),
              }) => SettingsRowsCompanion(
                id: id,
                globalPaused: globalPaused,
                snoozeUntilMs: snoozeUntilMs,
                onboardingComplete: onboardingComplete,
                gpsWarmupEnabled: gpsWarmupEnabled,
                mapsEnabled: mapsEnabled,
                units: units,
                localeCode: localeCode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> globalPaused = const Value.absent(),
                Value<int?> snoozeUntilMs = const Value.absent(),
                Value<bool> onboardingComplete = const Value.absent(),
                Value<bool> gpsWarmupEnabled = const Value.absent(),
                Value<bool> mapsEnabled = const Value.absent(),
                Value<int> units = const Value.absent(),
                Value<String?> localeCode = const Value.absent(),
              }) => SettingsRowsCompanion.insert(
                id: id,
                globalPaused: globalPaused,
                snoozeUntilMs: snoozeUntilMs,
                onboardingComplete: onboardingComplete,
                gpsWarmupEnabled: gpsWarmupEnabled,
                mapsEnabled: mapsEnabled,
                units: units,
                localeCode: localeCode,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsRowsTable,
      SettingsRow,
      $$SettingsRowsTableFilterComposer,
      $$SettingsRowsTableOrderingComposer,
      $$SettingsRowsTableAnnotationComposer,
      $$SettingsRowsTableCreateCompanionBuilder,
      $$SettingsRowsTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$AppDatabase, $SettingsRowsTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;
typedef $$EngagementRowsTableCreateCompanionBuilder =
    EngagementRowsCompanion Function({
      Value<int> id,
      Value<String> activePlaceIds,
      required int capturedRinger,
      required bool capturedDnd,
      required int appliedBehaviour,
      required int appliedRinger,
      required bool appliedDnd,
      Value<bool> overridden,
      Value<int?> bootTimeMs,
    });
typedef $$EngagementRowsTableUpdateCompanionBuilder =
    EngagementRowsCompanion Function({
      Value<int> id,
      Value<String> activePlaceIds,
      Value<int> capturedRinger,
      Value<bool> capturedDnd,
      Value<int> appliedBehaviour,
      Value<int> appliedRinger,
      Value<bool> appliedDnd,
      Value<bool> overridden,
      Value<int?> bootTimeMs,
    });

class $$EngagementRowsTableFilterComposer
    extends Composer<_$AppDatabase, $EngagementRowsTable> {
  $$EngagementRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activePlaceIds => $composableBuilder(
    column: $table.activePlaceIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capturedRinger => $composableBuilder(
    column: $table.capturedRinger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get capturedDnd => $composableBuilder(
    column: $table.capturedDnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appliedBehaviour => $composableBuilder(
    column: $table.appliedBehaviour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appliedRinger => $composableBuilder(
    column: $table.appliedRinger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get appliedDnd => $composableBuilder(
    column: $table.appliedDnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get overridden => $composableBuilder(
    column: $table.overridden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bootTimeMs => $composableBuilder(
    column: $table.bootTimeMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EngagementRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $EngagementRowsTable> {
  $$EngagementRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activePlaceIds => $composableBuilder(
    column: $table.activePlaceIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capturedRinger => $composableBuilder(
    column: $table.capturedRinger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get capturedDnd => $composableBuilder(
    column: $table.capturedDnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedBehaviour => $composableBuilder(
    column: $table.appliedBehaviour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedRinger => $composableBuilder(
    column: $table.appliedRinger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get appliedDnd => $composableBuilder(
    column: $table.appliedDnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get overridden => $composableBuilder(
    column: $table.overridden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bootTimeMs => $composableBuilder(
    column: $table.bootTimeMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EngagementRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EngagementRowsTable> {
  $$EngagementRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activePlaceIds => $composableBuilder(
    column: $table.activePlaceIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get capturedRinger => $composableBuilder(
    column: $table.capturedRinger,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get capturedDnd => $composableBuilder(
    column: $table.capturedDnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get appliedBehaviour => $composableBuilder(
    column: $table.appliedBehaviour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get appliedRinger => $composableBuilder(
    column: $table.appliedRinger,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get appliedDnd => $composableBuilder(
    column: $table.appliedDnd,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get overridden => $composableBuilder(
    column: $table.overridden,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bootTimeMs => $composableBuilder(
    column: $table.bootTimeMs,
    builder: (column) => column,
  );
}

class $$EngagementRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EngagementRowsTable,
          EngagementRow,
          $$EngagementRowsTableFilterComposer,
          $$EngagementRowsTableOrderingComposer,
          $$EngagementRowsTableAnnotationComposer,
          $$EngagementRowsTableCreateCompanionBuilder,
          $$EngagementRowsTableUpdateCompanionBuilder,
          (
            EngagementRow,
            BaseReferences<_$AppDatabase, $EngagementRowsTable, EngagementRow>,
          ),
          EngagementRow,
          PrefetchHooks Function()
        > {
  $$EngagementRowsTableTableManager(
    _$AppDatabase db,
    $EngagementRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EngagementRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EngagementRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EngagementRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> activePlaceIds = const Value.absent(),
                Value<int> capturedRinger = const Value.absent(),
                Value<bool> capturedDnd = const Value.absent(),
                Value<int> appliedBehaviour = const Value.absent(),
                Value<int> appliedRinger = const Value.absent(),
                Value<bool> appliedDnd = const Value.absent(),
                Value<bool> overridden = const Value.absent(),
                Value<int?> bootTimeMs = const Value.absent(),
              }) => EngagementRowsCompanion(
                id: id,
                activePlaceIds: activePlaceIds,
                capturedRinger: capturedRinger,
                capturedDnd: capturedDnd,
                appliedBehaviour: appliedBehaviour,
                appliedRinger: appliedRinger,
                appliedDnd: appliedDnd,
                overridden: overridden,
                bootTimeMs: bootTimeMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> activePlaceIds = const Value.absent(),
                required int capturedRinger,
                required bool capturedDnd,
                required int appliedBehaviour,
                required int appliedRinger,
                required bool appliedDnd,
                Value<bool> overridden = const Value.absent(),
                Value<int?> bootTimeMs = const Value.absent(),
              }) => EngagementRowsCompanion.insert(
                id: id,
                activePlaceIds: activePlaceIds,
                capturedRinger: capturedRinger,
                capturedDnd: capturedDnd,
                appliedBehaviour: appliedBehaviour,
                appliedRinger: appliedRinger,
                appliedDnd: appliedDnd,
                overridden: overridden,
                bootTimeMs: bootTimeMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EngagementRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EngagementRowsTable,
      EngagementRow,
      $$EngagementRowsTableFilterComposer,
      $$EngagementRowsTableOrderingComposer,
      $$EngagementRowsTableAnnotationComposer,
      $$EngagementRowsTableCreateCompanionBuilder,
      $$EngagementRowsTableUpdateCompanionBuilder,
      (
        EngagementRow,
        BaseReferences<_$AppDatabase, $EngagementRowsTable, EngagementRow>,
      ),
      EngagementRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuietPlacesTableTableManager get quietPlaces =>
      $$QuietPlacesTableTableManager(_db, _db.quietPlaces);
  $$TripLogsTableTableManager get tripLogs =>
      $$TripLogsTableTableManager(_db, _db.tripLogs);
  $$SettingsRowsTableTableManager get settingsRows =>
      $$SettingsRowsTableTableManager(_db, _db.settingsRows);
  $$EngagementRowsTableTableManager get engagementRows =>
      $$EngagementRowsTableTableManager(_db, _db.engagementRows);
}
