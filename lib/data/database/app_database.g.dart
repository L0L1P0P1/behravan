// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VoidingSchedulesTable extends VoidingSchedules
    with TableInfo<$VoidingSchedulesTable, VoidingScheduleEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoidingSchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalMinutesMeta = const VerificationMeta(
    'intervalMinutes',
  );
  @override
  late final GeneratedColumn<int> intervalMinutes = GeneratedColumn<int>(
    'interval_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _daysOfWeekMeta = const VerificationMeta(
    'daysOfWeek',
  );
  @override
  late final GeneratedColumn<int> daysOfWeek = GeneratedColumn<int>(
    'days_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(127),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    startTime,
    endTime,
    intervalMinutes,
    isActive,
    daysOfWeek,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voiding_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoidingScheduleEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('interval_minutes')) {
      context.handle(
        _intervalMinutesMeta,
        intervalMinutes.isAcceptableOrUnknown(
          data['interval_minutes']!,
          _intervalMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalMinutesMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('days_of_week')) {
      context.handle(
        _daysOfWeekMeta,
        daysOfWeek.isAcceptableOrUnknown(
          data['days_of_week']!,
          _daysOfWeekMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoidingScheduleEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoidingScheduleEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
      intervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_minutes'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      daysOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_of_week'],
      )!,
    );
  }

  @override
  $VoidingSchedulesTable createAlias(String alias) {
    return $VoidingSchedulesTable(attachedDatabase, alias);
  }
}

class VoidingScheduleEntity extends DataClass
    implements Insertable<VoidingScheduleEntity> {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final int intervalMinutes;
  final bool isActive;
  final int daysOfWeek;
  const VoidingScheduleEntity({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.intervalMinutes,
    required this.isActive,
    required this.daysOfWeek,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    map['interval_minutes'] = Variable<int>(intervalMinutes);
    map['is_active'] = Variable<bool>(isActive);
    map['days_of_week'] = Variable<int>(daysOfWeek);
    return map;
  }

  VoidingSchedulesCompanion toCompanion(bool nullToAbsent) {
    return VoidingSchedulesCompanion(
      id: Value(id),
      title: Value(title),
      startTime: Value(startTime),
      endTime: Value(endTime),
      intervalMinutes: Value(intervalMinutes),
      isActive: Value(isActive),
      daysOfWeek: Value(daysOfWeek),
    );
  }

  factory VoidingScheduleEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoidingScheduleEntity(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      intervalMinutes: serializer.fromJson<int>(json['intervalMinutes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      daysOfWeek: serializer.fromJson<int>(json['daysOfWeek']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'intervalMinutes': serializer.toJson<int>(intervalMinutes),
      'isActive': serializer.toJson<bool>(isActive),
      'daysOfWeek': serializer.toJson<int>(daysOfWeek),
    };
  }

  VoidingScheduleEntity copyWith({
    String? id,
    String? title,
    String? startTime,
    String? endTime,
    int? intervalMinutes,
    bool? isActive,
    int? daysOfWeek,
  }) => VoidingScheduleEntity(
    id: id ?? this.id,
    title: title ?? this.title,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    isActive: isActive ?? this.isActive,
    daysOfWeek: daysOfWeek ?? this.daysOfWeek,
  );
  VoidingScheduleEntity copyWithCompanion(VoidingSchedulesCompanion data) {
    return VoidingScheduleEntity(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      intervalMinutes: data.intervalMinutes.present
          ? data.intervalMinutes.value
          : this.intervalMinutes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      daysOfWeek: data.daysOfWeek.present
          ? data.daysOfWeek.value
          : this.daysOfWeek,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoidingScheduleEntity(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('intervalMinutes: $intervalMinutes, ')
          ..write('isActive: $isActive, ')
          ..write('daysOfWeek: $daysOfWeek')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    startTime,
    endTime,
    intervalMinutes,
    isActive,
    daysOfWeek,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoidingScheduleEntity &&
          other.id == this.id &&
          other.title == this.title &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.intervalMinutes == this.intervalMinutes &&
          other.isActive == this.isActive &&
          other.daysOfWeek == this.daysOfWeek);
}

class VoidingSchedulesCompanion extends UpdateCompanion<VoidingScheduleEntity> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<int> intervalMinutes;
  final Value<bool> isActive;
  final Value<int> daysOfWeek;
  final Value<int> rowid;
  const VoidingSchedulesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.intervalMinutes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoidingSchedulesCompanion.insert({
    required String id,
    required String title,
    required String startTime,
    required String endTime,
    required int intervalMinutes,
    this.isActive = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       startTime = Value(startTime),
       endTime = Value(endTime),
       intervalMinutes = Value(intervalMinutes);
  static Insertable<VoidingScheduleEntity> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<int>? intervalMinutes,
    Expression<bool>? isActive,
    Expression<int>? daysOfWeek,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (intervalMinutes != null) 'interval_minutes': intervalMinutes,
      if (isActive != null) 'is_active': isActive,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoidingSchedulesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? startTime,
    Value<String>? endTime,
    Value<int>? intervalMinutes,
    Value<bool>? isActive,
    Value<int>? daysOfWeek,
    Value<int>? rowid,
  }) {
    return VoidingSchedulesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      isActive: isActive ?? this.isActive,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (intervalMinutes.present) {
      map['interval_minutes'] = Variable<int>(intervalMinutes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (daysOfWeek.present) {
      map['days_of_week'] = Variable<int>(daysOfWeek.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoidingSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('intervalMinutes: $intervalMinutes, ')
          ..write('isActive: $isActive, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoidingLogsTable extends VoidingLogs
    with TableInfo<$VoidingLogsTable, VoidingLogEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoidingLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urgencyLevelMeta = const VerificationMeta(
    'urgencyLevel',
  );
  @override
  late final GeneratedColumn<int> urgencyLevel = GeneratedColumn<int>(
    'urgency_level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _volumeEstimationMeta = const VerificationMeta(
    'volumeEstimation',
  );
  @override
  late final GeneratedColumn<String> volumeEstimation = GeneratedColumn<String>(
    'volume_estimation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    eventType,
    urgencyLevel,
    volumeEstimation,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voiding_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoidingLogEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('urgency_level')) {
      context.handle(
        _urgencyLevelMeta,
        urgencyLevel.isAcceptableOrUnknown(
          data['urgency_level']!,
          _urgencyLevelMeta,
        ),
      );
    }
    if (data.containsKey('volume_estimation')) {
      context.handle(
        _volumeEstimationMeta,
        volumeEstimation.isAcceptableOrUnknown(
          data['volume_estimation']!,
          _volumeEstimationMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoidingLogEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoidingLogEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      urgencyLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}urgency_level'],
      ),
      volumeEstimation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_estimation'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $VoidingLogsTable createAlias(String alias) {
    return $VoidingLogsTable(attachedDatabase, alias);
  }
}

class VoidingLogEntity extends DataClass
    implements Insertable<VoidingLogEntity> {
  final String id;
  final DateTime timestamp;
  final String eventType;
  final int? urgencyLevel;
  final String? volumeEstimation;
  final String? notes;
  const VoidingLogEntity({
    required this.id,
    required this.timestamp,
    required this.eventType,
    this.urgencyLevel,
    this.volumeEstimation,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || urgencyLevel != null) {
      map['urgency_level'] = Variable<int>(urgencyLevel);
    }
    if (!nullToAbsent || volumeEstimation != null) {
      map['volume_estimation'] = Variable<String>(volumeEstimation);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  VoidingLogsCompanion toCompanion(bool nullToAbsent) {
    return VoidingLogsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      eventType: Value(eventType),
      urgencyLevel: urgencyLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(urgencyLevel),
      volumeEstimation: volumeEstimation == null && nullToAbsent
          ? const Value.absent()
          : Value(volumeEstimation),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory VoidingLogEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoidingLogEntity(
      id: serializer.fromJson<String>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      eventType: serializer.fromJson<String>(json['eventType']),
      urgencyLevel: serializer.fromJson<int?>(json['urgencyLevel']),
      volumeEstimation: serializer.fromJson<String?>(json['volumeEstimation']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'eventType': serializer.toJson<String>(eventType),
      'urgencyLevel': serializer.toJson<int?>(urgencyLevel),
      'volumeEstimation': serializer.toJson<String?>(volumeEstimation),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  VoidingLogEntity copyWith({
    String? id,
    DateTime? timestamp,
    String? eventType,
    Value<int?> urgencyLevel = const Value.absent(),
    Value<String?> volumeEstimation = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => VoidingLogEntity(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    eventType: eventType ?? this.eventType,
    urgencyLevel: urgencyLevel.present ? urgencyLevel.value : this.urgencyLevel,
    volumeEstimation: volumeEstimation.present
        ? volumeEstimation.value
        : this.volumeEstimation,
    notes: notes.present ? notes.value : this.notes,
  );
  VoidingLogEntity copyWithCompanion(VoidingLogsCompanion data) {
    return VoidingLogEntity(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      urgencyLevel: data.urgencyLevel.present
          ? data.urgencyLevel.value
          : this.urgencyLevel,
      volumeEstimation: data.volumeEstimation.present
          ? data.volumeEstimation.value
          : this.volumeEstimation,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoidingLogEntity(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('eventType: $eventType, ')
          ..write('urgencyLevel: $urgencyLevel, ')
          ..write('volumeEstimation: $volumeEstimation, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    eventType,
    urgencyLevel,
    volumeEstimation,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoidingLogEntity &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.eventType == this.eventType &&
          other.urgencyLevel == this.urgencyLevel &&
          other.volumeEstimation == this.volumeEstimation &&
          other.notes == this.notes);
}

class VoidingLogsCompanion extends UpdateCompanion<VoidingLogEntity> {
  final Value<String> id;
  final Value<DateTime> timestamp;
  final Value<String> eventType;
  final Value<int?> urgencyLevel;
  final Value<String?> volumeEstimation;
  final Value<String?> notes;
  final Value<int> rowid;
  const VoidingLogsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.eventType = const Value.absent(),
    this.urgencyLevel = const Value.absent(),
    this.volumeEstimation = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoidingLogsCompanion.insert({
    required String id,
    required DateTime timestamp,
    required String eventType,
    this.urgencyLevel = const Value.absent(),
    this.volumeEstimation = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       timestamp = Value(timestamp),
       eventType = Value(eventType);
  static Insertable<VoidingLogEntity> custom({
    Expression<String>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? eventType,
    Expression<int>? urgencyLevel,
    Expression<String>? volumeEstimation,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (eventType != null) 'event_type': eventType,
      if (urgencyLevel != null) 'urgency_level': urgencyLevel,
      if (volumeEstimation != null) 'volume_estimation': volumeEstimation,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoidingLogsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? timestamp,
    Value<String>? eventType,
    Value<int?>? urgencyLevel,
    Value<String?>? volumeEstimation,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return VoidingLogsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      eventType: eventType ?? this.eventType,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      volumeEstimation: volumeEstimation ?? this.volumeEstimation,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (urgencyLevel.present) {
      map['urgency_level'] = Variable<int>(urgencyLevel.value);
    }
    if (volumeEstimation.present) {
      map['volume_estimation'] = Variable<String>(volumeEstimation.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoidingLogsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('eventType: $eventType, ')
          ..write('urgencyLevel: $urgencyLevel, ')
          ..write('volumeEstimation: $volumeEstimation, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnuresisLogsTable extends EnuresisLogs
    with TableInfo<$EnuresisLogsTable, EnuresisLogEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnuresisLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDryMeta = const VerificationMeta('isDry');
  @override
  late final GeneratedColumn<bool> isDry = GeneratedColumn<bool>(
    'is_dry',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dry" IN (0, 1))',
    ),
  );
  static const VerificationMeta _wokeToPeeMeta = const VerificationMeta(
    'wokeToPee',
  );
  @override
  late final GeneratedColumn<bool> wokeToPee = GeneratedColumn<bool>(
    'woke_to_pee',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("woke_to_pee" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _eveningFluidRestrictionMeta =
      const VerificationMeta('eveningFluidRestriction');
  @override
  late final GeneratedColumn<bool> eveningFluidRestriction =
      GeneratedColumn<bool>(
        'evening_fluid_restriction',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("evening_fluid_restriction" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    isDry,
    wokeToPee,
    eveningFluidRestriction,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'enuresis_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnuresisLogEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_dry')) {
      context.handle(
        _isDryMeta,
        isDry.isAcceptableOrUnknown(data['is_dry']!, _isDryMeta),
      );
    } else if (isInserting) {
      context.missing(_isDryMeta);
    }
    if (data.containsKey('woke_to_pee')) {
      context.handle(
        _wokeToPeeMeta,
        wokeToPee.isAcceptableOrUnknown(data['woke_to_pee']!, _wokeToPeeMeta),
      );
    }
    if (data.containsKey('evening_fluid_restriction')) {
      context.handle(
        _eveningFluidRestrictionMeta,
        eveningFluidRestriction.isAcceptableOrUnknown(
          data['evening_fluid_restriction']!,
          _eveningFluidRestrictionMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnuresisLogEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnuresisLogEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      isDry: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dry'],
      )!,
      wokeToPee: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}woke_to_pee'],
      )!,
      eveningFluidRestriction: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}evening_fluid_restriction'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $EnuresisLogsTable createAlias(String alias) {
    return $EnuresisLogsTable(attachedDatabase, alias);
  }
}

class EnuresisLogEntity extends DataClass
    implements Insertable<EnuresisLogEntity> {
  final String id;
  final String date;
  final bool isDry;
  final bool wokeToPee;
  final bool eveningFluidRestriction;
  final String? notes;
  const EnuresisLogEntity({
    required this.id,
    required this.date,
    required this.isDry,
    required this.wokeToPee,
    required this.eveningFluidRestriction,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['is_dry'] = Variable<bool>(isDry);
    map['woke_to_pee'] = Variable<bool>(wokeToPee);
    map['evening_fluid_restriction'] = Variable<bool>(eveningFluidRestriction);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  EnuresisLogsCompanion toCompanion(bool nullToAbsent) {
    return EnuresisLogsCompanion(
      id: Value(id),
      date: Value(date),
      isDry: Value(isDry),
      wokeToPee: Value(wokeToPee),
      eveningFluidRestriction: Value(eveningFluidRestriction),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory EnuresisLogEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnuresisLogEntity(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      isDry: serializer.fromJson<bool>(json['isDry']),
      wokeToPee: serializer.fromJson<bool>(json['wokeToPee']),
      eveningFluidRestriction: serializer.fromJson<bool>(
        json['eveningFluidRestriction'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'isDry': serializer.toJson<bool>(isDry),
      'wokeToPee': serializer.toJson<bool>(wokeToPee),
      'eveningFluidRestriction': serializer.toJson<bool>(
        eveningFluidRestriction,
      ),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  EnuresisLogEntity copyWith({
    String? id,
    String? date,
    bool? isDry,
    bool? wokeToPee,
    bool? eveningFluidRestriction,
    Value<String?> notes = const Value.absent(),
  }) => EnuresisLogEntity(
    id: id ?? this.id,
    date: date ?? this.date,
    isDry: isDry ?? this.isDry,
    wokeToPee: wokeToPee ?? this.wokeToPee,
    eveningFluidRestriction:
        eveningFluidRestriction ?? this.eveningFluidRestriction,
    notes: notes.present ? notes.value : this.notes,
  );
  EnuresisLogEntity copyWithCompanion(EnuresisLogsCompanion data) {
    return EnuresisLogEntity(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      isDry: data.isDry.present ? data.isDry.value : this.isDry,
      wokeToPee: data.wokeToPee.present ? data.wokeToPee.value : this.wokeToPee,
      eveningFluidRestriction: data.eveningFluidRestriction.present
          ? data.eveningFluidRestriction.value
          : this.eveningFluidRestriction,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnuresisLogEntity(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('isDry: $isDry, ')
          ..write('wokeToPee: $wokeToPee, ')
          ..write('eveningFluidRestriction: $eveningFluidRestriction, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, isDry, wokeToPee, eveningFluidRestriction, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnuresisLogEntity &&
          other.id == this.id &&
          other.date == this.date &&
          other.isDry == this.isDry &&
          other.wokeToPee == this.wokeToPee &&
          other.eveningFluidRestriction == this.eveningFluidRestriction &&
          other.notes == this.notes);
}

class EnuresisLogsCompanion extends UpdateCompanion<EnuresisLogEntity> {
  final Value<String> id;
  final Value<String> date;
  final Value<bool> isDry;
  final Value<bool> wokeToPee;
  final Value<bool> eveningFluidRestriction;
  final Value<String?> notes;
  final Value<int> rowid;
  const EnuresisLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.isDry = const Value.absent(),
    this.wokeToPee = const Value.absent(),
    this.eveningFluidRestriction = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnuresisLogsCompanion.insert({
    required String id,
    required String date,
    required bool isDry,
    this.wokeToPee = const Value.absent(),
    this.eveningFluidRestriction = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       isDry = Value(isDry);
  static Insertable<EnuresisLogEntity> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<bool>? isDry,
    Expression<bool>? wokeToPee,
    Expression<bool>? eveningFluidRestriction,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (isDry != null) 'is_dry': isDry,
      if (wokeToPee != null) 'woke_to_pee': wokeToPee,
      if (eveningFluidRestriction != null)
        'evening_fluid_restriction': eveningFluidRestriction,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnuresisLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<bool>? isDry,
    Value<bool>? wokeToPee,
    Value<bool>? eveningFluidRestriction,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return EnuresisLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      isDry: isDry ?? this.isDry,
      wokeToPee: wokeToPee ?? this.wokeToPee,
      eveningFluidRestriction:
          eveningFluidRestriction ?? this.eveningFluidRestriction,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (isDry.present) {
      map['is_dry'] = Variable<bool>(isDry.value);
    }
    if (wokeToPee.present) {
      map['woke_to_pee'] = Variable<bool>(wokeToPee.value);
    }
    if (eveningFluidRestriction.present) {
      map['evening_fluid_restriction'] = Variable<bool>(
        eveningFluidRestriction.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnuresisLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('isDry: $isDry, ')
          ..write('wokeToPee: $wokeToPee, ')
          ..write('eveningFluidRestriction: $eveningFluidRestriction, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BowelLogsTable extends BowelLogs
    with TableInfo<$BowelLogsTable, BowelLogEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BowelLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bristolTypeMeta = const VerificationMeta(
    'bristolType',
  );
  @override
  late final GeneratedColumn<int> bristolType = GeneratedColumn<int>(
    'bristol_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strainingLevelMeta = const VerificationMeta(
    'strainingLevel',
  );
  @override
  late final GeneratedColumn<int> strainingLevel = GeneratedColumn<int>(
    'straining_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _bloodPresentMeta = const VerificationMeta(
    'bloodPresent',
  );
  @override
  late final GeneratedColumn<bool> bloodPresent = GeneratedColumn<bool>(
    'blood_present',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("blood_present" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _soilingAccidentMeta = const VerificationMeta(
    'soilingAccident',
  );
  @override
  late final GeneratedColumn<bool> soilingAccident = GeneratedColumn<bool>(
    'soiling_accident',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("soiling_accident" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    bristolType,
    strainingLevel,
    bloodPresent,
    soilingAccident,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bowel_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<BowelLogEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('bristol_type')) {
      context.handle(
        _bristolTypeMeta,
        bristolType.isAcceptableOrUnknown(
          data['bristol_type']!,
          _bristolTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bristolTypeMeta);
    }
    if (data.containsKey('straining_level')) {
      context.handle(
        _strainingLevelMeta,
        strainingLevel.isAcceptableOrUnknown(
          data['straining_level']!,
          _strainingLevelMeta,
        ),
      );
    }
    if (data.containsKey('blood_present')) {
      context.handle(
        _bloodPresentMeta,
        bloodPresent.isAcceptableOrUnknown(
          data['blood_present']!,
          _bloodPresentMeta,
        ),
      );
    }
    if (data.containsKey('soiling_accident')) {
      context.handle(
        _soilingAccidentMeta,
        soilingAccident.isAcceptableOrUnknown(
          data['soiling_accident']!,
          _soilingAccidentMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BowelLogEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BowelLogEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      bristolType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bristol_type'],
      )!,
      strainingLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}straining_level'],
      )!,
      bloodPresent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}blood_present'],
      )!,
      soilingAccident: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}soiling_accident'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $BowelLogsTable createAlias(String alias) {
    return $BowelLogsTable(attachedDatabase, alias);
  }
}

class BowelLogEntity extends DataClass implements Insertable<BowelLogEntity> {
  final String id;
  final DateTime timestamp;
  final int bristolType;
  final int strainingLevel;
  final bool bloodPresent;
  final bool soilingAccident;
  final String? notes;
  const BowelLogEntity({
    required this.id,
    required this.timestamp,
    required this.bristolType,
    required this.strainingLevel,
    required this.bloodPresent,
    required this.soilingAccident,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['bristol_type'] = Variable<int>(bristolType);
    map['straining_level'] = Variable<int>(strainingLevel);
    map['blood_present'] = Variable<bool>(bloodPresent);
    map['soiling_accident'] = Variable<bool>(soilingAccident);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  BowelLogsCompanion toCompanion(bool nullToAbsent) {
    return BowelLogsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      bristolType: Value(bristolType),
      strainingLevel: Value(strainingLevel),
      bloodPresent: Value(bloodPresent),
      soilingAccident: Value(soilingAccident),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory BowelLogEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BowelLogEntity(
      id: serializer.fromJson<String>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      bristolType: serializer.fromJson<int>(json['bristolType']),
      strainingLevel: serializer.fromJson<int>(json['strainingLevel']),
      bloodPresent: serializer.fromJson<bool>(json['bloodPresent']),
      soilingAccident: serializer.fromJson<bool>(json['soilingAccident']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'bristolType': serializer.toJson<int>(bristolType),
      'strainingLevel': serializer.toJson<int>(strainingLevel),
      'bloodPresent': serializer.toJson<bool>(bloodPresent),
      'soilingAccident': serializer.toJson<bool>(soilingAccident),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  BowelLogEntity copyWith({
    String? id,
    DateTime? timestamp,
    int? bristolType,
    int? strainingLevel,
    bool? bloodPresent,
    bool? soilingAccident,
    Value<String?> notes = const Value.absent(),
  }) => BowelLogEntity(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    bristolType: bristolType ?? this.bristolType,
    strainingLevel: strainingLevel ?? this.strainingLevel,
    bloodPresent: bloodPresent ?? this.bloodPresent,
    soilingAccident: soilingAccident ?? this.soilingAccident,
    notes: notes.present ? notes.value : this.notes,
  );
  BowelLogEntity copyWithCompanion(BowelLogsCompanion data) {
    return BowelLogEntity(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      bristolType: data.bristolType.present
          ? data.bristolType.value
          : this.bristolType,
      strainingLevel: data.strainingLevel.present
          ? data.strainingLevel.value
          : this.strainingLevel,
      bloodPresent: data.bloodPresent.present
          ? data.bloodPresent.value
          : this.bloodPresent,
      soilingAccident: data.soilingAccident.present
          ? data.soilingAccident.value
          : this.soilingAccident,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BowelLogEntity(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('bristolType: $bristolType, ')
          ..write('strainingLevel: $strainingLevel, ')
          ..write('bloodPresent: $bloodPresent, ')
          ..write('soilingAccident: $soilingAccident, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    bristolType,
    strainingLevel,
    bloodPresent,
    soilingAccident,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BowelLogEntity &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.bristolType == this.bristolType &&
          other.strainingLevel == this.strainingLevel &&
          other.bloodPresent == this.bloodPresent &&
          other.soilingAccident == this.soilingAccident &&
          other.notes == this.notes);
}

class BowelLogsCompanion extends UpdateCompanion<BowelLogEntity> {
  final Value<String> id;
  final Value<DateTime> timestamp;
  final Value<int> bristolType;
  final Value<int> strainingLevel;
  final Value<bool> bloodPresent;
  final Value<bool> soilingAccident;
  final Value<String?> notes;
  final Value<int> rowid;
  const BowelLogsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.bristolType = const Value.absent(),
    this.strainingLevel = const Value.absent(),
    this.bloodPresent = const Value.absent(),
    this.soilingAccident = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BowelLogsCompanion.insert({
    required String id,
    required DateTime timestamp,
    required int bristolType,
    this.strainingLevel = const Value.absent(),
    this.bloodPresent = const Value.absent(),
    this.soilingAccident = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       timestamp = Value(timestamp),
       bristolType = Value(bristolType);
  static Insertable<BowelLogEntity> custom({
    Expression<String>? id,
    Expression<DateTime>? timestamp,
    Expression<int>? bristolType,
    Expression<int>? strainingLevel,
    Expression<bool>? bloodPresent,
    Expression<bool>? soilingAccident,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (bristolType != null) 'bristol_type': bristolType,
      if (strainingLevel != null) 'straining_level': strainingLevel,
      if (bloodPresent != null) 'blood_present': bloodPresent,
      if (soilingAccident != null) 'soiling_accident': soilingAccident,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BowelLogsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? timestamp,
    Value<int>? bristolType,
    Value<int>? strainingLevel,
    Value<bool>? bloodPresent,
    Value<bool>? soilingAccident,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return BowelLogsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      bristolType: bristolType ?? this.bristolType,
      strainingLevel: strainingLevel ?? this.strainingLevel,
      bloodPresent: bloodPresent ?? this.bloodPresent,
      soilingAccident: soilingAccident ?? this.soilingAccident,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (bristolType.present) {
      map['bristol_type'] = Variable<int>(bristolType.value);
    }
    if (strainingLevel.present) {
      map['straining_level'] = Variable<int>(strainingLevel.value);
    }
    if (bloodPresent.present) {
      map['blood_present'] = Variable<bool>(bloodPresent.value);
    }
    if (soilingAccident.present) {
      map['soiling_accident'] = Variable<bool>(soilingAccident.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BowelLogsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('bristolType: $bristolType, ')
          ..write('strainingLevel: $strainingLevel, ')
          ..write('bloodPresent: $bloodPresent, ')
          ..write('soilingAccident: $soilingAccident, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VoidingSchedulesTable voidingSchedules = $VoidingSchedulesTable(
    this,
  );
  late final $VoidingLogsTable voidingLogs = $VoidingLogsTable(this);
  late final $EnuresisLogsTable enuresisLogs = $EnuresisLogsTable(this);
  late final $BowelLogsTable bowelLogs = $BowelLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    voidingSchedules,
    voidingLogs,
    enuresisLogs,
    bowelLogs,
  ];
}

typedef $$VoidingSchedulesTableCreateCompanionBuilder =
    VoidingSchedulesCompanion Function({
      required String id,
      required String title,
      required String startTime,
      required String endTime,
      required int intervalMinutes,
      Value<bool> isActive,
      Value<int> daysOfWeek,
      Value<int> rowid,
    });
typedef $$VoidingSchedulesTableUpdateCompanionBuilder =
    VoidingSchedulesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> startTime,
      Value<String> endTime,
      Value<int> intervalMinutes,
      Value<bool> isActive,
      Value<int> daysOfWeek,
      Value<int> rowid,
    });

class $$VoidingSchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $VoidingSchedulesTable> {
  $$VoidingSchedulesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalMinutes => $composableBuilder(
    column: $table.intervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VoidingSchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $VoidingSchedulesTable> {
  $$VoidingSchedulesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalMinutes => $composableBuilder(
    column: $table.intervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VoidingSchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VoidingSchedulesTable> {
  $$VoidingSchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get intervalMinutes => $composableBuilder(
    column: $table.intervalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => column,
  );
}

class $$VoidingSchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VoidingSchedulesTable,
          VoidingScheduleEntity,
          $$VoidingSchedulesTableFilterComposer,
          $$VoidingSchedulesTableOrderingComposer,
          $$VoidingSchedulesTableAnnotationComposer,
          $$VoidingSchedulesTableCreateCompanionBuilder,
          $$VoidingSchedulesTableUpdateCompanionBuilder,
          (
            VoidingScheduleEntity,
            BaseReferences<
              _$AppDatabase,
              $VoidingSchedulesTable,
              VoidingScheduleEntity
            >,
          ),
          VoidingScheduleEntity,
          PrefetchHooks Function()
        > {
  $$VoidingSchedulesTableTableManager(
    _$AppDatabase db,
    $VoidingSchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoidingSchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoidingSchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoidingSchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String> endTime = const Value.absent(),
                Value<int> intervalMinutes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> daysOfWeek = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoidingSchedulesCompanion(
                id: id,
                title: title,
                startTime: startTime,
                endTime: endTime,
                intervalMinutes: intervalMinutes,
                isActive: isActive,
                daysOfWeek: daysOfWeek,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String startTime,
                required String endTime,
                required int intervalMinutes,
                Value<bool> isActive = const Value.absent(),
                Value<int> daysOfWeek = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoidingSchedulesCompanion.insert(
                id: id,
                title: title,
                startTime: startTime,
                endTime: endTime,
                intervalMinutes: intervalMinutes,
                isActive: isActive,
                daysOfWeek: daysOfWeek,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VoidingSchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VoidingSchedulesTable,
      VoidingScheduleEntity,
      $$VoidingSchedulesTableFilterComposer,
      $$VoidingSchedulesTableOrderingComposer,
      $$VoidingSchedulesTableAnnotationComposer,
      $$VoidingSchedulesTableCreateCompanionBuilder,
      $$VoidingSchedulesTableUpdateCompanionBuilder,
      (
        VoidingScheduleEntity,
        BaseReferences<
          _$AppDatabase,
          $VoidingSchedulesTable,
          VoidingScheduleEntity
        >,
      ),
      VoidingScheduleEntity,
      PrefetchHooks Function()
    >;
typedef $$VoidingLogsTableCreateCompanionBuilder =
    VoidingLogsCompanion Function({
      required String id,
      required DateTime timestamp,
      required String eventType,
      Value<int?> urgencyLevel,
      Value<String?> volumeEstimation,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$VoidingLogsTableUpdateCompanionBuilder =
    VoidingLogsCompanion Function({
      Value<String> id,
      Value<DateTime> timestamp,
      Value<String> eventType,
      Value<int?> urgencyLevel,
      Value<String?> volumeEstimation,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$VoidingLogsTableFilterComposer
    extends Composer<_$AppDatabase, $VoidingLogsTable> {
  $$VoidingLogsTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get urgencyLevel => $composableBuilder(
    column: $table.urgencyLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get volumeEstimation => $composableBuilder(
    column: $table.volumeEstimation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VoidingLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $VoidingLogsTable> {
  $$VoidingLogsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get urgencyLevel => $composableBuilder(
    column: $table.urgencyLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get volumeEstimation => $composableBuilder(
    column: $table.volumeEstimation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VoidingLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VoidingLogsTable> {
  $$VoidingLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<int> get urgencyLevel => $composableBuilder(
    column: $table.urgencyLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get volumeEstimation => $composableBuilder(
    column: $table.volumeEstimation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$VoidingLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VoidingLogsTable,
          VoidingLogEntity,
          $$VoidingLogsTableFilterComposer,
          $$VoidingLogsTableOrderingComposer,
          $$VoidingLogsTableAnnotationComposer,
          $$VoidingLogsTableCreateCompanionBuilder,
          $$VoidingLogsTableUpdateCompanionBuilder,
          (
            VoidingLogEntity,
            BaseReferences<_$AppDatabase, $VoidingLogsTable, VoidingLogEntity>,
          ),
          VoidingLogEntity,
          PrefetchHooks Function()
        > {
  $$VoidingLogsTableTableManager(_$AppDatabase db, $VoidingLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoidingLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoidingLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoidingLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<int?> urgencyLevel = const Value.absent(),
                Value<String?> volumeEstimation = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoidingLogsCompanion(
                id: id,
                timestamp: timestamp,
                eventType: eventType,
                urgencyLevel: urgencyLevel,
                volumeEstimation: volumeEstimation,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime timestamp,
                required String eventType,
                Value<int?> urgencyLevel = const Value.absent(),
                Value<String?> volumeEstimation = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoidingLogsCompanion.insert(
                id: id,
                timestamp: timestamp,
                eventType: eventType,
                urgencyLevel: urgencyLevel,
                volumeEstimation: volumeEstimation,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VoidingLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VoidingLogsTable,
      VoidingLogEntity,
      $$VoidingLogsTableFilterComposer,
      $$VoidingLogsTableOrderingComposer,
      $$VoidingLogsTableAnnotationComposer,
      $$VoidingLogsTableCreateCompanionBuilder,
      $$VoidingLogsTableUpdateCompanionBuilder,
      (
        VoidingLogEntity,
        BaseReferences<_$AppDatabase, $VoidingLogsTable, VoidingLogEntity>,
      ),
      VoidingLogEntity,
      PrefetchHooks Function()
    >;
typedef $$EnuresisLogsTableCreateCompanionBuilder =
    EnuresisLogsCompanion Function({
      required String id,
      required String date,
      required bool isDry,
      Value<bool> wokeToPee,
      Value<bool> eveningFluidRestriction,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$EnuresisLogsTableUpdateCompanionBuilder =
    EnuresisLogsCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<bool> isDry,
      Value<bool> wokeToPee,
      Value<bool> eveningFluidRestriction,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$EnuresisLogsTableFilterComposer
    extends Composer<_$AppDatabase, $EnuresisLogsTable> {
  $$EnuresisLogsTableFilterComposer({
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

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDry => $composableBuilder(
    column: $table.isDry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wokeToPee => $composableBuilder(
    column: $table.wokeToPee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get eveningFluidRestriction => $composableBuilder(
    column: $table.eveningFluidRestriction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnuresisLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $EnuresisLogsTable> {
  $$EnuresisLogsTableOrderingComposer({
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

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDry => $composableBuilder(
    column: $table.isDry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wokeToPee => $composableBuilder(
    column: $table.wokeToPee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get eveningFluidRestriction => $composableBuilder(
    column: $table.eveningFluidRestriction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnuresisLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnuresisLogsTable> {
  $$EnuresisLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isDry =>
      $composableBuilder(column: $table.isDry, builder: (column) => column);

  GeneratedColumn<bool> get wokeToPee =>
      $composableBuilder(column: $table.wokeToPee, builder: (column) => column);

  GeneratedColumn<bool> get eveningFluidRestriction => $composableBuilder(
    column: $table.eveningFluidRestriction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$EnuresisLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EnuresisLogsTable,
          EnuresisLogEntity,
          $$EnuresisLogsTableFilterComposer,
          $$EnuresisLogsTableOrderingComposer,
          $$EnuresisLogsTableAnnotationComposer,
          $$EnuresisLogsTableCreateCompanionBuilder,
          $$EnuresisLogsTableUpdateCompanionBuilder,
          (
            EnuresisLogEntity,
            BaseReferences<
              _$AppDatabase,
              $EnuresisLogsTable,
              EnuresisLogEntity
            >,
          ),
          EnuresisLogEntity,
          PrefetchHooks Function()
        > {
  $$EnuresisLogsTableTableManager(_$AppDatabase db, $EnuresisLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnuresisLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnuresisLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnuresisLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<bool> isDry = const Value.absent(),
                Value<bool> wokeToPee = const Value.absent(),
                Value<bool> eveningFluidRestriction = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnuresisLogsCompanion(
                id: id,
                date: date,
                isDry: isDry,
                wokeToPee: wokeToPee,
                eveningFluidRestriction: eveningFluidRestriction,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required bool isDry,
                Value<bool> wokeToPee = const Value.absent(),
                Value<bool> eveningFluidRestriction = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnuresisLogsCompanion.insert(
                id: id,
                date: date,
                isDry: isDry,
                wokeToPee: wokeToPee,
                eveningFluidRestriction: eveningFluidRestriction,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnuresisLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EnuresisLogsTable,
      EnuresisLogEntity,
      $$EnuresisLogsTableFilterComposer,
      $$EnuresisLogsTableOrderingComposer,
      $$EnuresisLogsTableAnnotationComposer,
      $$EnuresisLogsTableCreateCompanionBuilder,
      $$EnuresisLogsTableUpdateCompanionBuilder,
      (
        EnuresisLogEntity,
        BaseReferences<_$AppDatabase, $EnuresisLogsTable, EnuresisLogEntity>,
      ),
      EnuresisLogEntity,
      PrefetchHooks Function()
    >;
typedef $$BowelLogsTableCreateCompanionBuilder =
    BowelLogsCompanion Function({
      required String id,
      required DateTime timestamp,
      required int bristolType,
      Value<int> strainingLevel,
      Value<bool> bloodPresent,
      Value<bool> soilingAccident,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$BowelLogsTableUpdateCompanionBuilder =
    BowelLogsCompanion Function({
      Value<String> id,
      Value<DateTime> timestamp,
      Value<int> bristolType,
      Value<int> strainingLevel,
      Value<bool> bloodPresent,
      Value<bool> soilingAccident,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$BowelLogsTableFilterComposer
    extends Composer<_$AppDatabase, $BowelLogsTable> {
  $$BowelLogsTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bristolType => $composableBuilder(
    column: $table.bristolType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strainingLevel => $composableBuilder(
    column: $table.strainingLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bloodPresent => $composableBuilder(
    column: $table.bloodPresent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get soilingAccident => $composableBuilder(
    column: $table.soilingAccident,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BowelLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $BowelLogsTable> {
  $$BowelLogsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bristolType => $composableBuilder(
    column: $table.bristolType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strainingLevel => $composableBuilder(
    column: $table.strainingLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bloodPresent => $composableBuilder(
    column: $table.bloodPresent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get soilingAccident => $composableBuilder(
    column: $table.soilingAccident,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BowelLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BowelLogsTable> {
  $$BowelLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get bristolType => $composableBuilder(
    column: $table.bristolType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get strainingLevel => $composableBuilder(
    column: $table.strainingLevel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bloodPresent => $composableBuilder(
    column: $table.bloodPresent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get soilingAccident => $composableBuilder(
    column: $table.soilingAccident,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$BowelLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BowelLogsTable,
          BowelLogEntity,
          $$BowelLogsTableFilterComposer,
          $$BowelLogsTableOrderingComposer,
          $$BowelLogsTableAnnotationComposer,
          $$BowelLogsTableCreateCompanionBuilder,
          $$BowelLogsTableUpdateCompanionBuilder,
          (
            BowelLogEntity,
            BaseReferences<_$AppDatabase, $BowelLogsTable, BowelLogEntity>,
          ),
          BowelLogEntity,
          PrefetchHooks Function()
        > {
  $$BowelLogsTableTableManager(_$AppDatabase db, $BowelLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BowelLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BowelLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BowelLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> bristolType = const Value.absent(),
                Value<int> strainingLevel = const Value.absent(),
                Value<bool> bloodPresent = const Value.absent(),
                Value<bool> soilingAccident = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BowelLogsCompanion(
                id: id,
                timestamp: timestamp,
                bristolType: bristolType,
                strainingLevel: strainingLevel,
                bloodPresent: bloodPresent,
                soilingAccident: soilingAccident,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime timestamp,
                required int bristolType,
                Value<int> strainingLevel = const Value.absent(),
                Value<bool> bloodPresent = const Value.absent(),
                Value<bool> soilingAccident = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BowelLogsCompanion.insert(
                id: id,
                timestamp: timestamp,
                bristolType: bristolType,
                strainingLevel: strainingLevel,
                bloodPresent: bloodPresent,
                soilingAccident: soilingAccident,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BowelLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BowelLogsTable,
      BowelLogEntity,
      $$BowelLogsTableFilterComposer,
      $$BowelLogsTableOrderingComposer,
      $$BowelLogsTableAnnotationComposer,
      $$BowelLogsTableCreateCompanionBuilder,
      $$BowelLogsTableUpdateCompanionBuilder,
      (
        BowelLogEntity,
        BaseReferences<_$AppDatabase, $BowelLogsTable, BowelLogEntity>,
      ),
      BowelLogEntity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VoidingSchedulesTableTableManager get voidingSchedules =>
      $$VoidingSchedulesTableTableManager(_db, _db.voidingSchedules);
  $$VoidingLogsTableTableManager get voidingLogs =>
      $$VoidingLogsTableTableManager(_db, _db.voidingLogs);
  $$EnuresisLogsTableTableManager get enuresisLogs =>
      $$EnuresisLogsTableTableManager(_db, _db.enuresisLogs);
  $$BowelLogsTableTableManager get bowelLogs =>
      $$BowelLogsTableTableManager(_db, _db.bowelLogs);
}
