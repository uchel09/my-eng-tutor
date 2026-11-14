// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LevelsTable extends Levels with TableInfo<$LevelsTable, Level> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LevelsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minPassScoreMeta = const VerificationMeta(
    'minPassScore',
  );
  @override
  late final GeneratedColumn<int> minPassScore = GeneratedColumn<int>(
    'min_pass_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(70),
  );
  static const VerificationMeta _isUnlockedMeta = const VerificationMeta(
    'isUnlocked',
  );
  @override
  late final GeneratedColumn<bool> isUnlocked = GeneratedColumn<bool>(
    'is_unlocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unlocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    title,
    description,
    orderIndex,
    minPassScore,
    isUnlocked,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'levels';
  @override
  VerificationContext validateIntegrity(
    Insertable<Level> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('min_pass_score')) {
      context.handle(
        _minPassScoreMeta,
        minPassScore.isAcceptableOrUnknown(
          data['min_pass_score']!,
          _minPassScoreMeta,
        ),
      );
    }
    if (data.containsKey('is_unlocked')) {
      context.handle(
        _isUnlockedMeta,
        isUnlocked.isAcceptableOrUnknown(data['is_unlocked']!, _isUnlockedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Level map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Level(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      minPassScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_pass_score'],
      )!,
      isUnlocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unlocked'],
      )!,
    );
  }

  @override
  $LevelsTable createAlias(String alias) {
    return $LevelsTable(attachedDatabase, alias);
  }
}

class Level extends DataClass implements Insertable<Level> {
  final int id;
  final String code;
  final String title;
  final String description;
  final int orderIndex;
  final int minPassScore;
  final bool isUnlocked;
  const Level({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.minPassScore,
    required this.isUnlocked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['order_index'] = Variable<int>(orderIndex);
    map['min_pass_score'] = Variable<int>(minPassScore);
    map['is_unlocked'] = Variable<bool>(isUnlocked);
    return map;
  }

  LevelsCompanion toCompanion(bool nullToAbsent) {
    return LevelsCompanion(
      id: Value(id),
      code: Value(code),
      title: Value(title),
      description: Value(description),
      orderIndex: Value(orderIndex),
      minPassScore: Value(minPassScore),
      isUnlocked: Value(isUnlocked),
    );
  }

  factory Level.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Level(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      minPassScore: serializer.fromJson<int>(json['minPassScore']),
      isUnlocked: serializer.fromJson<bool>(json['isUnlocked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'minPassScore': serializer.toJson<int>(minPassScore),
      'isUnlocked': serializer.toJson<bool>(isUnlocked),
    };
  }

  Level copyWith({
    int? id,
    String? code,
    String? title,
    String? description,
    int? orderIndex,
    int? minPassScore,
    bool? isUnlocked,
  }) => Level(
    id: id ?? this.id,
    code: code ?? this.code,
    title: title ?? this.title,
    description: description ?? this.description,
    orderIndex: orderIndex ?? this.orderIndex,
    minPassScore: minPassScore ?? this.minPassScore,
    isUnlocked: isUnlocked ?? this.isUnlocked,
  );
  Level copyWithCompanion(LevelsCompanion data) {
    return Level(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      minPassScore: data.minPassScore.present
          ? data.minPassScore.value
          : this.minPassScore,
      isUnlocked: data.isUnlocked.present
          ? data.isUnlocked.value
          : this.isUnlocked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Level(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('minPassScore: $minPassScore, ')
          ..write('isUnlocked: $isUnlocked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    title,
    description,
    orderIndex,
    minPassScore,
    isUnlocked,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Level &&
          other.id == this.id &&
          other.code == this.code &&
          other.title == this.title &&
          other.description == this.description &&
          other.orderIndex == this.orderIndex &&
          other.minPassScore == this.minPassScore &&
          other.isUnlocked == this.isUnlocked);
}

class LevelsCompanion extends UpdateCompanion<Level> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> title;
  final Value<String> description;
  final Value<int> orderIndex;
  final Value<int> minPassScore;
  final Value<bool> isUnlocked;
  const LevelsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.minPassScore = const Value.absent(),
    this.isUnlocked = const Value.absent(),
  });
  LevelsCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String title,
    required String description,
    required int orderIndex,
    this.minPassScore = const Value.absent(),
    this.isUnlocked = const Value.absent(),
  }) : code = Value(code),
       title = Value(title),
       description = Value(description),
       orderIndex = Value(orderIndex);
  static Insertable<Level> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? orderIndex,
    Expression<int>? minPassScore,
    Expression<bool>? isUnlocked,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (orderIndex != null) 'order_index': orderIndex,
      if (minPassScore != null) 'min_pass_score': minPassScore,
      if (isUnlocked != null) 'is_unlocked': isUnlocked,
    });
  }

  LevelsCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? title,
    Value<String>? description,
    Value<int>? orderIndex,
    Value<int>? minPassScore,
    Value<bool>? isUnlocked,
  }) {
    return LevelsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      minPassScore: minPassScore ?? this.minPassScore,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (minPassScore.present) {
      map['min_pass_score'] = Variable<int>(minPassScore.value);
    }
    if (isUnlocked.present) {
      map['is_unlocked'] = Variable<bool>(isUnlocked.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LevelsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('minPassScore: $minPassScore, ')
          ..write('isUnlocked: $isUnlocked')
          ..write(')'))
        .toString();
  }
}

class $LessonsTable extends Lessons with TableInfo<$LessonsTable, Lesson> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _levelIdMeta = const VerificationMeta(
    'levelId',
  );
  @override
  late final GeneratedColumn<int> levelId = GeneratedColumn<int>(
    'level_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES levels (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _scenarioPromptMeta = const VerificationMeta(
    'scenarioPrompt',
  );
  @override
  late final GeneratedColumn<String> scenarioPrompt = GeneratedColumn<String>(
    'scenario_prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systemInstructionMeta = const VerificationMeta(
    'systemInstruction',
  );
  @override
  late final GeneratedColumn<String> systemInstruction =
      GeneratedColumn<String>(
        'system_instruction',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDurationSecMeta = const VerificationMeta(
    'targetDurationSec',
  );
  @override
  late final GeneratedColumn<int> targetDurationSec = GeneratedColumn<int>(
    'target_duration_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isUnlockedMeta = const VerificationMeta(
    'isUnlocked',
  );
  @override
  late final GeneratedColumn<bool> isUnlocked = GeneratedColumn<bool>(
    'is_unlocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unlocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bestScoreMeta = const VerificationMeta(
    'bestScore',
  );
  @override
  late final GeneratedColumn<int> bestScore = GeneratedColumn<int>(
    'best_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    levelId,
    title,
    scenarioPrompt,
    systemInstruction,
    mode,
    targetDurationSec,
    orderIndex,
    isUnlocked,
    bestScore,
    isCompleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lessons';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lesson> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('level_id')) {
      context.handle(
        _levelIdMeta,
        levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_levelIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('scenario_prompt')) {
      context.handle(
        _scenarioPromptMeta,
        scenarioPrompt.isAcceptableOrUnknown(
          data['scenario_prompt']!,
          _scenarioPromptMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scenarioPromptMeta);
    }
    if (data.containsKey('system_instruction')) {
      context.handle(
        _systemInstructionMeta,
        systemInstruction.isAcceptableOrUnknown(
          data['system_instruction']!,
          _systemInstructionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_systemInstructionMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('target_duration_sec')) {
      context.handle(
        _targetDurationSecMeta,
        targetDurationSec.isAcceptableOrUnknown(
          data['target_duration_sec']!,
          _targetDurationSecMeta,
        ),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('is_unlocked')) {
      context.handle(
        _isUnlockedMeta,
        isUnlocked.isAcceptableOrUnknown(data['is_unlocked']!, _isUnlockedMeta),
      );
    }
    if (data.containsKey('best_score')) {
      context.handle(
        _bestScoreMeta,
        bestScore.isAcceptableOrUnknown(data['best_score']!, _bestScoreMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lesson map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lesson(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      levelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      scenarioPrompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scenario_prompt'],
      )!,
      systemInstruction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_instruction'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      targetDurationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_duration_sec'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      isUnlocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unlocked'],
      )!,
      bestScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_score'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
    );
  }

  @override
  $LessonsTable createAlias(String alias) {
    return $LessonsTable(attachedDatabase, alias);
  }
}

class Lesson extends DataClass implements Insertable<Lesson> {
  final int id;
  final int levelId;
  final String title;
  final String scenarioPrompt;
  final String systemInstruction;
  final String mode;
  final int targetDurationSec;
  final int orderIndex;
  final bool isUnlocked;
  final int bestScore;
  final bool isCompleted;
  const Lesson({
    required this.id,
    required this.levelId,
    required this.title,
    required this.scenarioPrompt,
    required this.systemInstruction,
    required this.mode,
    required this.targetDurationSec,
    required this.orderIndex,
    required this.isUnlocked,
    required this.bestScore,
    required this.isCompleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['level_id'] = Variable<int>(levelId);
    map['title'] = Variable<String>(title);
    map['scenario_prompt'] = Variable<String>(scenarioPrompt);
    map['system_instruction'] = Variable<String>(systemInstruction);
    map['mode'] = Variable<String>(mode);
    map['target_duration_sec'] = Variable<int>(targetDurationSec);
    map['order_index'] = Variable<int>(orderIndex);
    map['is_unlocked'] = Variable<bool>(isUnlocked);
    map['best_score'] = Variable<int>(bestScore);
    map['is_completed'] = Variable<bool>(isCompleted);
    return map;
  }

  LessonsCompanion toCompanion(bool nullToAbsent) {
    return LessonsCompanion(
      id: Value(id),
      levelId: Value(levelId),
      title: Value(title),
      scenarioPrompt: Value(scenarioPrompt),
      systemInstruction: Value(systemInstruction),
      mode: Value(mode),
      targetDurationSec: Value(targetDurationSec),
      orderIndex: Value(orderIndex),
      isUnlocked: Value(isUnlocked),
      bestScore: Value(bestScore),
      isCompleted: Value(isCompleted),
    );
  }

  factory Lesson.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lesson(
      id: serializer.fromJson<int>(json['id']),
      levelId: serializer.fromJson<int>(json['levelId']),
      title: serializer.fromJson<String>(json['title']),
      scenarioPrompt: serializer.fromJson<String>(json['scenarioPrompt']),
      systemInstruction: serializer.fromJson<String>(json['systemInstruction']),
      mode: serializer.fromJson<String>(json['mode']),
      targetDurationSec: serializer.fromJson<int>(json['targetDurationSec']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      isUnlocked: serializer.fromJson<bool>(json['isUnlocked']),
      bestScore: serializer.fromJson<int>(json['bestScore']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'levelId': serializer.toJson<int>(levelId),
      'title': serializer.toJson<String>(title),
      'scenarioPrompt': serializer.toJson<String>(scenarioPrompt),
      'systemInstruction': serializer.toJson<String>(systemInstruction),
      'mode': serializer.toJson<String>(mode),
      'targetDurationSec': serializer.toJson<int>(targetDurationSec),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'isUnlocked': serializer.toJson<bool>(isUnlocked),
      'bestScore': serializer.toJson<int>(bestScore),
      'isCompleted': serializer.toJson<bool>(isCompleted),
    };
  }

  Lesson copyWith({
    int? id,
    int? levelId,
    String? title,
    String? scenarioPrompt,
    String? systemInstruction,
    String? mode,
    int? targetDurationSec,
    int? orderIndex,
    bool? isUnlocked,
    int? bestScore,
    bool? isCompleted,
  }) => Lesson(
    id: id ?? this.id,
    levelId: levelId ?? this.levelId,
    title: title ?? this.title,
    scenarioPrompt: scenarioPrompt ?? this.scenarioPrompt,
    systemInstruction: systemInstruction ?? this.systemInstruction,
    mode: mode ?? this.mode,
    targetDurationSec: targetDurationSec ?? this.targetDurationSec,
    orderIndex: orderIndex ?? this.orderIndex,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    bestScore: bestScore ?? this.bestScore,
    isCompleted: isCompleted ?? this.isCompleted,
  );
  Lesson copyWithCompanion(LessonsCompanion data) {
    return Lesson(
      id: data.id.present ? data.id.value : this.id,
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
      title: data.title.present ? data.title.value : this.title,
      scenarioPrompt: data.scenarioPrompt.present
          ? data.scenarioPrompt.value
          : this.scenarioPrompt,
      systemInstruction: data.systemInstruction.present
          ? data.systemInstruction.value
          : this.systemInstruction,
      mode: data.mode.present ? data.mode.value : this.mode,
      targetDurationSec: data.targetDurationSec.present
          ? data.targetDurationSec.value
          : this.targetDurationSec,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      isUnlocked: data.isUnlocked.present
          ? data.isUnlocked.value
          : this.isUnlocked,
      bestScore: data.bestScore.present ? data.bestScore.value : this.bestScore,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lesson(')
          ..write('id: $id, ')
          ..write('levelId: $levelId, ')
          ..write('title: $title, ')
          ..write('scenarioPrompt: $scenarioPrompt, ')
          ..write('systemInstruction: $systemInstruction, ')
          ..write('mode: $mode, ')
          ..write('targetDurationSec: $targetDurationSec, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('bestScore: $bestScore, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    levelId,
    title,
    scenarioPrompt,
    systemInstruction,
    mode,
    targetDurationSec,
    orderIndex,
    isUnlocked,
    bestScore,
    isCompleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lesson &&
          other.id == this.id &&
          other.levelId == this.levelId &&
          other.title == this.title &&
          other.scenarioPrompt == this.scenarioPrompt &&
          other.systemInstruction == this.systemInstruction &&
          other.mode == this.mode &&
          other.targetDurationSec == this.targetDurationSec &&
          other.orderIndex == this.orderIndex &&
          other.isUnlocked == this.isUnlocked &&
          other.bestScore == this.bestScore &&
          other.isCompleted == this.isCompleted);
}

class LessonsCompanion extends UpdateCompanion<Lesson> {
  final Value<int> id;
  final Value<int> levelId;
  final Value<String> title;
  final Value<String> scenarioPrompt;
  final Value<String> systemInstruction;
  final Value<String> mode;
  final Value<int> targetDurationSec;
  final Value<int> orderIndex;
  final Value<bool> isUnlocked;
  final Value<int> bestScore;
  final Value<bool> isCompleted;
  const LessonsCompanion({
    this.id = const Value.absent(),
    this.levelId = const Value.absent(),
    this.title = const Value.absent(),
    this.scenarioPrompt = const Value.absent(),
    this.systemInstruction = const Value.absent(),
    this.mode = const Value.absent(),
    this.targetDurationSec = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.bestScore = const Value.absent(),
    this.isCompleted = const Value.absent(),
  });
  LessonsCompanion.insert({
    this.id = const Value.absent(),
    required int levelId,
    required String title,
    required String scenarioPrompt,
    required String systemInstruction,
    required String mode,
    this.targetDurationSec = const Value.absent(),
    required int orderIndex,
    this.isUnlocked = const Value.absent(),
    this.bestScore = const Value.absent(),
    this.isCompleted = const Value.absent(),
  }) : levelId = Value(levelId),
       title = Value(title),
       scenarioPrompt = Value(scenarioPrompt),
       systemInstruction = Value(systemInstruction),
       mode = Value(mode),
       orderIndex = Value(orderIndex);
  static Insertable<Lesson> custom({
    Expression<int>? id,
    Expression<int>? levelId,
    Expression<String>? title,
    Expression<String>? scenarioPrompt,
    Expression<String>? systemInstruction,
    Expression<String>? mode,
    Expression<int>? targetDurationSec,
    Expression<int>? orderIndex,
    Expression<bool>? isUnlocked,
    Expression<int>? bestScore,
    Expression<bool>? isCompleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (levelId != null) 'level_id': levelId,
      if (title != null) 'title': title,
      if (scenarioPrompt != null) 'scenario_prompt': scenarioPrompt,
      if (systemInstruction != null) 'system_instruction': systemInstruction,
      if (mode != null) 'mode': mode,
      if (targetDurationSec != null) 'target_duration_sec': targetDurationSec,
      if (orderIndex != null) 'order_index': orderIndex,
      if (isUnlocked != null) 'is_unlocked': isUnlocked,
      if (bestScore != null) 'best_score': bestScore,
      if (isCompleted != null) 'is_completed': isCompleted,
    });
  }

  LessonsCompanion copyWith({
    Value<int>? id,
    Value<int>? levelId,
    Value<String>? title,
    Value<String>? scenarioPrompt,
    Value<String>? systemInstruction,
    Value<String>? mode,
    Value<int>? targetDurationSec,
    Value<int>? orderIndex,
    Value<bool>? isUnlocked,
    Value<int>? bestScore,
    Value<bool>? isCompleted,
  }) {
    return LessonsCompanion(
      id: id ?? this.id,
      levelId: levelId ?? this.levelId,
      title: title ?? this.title,
      scenarioPrompt: scenarioPrompt ?? this.scenarioPrompt,
      systemInstruction: systemInstruction ?? this.systemInstruction,
      mode: mode ?? this.mode,
      targetDurationSec: targetDurationSec ?? this.targetDurationSec,
      orderIndex: orderIndex ?? this.orderIndex,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      bestScore: bestScore ?? this.bestScore,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (levelId.present) {
      map['level_id'] = Variable<int>(levelId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (scenarioPrompt.present) {
      map['scenario_prompt'] = Variable<String>(scenarioPrompt.value);
    }
    if (systemInstruction.present) {
      map['system_instruction'] = Variable<String>(systemInstruction.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (targetDurationSec.present) {
      map['target_duration_sec'] = Variable<int>(targetDurationSec.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (isUnlocked.present) {
      map['is_unlocked'] = Variable<bool>(isUnlocked.value);
    }
    if (bestScore.present) {
      map['best_score'] = Variable<int>(bestScore.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonsCompanion(')
          ..write('id: $id, ')
          ..write('levelId: $levelId, ')
          ..write('title: $title, ')
          ..write('scenarioPrompt: $scenarioPrompt, ')
          ..write('systemInstruction: $systemInstruction, ')
          ..write('mode: $mode, ')
          ..write('targetDurationSec: $targetDurationSec, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('bestScore: $bestScore, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }
}

class $PracticeSessionsTable extends PracticeSessions
    with TableInfo<$PracticeSessionsTable, PracticeSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeSessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<int> lessonId = GeneratedColumn<int>(
    'lesson_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lessons (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _transcriptJsonMeta = const VerificationMeta(
    'transcriptJson',
  );
  @override
  late final GeneratedColumn<String> transcriptJson = GeneratedColumn<String>(
    'transcript_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _overallScoreMeta = const VerificationMeta(
    'overallScore',
  );
  @override
  late final GeneratedColumn<int> overallScore = GeneratedColumn<int>(
    'overall_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fluencyScoreMeta = const VerificationMeta(
    'fluencyScore',
  );
  @override
  late final GeneratedColumn<int> fluencyScore = GeneratedColumn<int>(
    'fluency_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _grammarScoreMeta = const VerificationMeta(
    'grammarScore',
  );
  @override
  late final GeneratedColumn<int> grammarScore = GeneratedColumn<int>(
    'grammar_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vocabScoreMeta = const VerificationMeta(
    'vocabScore',
  );
  @override
  late final GeneratedColumn<int> vocabScore = GeneratedColumn<int>(
    'vocab_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pronunciationScoreMeta =
      const VerificationMeta('pronunciationScore');
  @override
  late final GeneratedColumn<int> pronunciationScore = GeneratedColumn<int>(
    'pronunciation_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fillerCountMeta = const VerificationMeta(
    'fillerCount',
  );
  @override
  late final GeneratedColumn<int> fillerCount = GeneratedColumn<int>(
    'filler_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _aiSummaryMeta = const VerificationMeta(
    'aiSummary',
  );
  @override
  late final GeneratedColumn<String> aiSummary = GeneratedColumn<String>(
    'ai_summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _passedMeta = const VerificationMeta('passed');
  @override
  late final GeneratedColumn<bool> passed = GeneratedColumn<bool>(
    'passed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("passed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lessonId,
    sessionType,
    startedAt,
    endedAt,
    durationSec,
    transcriptJson,
    overallScore,
    fluencyScore,
    grammarScore,
    vocabScore,
    pronunciationScore,
    fillerCount,
    aiSummary,
    passed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionTypeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('transcript_json')) {
      context.handle(
        _transcriptJsonMeta,
        transcriptJson.isAcceptableOrUnknown(
          data['transcript_json']!,
          _transcriptJsonMeta,
        ),
      );
    }
    if (data.containsKey('overall_score')) {
      context.handle(
        _overallScoreMeta,
        overallScore.isAcceptableOrUnknown(
          data['overall_score']!,
          _overallScoreMeta,
        ),
      );
    }
    if (data.containsKey('fluency_score')) {
      context.handle(
        _fluencyScoreMeta,
        fluencyScore.isAcceptableOrUnknown(
          data['fluency_score']!,
          _fluencyScoreMeta,
        ),
      );
    }
    if (data.containsKey('grammar_score')) {
      context.handle(
        _grammarScoreMeta,
        grammarScore.isAcceptableOrUnknown(
          data['grammar_score']!,
          _grammarScoreMeta,
        ),
      );
    }
    if (data.containsKey('vocab_score')) {
      context.handle(
        _vocabScoreMeta,
        vocabScore.isAcceptableOrUnknown(data['vocab_score']!, _vocabScoreMeta),
      );
    }
    if (data.containsKey('pronunciation_score')) {
      context.handle(
        _pronunciationScoreMeta,
        pronunciationScore.isAcceptableOrUnknown(
          data['pronunciation_score']!,
          _pronunciationScoreMeta,
        ),
      );
    }
    if (data.containsKey('filler_count')) {
      context.handle(
        _fillerCountMeta,
        fillerCount.isAcceptableOrUnknown(
          data['filler_count']!,
          _fillerCountMeta,
        ),
      );
    }
    if (data.containsKey('ai_summary')) {
      context.handle(
        _aiSummaryMeta,
        aiSummary.isAcceptableOrUnknown(data['ai_summary']!, _aiSummaryMeta),
      );
    }
    if (data.containsKey('passed')) {
      context.handle(
        _passedMeta,
        passed.isAcceptableOrUnknown(data['passed']!, _passedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lesson_id'],
      ),
      sessionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_type'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      )!,
      transcriptJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcript_json'],
      )!,
      overallScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overall_score'],
      )!,
      fluencyScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fluency_score'],
      )!,
      grammarScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grammar_score'],
      )!,
      vocabScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vocab_score'],
      )!,
      pronunciationScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pronunciation_score'],
      )!,
      fillerCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}filler_count'],
      )!,
      aiSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_summary'],
      )!,
      passed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}passed'],
      )!,
    );
  }

  @override
  $PracticeSessionsTable createAlias(String alias) {
    return $PracticeSessionsTable(attachedDatabase, alias);
  }
}

class PracticeSession extends DataClass implements Insertable<PracticeSession> {
  final int id;
  final int? lessonId;
  final String sessionType;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSec;
  final String transcriptJson;
  final int overallScore;
  final int fluencyScore;
  final int grammarScore;
  final int vocabScore;
  final int pronunciationScore;
  final int fillerCount;
  final String aiSummary;
  final bool passed;
  const PracticeSession({
    required this.id,
    this.lessonId,
    required this.sessionType,
    required this.startedAt,
    this.endedAt,
    required this.durationSec,
    required this.transcriptJson,
    required this.overallScore,
    required this.fluencyScore,
    required this.grammarScore,
    required this.vocabScore,
    required this.pronunciationScore,
    required this.fillerCount,
    required this.aiSummary,
    required this.passed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || lessonId != null) {
      map['lesson_id'] = Variable<int>(lessonId);
    }
    map['session_type'] = Variable<String>(sessionType);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['duration_sec'] = Variable<int>(durationSec);
    map['transcript_json'] = Variable<String>(transcriptJson);
    map['overall_score'] = Variable<int>(overallScore);
    map['fluency_score'] = Variable<int>(fluencyScore);
    map['grammar_score'] = Variable<int>(grammarScore);
    map['vocab_score'] = Variable<int>(vocabScore);
    map['pronunciation_score'] = Variable<int>(pronunciationScore);
    map['filler_count'] = Variable<int>(fillerCount);
    map['ai_summary'] = Variable<String>(aiSummary);
    map['passed'] = Variable<bool>(passed);
    return map;
  }

  PracticeSessionsCompanion toCompanion(bool nullToAbsent) {
    return PracticeSessionsCompanion(
      id: Value(id),
      lessonId: lessonId == null && nullToAbsent
          ? const Value.absent()
          : Value(lessonId),
      sessionType: Value(sessionType),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationSec: Value(durationSec),
      transcriptJson: Value(transcriptJson),
      overallScore: Value(overallScore),
      fluencyScore: Value(fluencyScore),
      grammarScore: Value(grammarScore),
      vocabScore: Value(vocabScore),
      pronunciationScore: Value(pronunciationScore),
      fillerCount: Value(fillerCount),
      aiSummary: Value(aiSummary),
      passed: Value(passed),
    );
  }

  factory PracticeSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeSession(
      id: serializer.fromJson<int>(json['id']),
      lessonId: serializer.fromJson<int?>(json['lessonId']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      durationSec: serializer.fromJson<int>(json['durationSec']),
      transcriptJson: serializer.fromJson<String>(json['transcriptJson']),
      overallScore: serializer.fromJson<int>(json['overallScore']),
      fluencyScore: serializer.fromJson<int>(json['fluencyScore']),
      grammarScore: serializer.fromJson<int>(json['grammarScore']),
      vocabScore: serializer.fromJson<int>(json['vocabScore']),
      pronunciationScore: serializer.fromJson<int>(json['pronunciationScore']),
      fillerCount: serializer.fromJson<int>(json['fillerCount']),
      aiSummary: serializer.fromJson<String>(json['aiSummary']),
      passed: serializer.fromJson<bool>(json['passed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lessonId': serializer.toJson<int?>(lessonId),
      'sessionType': serializer.toJson<String>(sessionType),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'durationSec': serializer.toJson<int>(durationSec),
      'transcriptJson': serializer.toJson<String>(transcriptJson),
      'overallScore': serializer.toJson<int>(overallScore),
      'fluencyScore': serializer.toJson<int>(fluencyScore),
      'grammarScore': serializer.toJson<int>(grammarScore),
      'vocabScore': serializer.toJson<int>(vocabScore),
      'pronunciationScore': serializer.toJson<int>(pronunciationScore),
      'fillerCount': serializer.toJson<int>(fillerCount),
      'aiSummary': serializer.toJson<String>(aiSummary),
      'passed': serializer.toJson<bool>(passed),
    };
  }

  PracticeSession copyWith({
    int? id,
    Value<int?> lessonId = const Value.absent(),
    String? sessionType,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? durationSec,
    String? transcriptJson,
    int? overallScore,
    int? fluencyScore,
    int? grammarScore,
    int? vocabScore,
    int? pronunciationScore,
    int? fillerCount,
    String? aiSummary,
    bool? passed,
  }) => PracticeSession(
    id: id ?? this.id,
    lessonId: lessonId.present ? lessonId.value : this.lessonId,
    sessionType: sessionType ?? this.sessionType,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    durationSec: durationSec ?? this.durationSec,
    transcriptJson: transcriptJson ?? this.transcriptJson,
    overallScore: overallScore ?? this.overallScore,
    fluencyScore: fluencyScore ?? this.fluencyScore,
    grammarScore: grammarScore ?? this.grammarScore,
    vocabScore: vocabScore ?? this.vocabScore,
    pronunciationScore: pronunciationScore ?? this.pronunciationScore,
    fillerCount: fillerCount ?? this.fillerCount,
    aiSummary: aiSummary ?? this.aiSummary,
    passed: passed ?? this.passed,
  );
  PracticeSession copyWithCompanion(PracticeSessionsCompanion data) {
    return PracticeSession(
      id: data.id.present ? data.id.value : this.id,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      sessionType: data.sessionType.present
          ? data.sessionType.value
          : this.sessionType,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      transcriptJson: data.transcriptJson.present
          ? data.transcriptJson.value
          : this.transcriptJson,
      overallScore: data.overallScore.present
          ? data.overallScore.value
          : this.overallScore,
      fluencyScore: data.fluencyScore.present
          ? data.fluencyScore.value
          : this.fluencyScore,
      grammarScore: data.grammarScore.present
          ? data.grammarScore.value
          : this.grammarScore,
      vocabScore: data.vocabScore.present
          ? data.vocabScore.value
          : this.vocabScore,
      pronunciationScore: data.pronunciationScore.present
          ? data.pronunciationScore.value
          : this.pronunciationScore,
      fillerCount: data.fillerCount.present
          ? data.fillerCount.value
          : this.fillerCount,
      aiSummary: data.aiSummary.present ? data.aiSummary.value : this.aiSummary,
      passed: data.passed.present ? data.passed.value : this.passed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSession(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('sessionType: $sessionType, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSec: $durationSec, ')
          ..write('transcriptJson: $transcriptJson, ')
          ..write('overallScore: $overallScore, ')
          ..write('fluencyScore: $fluencyScore, ')
          ..write('grammarScore: $grammarScore, ')
          ..write('vocabScore: $vocabScore, ')
          ..write('pronunciationScore: $pronunciationScore, ')
          ..write('fillerCount: $fillerCount, ')
          ..write('aiSummary: $aiSummary, ')
          ..write('passed: $passed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lessonId,
    sessionType,
    startedAt,
    endedAt,
    durationSec,
    transcriptJson,
    overallScore,
    fluencyScore,
    grammarScore,
    vocabScore,
    pronunciationScore,
    fillerCount,
    aiSummary,
    passed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeSession &&
          other.id == this.id &&
          other.lessonId == this.lessonId &&
          other.sessionType == this.sessionType &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSec == this.durationSec &&
          other.transcriptJson == this.transcriptJson &&
          other.overallScore == this.overallScore &&
          other.fluencyScore == this.fluencyScore &&
          other.grammarScore == this.grammarScore &&
          other.vocabScore == this.vocabScore &&
          other.pronunciationScore == this.pronunciationScore &&
          other.fillerCount == this.fillerCount &&
          other.aiSummary == this.aiSummary &&
          other.passed == this.passed);
}

class PracticeSessionsCompanion extends UpdateCompanion<PracticeSession> {
  final Value<int> id;
  final Value<int?> lessonId;
  final Value<String> sessionType;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> durationSec;
  final Value<String> transcriptJson;
  final Value<int> overallScore;
  final Value<int> fluencyScore;
  final Value<int> grammarScore;
  final Value<int> vocabScore;
  final Value<int> pronunciationScore;
  final Value<int> fillerCount;
  final Value<String> aiSummary;
  final Value<bool> passed;
  const PracticeSessionsCompanion({
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.transcriptJson = const Value.absent(),
    this.overallScore = const Value.absent(),
    this.fluencyScore = const Value.absent(),
    this.grammarScore = const Value.absent(),
    this.vocabScore = const Value.absent(),
    this.pronunciationScore = const Value.absent(),
    this.fillerCount = const Value.absent(),
    this.aiSummary = const Value.absent(),
    this.passed = const Value.absent(),
  });
  PracticeSessionsCompanion.insert({
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    required String sessionType,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.transcriptJson = const Value.absent(),
    this.overallScore = const Value.absent(),
    this.fluencyScore = const Value.absent(),
    this.grammarScore = const Value.absent(),
    this.vocabScore = const Value.absent(),
    this.pronunciationScore = const Value.absent(),
    this.fillerCount = const Value.absent(),
    this.aiSummary = const Value.absent(),
    this.passed = const Value.absent(),
  }) : sessionType = Value(sessionType),
       startedAt = Value(startedAt);
  static Insertable<PracticeSession> custom({
    Expression<int>? id,
    Expression<int>? lessonId,
    Expression<String>? sessionType,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? durationSec,
    Expression<String>? transcriptJson,
    Expression<int>? overallScore,
    Expression<int>? fluencyScore,
    Expression<int>? grammarScore,
    Expression<int>? vocabScore,
    Expression<int>? pronunciationScore,
    Expression<int>? fillerCount,
    Expression<String>? aiSummary,
    Expression<bool>? passed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lessonId != null) 'lesson_id': lessonId,
      if (sessionType != null) 'session_type': sessionType,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSec != null) 'duration_sec': durationSec,
      if (transcriptJson != null) 'transcript_json': transcriptJson,
      if (overallScore != null) 'overall_score': overallScore,
      if (fluencyScore != null) 'fluency_score': fluencyScore,
      if (grammarScore != null) 'grammar_score': grammarScore,
      if (vocabScore != null) 'vocab_score': vocabScore,
      if (pronunciationScore != null) 'pronunciation_score': pronunciationScore,
      if (fillerCount != null) 'filler_count': fillerCount,
      if (aiSummary != null) 'ai_summary': aiSummary,
      if (passed != null) 'passed': passed,
    });
  }

  PracticeSessionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? lessonId,
    Value<String>? sessionType,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? durationSec,
    Value<String>? transcriptJson,
    Value<int>? overallScore,
    Value<int>? fluencyScore,
    Value<int>? grammarScore,
    Value<int>? vocabScore,
    Value<int>? pronunciationScore,
    Value<int>? fillerCount,
    Value<String>? aiSummary,
    Value<bool>? passed,
  }) {
    return PracticeSessionsCompanion(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      sessionType: sessionType ?? this.sessionType,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSec: durationSec ?? this.durationSec,
      transcriptJson: transcriptJson ?? this.transcriptJson,
      overallScore: overallScore ?? this.overallScore,
      fluencyScore: fluencyScore ?? this.fluencyScore,
      grammarScore: grammarScore ?? this.grammarScore,
      vocabScore: vocabScore ?? this.vocabScore,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
      fillerCount: fillerCount ?? this.fillerCount,
      aiSummary: aiSummary ?? this.aiSummary,
      passed: passed ?? this.passed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<int>(lessonId.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (transcriptJson.present) {
      map['transcript_json'] = Variable<String>(transcriptJson.value);
    }
    if (overallScore.present) {
      map['overall_score'] = Variable<int>(overallScore.value);
    }
    if (fluencyScore.present) {
      map['fluency_score'] = Variable<int>(fluencyScore.value);
    }
    if (grammarScore.present) {
      map['grammar_score'] = Variable<int>(grammarScore.value);
    }
    if (vocabScore.present) {
      map['vocab_score'] = Variable<int>(vocabScore.value);
    }
    if (pronunciationScore.present) {
      map['pronunciation_score'] = Variable<int>(pronunciationScore.value);
    }
    if (fillerCount.present) {
      map['filler_count'] = Variable<int>(fillerCount.value);
    }
    if (aiSummary.present) {
      map['ai_summary'] = Variable<String>(aiSummary.value);
    }
    if (passed.present) {
      map['passed'] = Variable<bool>(passed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSessionsCompanion(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('sessionType: $sessionType, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSec: $durationSec, ')
          ..write('transcriptJson: $transcriptJson, ')
          ..write('overallScore: $overallScore, ')
          ..write('fluencyScore: $fluencyScore, ')
          ..write('grammarScore: $grammarScore, ')
          ..write('vocabScore: $vocabScore, ')
          ..write('pronunciationScore: $pronunciationScore, ')
          ..write('fillerCount: $fillerCount, ')
          ..write('aiSummary: $aiSummary, ')
          ..write('passed: $passed')
          ..write(')'))
        .toString();
  }
}

class $MistakesTable extends Mistakes with TableInfo<$MistakesTable, Mistake> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MistakesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _originalSentenceMeta = const VerificationMeta(
    'originalSentence',
  );
  @override
  late final GeneratedColumn<String> originalSentence = GeneratedColumn<String>(
    'original_sentence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctedSentenceMeta = const VerificationMeta(
    'correctedSentence',
  );
  @override
  late final GeneratedColumn<String> correctedSentence =
      GeneratedColumn<String>(
        'corrected_sentence',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    originalSentence,
    correctedSentence,
    explanation,
    category,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mistakes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Mistake> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('original_sentence')) {
      context.handle(
        _originalSentenceMeta,
        originalSentence.isAcceptableOrUnknown(
          data['original_sentence']!,
          _originalSentenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalSentenceMeta);
    }
    if (data.containsKey('corrected_sentence')) {
      context.handle(
        _correctedSentenceMeta,
        correctedSentence.isAcceptableOrUnknown(
          data['corrected_sentence']!,
          _correctedSentenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctedSentenceMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Mistake map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Mistake(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      originalSentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_sentence'],
      )!,
      correctedSentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corrected_sentence'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MistakesTable createAlias(String alias) {
    return $MistakesTable(attachedDatabase, alias);
  }
}

class Mistake extends DataClass implements Insertable<Mistake> {
  final int id;
  final int sessionId;
  final String originalSentence;
  final String correctedSentence;
  final String explanation;
  final String category;
  final DateTime createdAt;
  const Mistake({
    required this.id,
    required this.sessionId,
    required this.originalSentence,
    required this.correctedSentence,
    required this.explanation,
    required this.category,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['original_sentence'] = Variable<String>(originalSentence);
    map['corrected_sentence'] = Variable<String>(correctedSentence);
    map['explanation'] = Variable<String>(explanation);
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MistakesCompanion toCompanion(bool nullToAbsent) {
    return MistakesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      originalSentence: Value(originalSentence),
      correctedSentence: Value(correctedSentence),
      explanation: Value(explanation),
      category: Value(category),
      createdAt: Value(createdAt),
    );
  }

  factory Mistake.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Mistake(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      originalSentence: serializer.fromJson<String>(json['originalSentence']),
      correctedSentence: serializer.fromJson<String>(json['correctedSentence']),
      explanation: serializer.fromJson<String>(json['explanation']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'originalSentence': serializer.toJson<String>(originalSentence),
      'correctedSentence': serializer.toJson<String>(correctedSentence),
      'explanation': serializer.toJson<String>(explanation),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Mistake copyWith({
    int? id,
    int? sessionId,
    String? originalSentence,
    String? correctedSentence,
    String? explanation,
    String? category,
    DateTime? createdAt,
  }) => Mistake(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    originalSentence: originalSentence ?? this.originalSentence,
    correctedSentence: correctedSentence ?? this.correctedSentence,
    explanation: explanation ?? this.explanation,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
  );
  Mistake copyWithCompanion(MistakesCompanion data) {
    return Mistake(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      originalSentence: data.originalSentence.present
          ? data.originalSentence.value
          : this.originalSentence,
      correctedSentence: data.correctedSentence.present
          ? data.correctedSentence.value
          : this.correctedSentence,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Mistake(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('originalSentence: $originalSentence, ')
          ..write('correctedSentence: $correctedSentence, ')
          ..write('explanation: $explanation, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    originalSentence,
    correctedSentence,
    explanation,
    category,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Mistake &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.originalSentence == this.originalSentence &&
          other.correctedSentence == this.correctedSentence &&
          other.explanation == this.explanation &&
          other.category == this.category &&
          other.createdAt == this.createdAt);
}

class MistakesCompanion extends UpdateCompanion<Mistake> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> originalSentence;
  final Value<String> correctedSentence;
  final Value<String> explanation;
  final Value<String> category;
  final Value<DateTime> createdAt;
  const MistakesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.originalSentence = const Value.absent(),
    this.correctedSentence = const Value.absent(),
    this.explanation = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MistakesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String originalSentence,
    required String correctedSentence,
    required String explanation,
    required String category,
    required DateTime createdAt,
  }) : sessionId = Value(sessionId),
       originalSentence = Value(originalSentence),
       correctedSentence = Value(correctedSentence),
       explanation = Value(explanation),
       category = Value(category),
       createdAt = Value(createdAt);
  static Insertable<Mistake> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? originalSentence,
    Expression<String>? correctedSentence,
    Expression<String>? explanation,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (originalSentence != null) 'original_sentence': originalSentence,
      if (correctedSentence != null) 'corrected_sentence': correctedSentence,
      if (explanation != null) 'explanation': explanation,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MistakesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? originalSentence,
    Value<String>? correctedSentence,
    Value<String>? explanation,
    Value<String>? category,
    Value<DateTime>? createdAt,
  }) {
    return MistakesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      originalSentence: originalSentence ?? this.originalSentence,
      correctedSentence: correctedSentence ?? this.correctedSentence,
      explanation: explanation ?? this.explanation,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (originalSentence.present) {
      map['original_sentence'] = Variable<String>(originalSentence.value);
    }
    if (correctedSentence.present) {
      map['corrected_sentence'] = Variable<String>(correctedSentence.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MistakesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('originalSentence: $originalSentence, ')
          ..write('correctedSentence: $correctedSentence, ')
          ..write('explanation: $explanation, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $VocabItemsTable extends VocabItems
    with TableInfo<$VocabItemsTable, VocabItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_sessions (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningIdMeta = const VerificationMeta(
    'meaningId',
  );
  @override
  late final GeneratedColumn<String> meaningId = GeneratedColumn<String>(
    'meaning_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleSentenceMeta = const VerificationMeta(
    'exampleSentence',
  );
  @override
  late final GeneratedColumn<String> exampleSentence = GeneratedColumn<String>(
    'example_sentence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cefrLevelMeta = const VerificationMeta(
    'cefrLevel',
  );
  @override
  late final GeneratedColumn<String> cefrLevel = GeneratedColumn<String>(
    'cefr_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _masteryCountMeta = const VerificationMeta(
    'masteryCount',
  );
  @override
  late final GeneratedColumn<int> masteryCount = GeneratedColumn<int>(
    'mastery_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    word,
    meaningId,
    exampleSentence,
    cefrLevel,
    masteryCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocab_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('meaning_id')) {
      context.handle(
        _meaningIdMeta,
        meaningId.isAcceptableOrUnknown(data['meaning_id']!, _meaningIdMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningIdMeta);
    }
    if (data.containsKey('example_sentence')) {
      context.handle(
        _exampleSentenceMeta,
        exampleSentence.isAcceptableOrUnknown(
          data['example_sentence']!,
          _exampleSentenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exampleSentenceMeta);
    }
    if (data.containsKey('cefr_level')) {
      context.handle(
        _cefrLevelMeta,
        cefrLevel.isAcceptableOrUnknown(data['cefr_level']!, _cefrLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_cefrLevelMeta);
    }
    if (data.containsKey('mastery_count')) {
      context.handle(
        _masteryCountMeta,
        masteryCount.isAcceptableOrUnknown(
          data['mastery_count']!,
          _masteryCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      ),
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      meaningId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning_id'],
      )!,
      exampleSentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_sentence'],
      )!,
      cefrLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cefr_level'],
      )!,
      masteryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastery_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VocabItemsTable createAlias(String alias) {
    return $VocabItemsTable(attachedDatabase, alias);
  }
}

class VocabItem extends DataClass implements Insertable<VocabItem> {
  final int id;
  final int? sessionId;
  final String word;
  final String meaningId;
  final String exampleSentence;
  final String cefrLevel;
  final int masteryCount;
  final DateTime createdAt;
  const VocabItem({
    required this.id,
    this.sessionId,
    required this.word,
    required this.meaningId,
    required this.exampleSentence,
    required this.cefrLevel,
    required this.masteryCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<int>(sessionId);
    }
    map['word'] = Variable<String>(word);
    map['meaning_id'] = Variable<String>(meaningId);
    map['example_sentence'] = Variable<String>(exampleSentence);
    map['cefr_level'] = Variable<String>(cefrLevel);
    map['mastery_count'] = Variable<int>(masteryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VocabItemsCompanion toCompanion(bool nullToAbsent) {
    return VocabItemsCompanion(
      id: Value(id),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      word: Value(word),
      meaningId: Value(meaningId),
      exampleSentence: Value(exampleSentence),
      cefrLevel: Value(cefrLevel),
      masteryCount: Value(masteryCount),
      createdAt: Value(createdAt),
    );
  }

  factory VocabItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabItem(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int?>(json['sessionId']),
      word: serializer.fromJson<String>(json['word']),
      meaningId: serializer.fromJson<String>(json['meaningId']),
      exampleSentence: serializer.fromJson<String>(json['exampleSentence']),
      cefrLevel: serializer.fromJson<String>(json['cefrLevel']),
      masteryCount: serializer.fromJson<int>(json['masteryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int?>(sessionId),
      'word': serializer.toJson<String>(word),
      'meaningId': serializer.toJson<String>(meaningId),
      'exampleSentence': serializer.toJson<String>(exampleSentence),
      'cefrLevel': serializer.toJson<String>(cefrLevel),
      'masteryCount': serializer.toJson<int>(masteryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VocabItem copyWith({
    int? id,
    Value<int?> sessionId = const Value.absent(),
    String? word,
    String? meaningId,
    String? exampleSentence,
    String? cefrLevel,
    int? masteryCount,
    DateTime? createdAt,
  }) => VocabItem(
    id: id ?? this.id,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    word: word ?? this.word,
    meaningId: meaningId ?? this.meaningId,
    exampleSentence: exampleSentence ?? this.exampleSentence,
    cefrLevel: cefrLevel ?? this.cefrLevel,
    masteryCount: masteryCount ?? this.masteryCount,
    createdAt: createdAt ?? this.createdAt,
  );
  VocabItem copyWithCompanion(VocabItemsCompanion data) {
    return VocabItem(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      word: data.word.present ? data.word.value : this.word,
      meaningId: data.meaningId.present ? data.meaningId.value : this.meaningId,
      exampleSentence: data.exampleSentence.present
          ? data.exampleSentence.value
          : this.exampleSentence,
      cefrLevel: data.cefrLevel.present ? data.cefrLevel.value : this.cefrLevel,
      masteryCount: data.masteryCount.present
          ? data.masteryCount.value
          : this.masteryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabItem(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('word: $word, ')
          ..write('meaningId: $meaningId, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('cefrLevel: $cefrLevel, ')
          ..write('masteryCount: $masteryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    word,
    meaningId,
    exampleSentence,
    cefrLevel,
    masteryCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabItem &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.word == this.word &&
          other.meaningId == this.meaningId &&
          other.exampleSentence == this.exampleSentence &&
          other.cefrLevel == this.cefrLevel &&
          other.masteryCount == this.masteryCount &&
          other.createdAt == this.createdAt);
}

class VocabItemsCompanion extends UpdateCompanion<VocabItem> {
  final Value<int> id;
  final Value<int?> sessionId;
  final Value<String> word;
  final Value<String> meaningId;
  final Value<String> exampleSentence;
  final Value<String> cefrLevel;
  final Value<int> masteryCount;
  final Value<DateTime> createdAt;
  const VocabItemsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.word = const Value.absent(),
    this.meaningId = const Value.absent(),
    this.exampleSentence = const Value.absent(),
    this.cefrLevel = const Value.absent(),
    this.masteryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  VocabItemsCompanion.insert({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    required String word,
    required String meaningId,
    required String exampleSentence,
    required String cefrLevel,
    this.masteryCount = const Value.absent(),
    required DateTime createdAt,
  }) : word = Value(word),
       meaningId = Value(meaningId),
       exampleSentence = Value(exampleSentence),
       cefrLevel = Value(cefrLevel),
       createdAt = Value(createdAt);
  static Insertable<VocabItem> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? word,
    Expression<String>? meaningId,
    Expression<String>? exampleSentence,
    Expression<String>? cefrLevel,
    Expression<int>? masteryCount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (word != null) 'word': word,
      if (meaningId != null) 'meaning_id': meaningId,
      if (exampleSentence != null) 'example_sentence': exampleSentence,
      if (cefrLevel != null) 'cefr_level': cefrLevel,
      if (masteryCount != null) 'mastery_count': masteryCount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  VocabItemsCompanion copyWith({
    Value<int>? id,
    Value<int?>? sessionId,
    Value<String>? word,
    Value<String>? meaningId,
    Value<String>? exampleSentence,
    Value<String>? cefrLevel,
    Value<int>? masteryCount,
    Value<DateTime>? createdAt,
  }) {
    return VocabItemsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      word: word ?? this.word,
      meaningId: meaningId ?? this.meaningId,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      masteryCount: masteryCount ?? this.masteryCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (meaningId.present) {
      map['meaning_id'] = Variable<String>(meaningId.value);
    }
    if (exampleSentence.present) {
      map['example_sentence'] = Variable<String>(exampleSentence.value);
    }
    if (cefrLevel.present) {
      map['cefr_level'] = Variable<String>(cefrLevel.value);
    }
    if (masteryCount.present) {
      map['mastery_count'] = Variable<int>(masteryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabItemsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('word: $word, ')
          ..write('meaningId: $meaningId, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('cefrLevel: $cefrLevel, ')
          ..write('masteryCount: $masteryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  @override
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
    'api_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _liveModelMeta = const VerificationMeta(
    'liveModel',
  );
  @override
  late final GeneratedColumn<String> liveModel = GeneratedColumn<String>(
    'live_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(
      'gemini-2.5-flash-native-audio-preview-12-2025',
    ),
  );
  static const VerificationMeta _scoringModelMeta = const VerificationMeta(
    'scoringModel',
  );
  @override
  late final GeneratedColumn<String> scoringModel = GeneratedColumn<String>(
    'scoring_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('gemini-2.5-flash'),
  );
  static const VerificationMeta _flashcardModelMeta = const VerificationMeta(
    'flashcardModel',
  );
  @override
  late final GeneratedColumn<String> flashcardModel = GeneratedColumn<String>(
    'flashcard_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('gemini-3.8-flash'),
  );
  static const VerificationMeta _flashcardTtsModelMeta = const VerificationMeta(
    'flashcardTtsModel',
  );
  @override
  late final GeneratedColumn<String> flashcardTtsModel =
      GeneratedColumn<String>(
        'flashcard_tts_model',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('gemini-3.8-live'),
      );
  static const VerificationMeta _bilingualBeginnerSupportMeta =
      const VerificationMeta('bilingualBeginnerSupport');
  @override
  late final GeneratedColumn<bool> bilingualBeginnerSupport =
      GeneratedColumn<bool>(
        'bilingual_beginner_support',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("bilingual_beginner_support" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _darkModeMeta = const VerificationMeta(
    'darkMode',
  );
  @override
  late final GeneratedColumn<bool> darkMode = GeneratedColumn<bool>(
    'dark_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dark_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unlockAllOverrideMeta = const VerificationMeta(
    'unlockAllOverride',
  );
  @override
  late final GeneratedColumn<bool> unlockAllOverride = GeneratedColumn<bool>(
    'unlock_all_override',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("unlock_all_override" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currentStreakMeta = const VerificationMeta(
    'currentStreak',
  );
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
    'current_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPracticeDateMeta = const VerificationMeta(
    'lastPracticeDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastPracticeDate =
      GeneratedColumn<DateTime>(
        'last_practice_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    apiKey,
    liveModel,
    scoringModel,
    flashcardModel,
    flashcardTtsModel,
    bilingualBeginnerSupport,
    darkMode,
    unlockAllOverride,
    currentStreak,
    lastPracticeDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('api_key')) {
      context.handle(
        _apiKeyMeta,
        apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta),
      );
    }
    if (data.containsKey('live_model')) {
      context.handle(
        _liveModelMeta,
        liveModel.isAcceptableOrUnknown(data['live_model']!, _liveModelMeta),
      );
    }
    if (data.containsKey('scoring_model')) {
      context.handle(
        _scoringModelMeta,
        scoringModel.isAcceptableOrUnknown(
          data['scoring_model']!,
          _scoringModelMeta,
        ),
      );
    }
    if (data.containsKey('flashcard_model')) {
      context.handle(
        _flashcardModelMeta,
        flashcardModel.isAcceptableOrUnknown(
          data['flashcard_model']!,
          _flashcardModelMeta,
        ),
      );
    }
    if (data.containsKey('flashcard_tts_model')) {
      context.handle(
        _flashcardTtsModelMeta,
        flashcardTtsModel.isAcceptableOrUnknown(
          data['flashcard_tts_model']!,
          _flashcardTtsModelMeta,
        ),
      );
    }
    if (data.containsKey('bilingual_beginner_support')) {
      context.handle(
        _bilingualBeginnerSupportMeta,
        bilingualBeginnerSupport.isAcceptableOrUnknown(
          data['bilingual_beginner_support']!,
          _bilingualBeginnerSupportMeta,
        ),
      );
    }
    if (data.containsKey('dark_mode')) {
      context.handle(
        _darkModeMeta,
        darkMode.isAcceptableOrUnknown(data['dark_mode']!, _darkModeMeta),
      );
    }
    if (data.containsKey('unlock_all_override')) {
      context.handle(
        _unlockAllOverrideMeta,
        unlockAllOverride.isAcceptableOrUnknown(
          data['unlock_all_override']!,
          _unlockAllOverrideMeta,
        ),
      );
    }
    if (data.containsKey('current_streak')) {
      context.handle(
        _currentStreakMeta,
        currentStreak.isAcceptableOrUnknown(
          data['current_streak']!,
          _currentStreakMeta,
        ),
      );
    }
    if (data.containsKey('last_practice_date')) {
      context.handle(
        _lastPracticeDateMeta,
        lastPracticeDate.isAcceptableOrUnknown(
          data['last_practice_date']!,
          _lastPracticeDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      apiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_key'],
      )!,
      liveModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}live_model'],
      )!,
      scoringModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scoring_model'],
      )!,
      flashcardModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flashcard_model'],
      )!,
      flashcardTtsModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flashcard_tts_model'],
      )!,
      bilingualBeginnerSupport: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bilingual_beginner_support'],
      )!,
      darkMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dark_mode'],
      )!,
      unlockAllOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}unlock_all_override'],
      )!,
      currentStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_streak'],
      )!,
      lastPracticeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_practice_date'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String apiKey;
  final String liveModel;
  final String scoringModel;
  final String flashcardModel;
  final String flashcardTtsModel;
  final bool bilingualBeginnerSupport;
  final bool darkMode;
  final bool unlockAllOverride;
  final int currentStreak;
  final DateTime? lastPracticeDate;
  const AppSetting({
    required this.id,
    required this.apiKey,
    required this.liveModel,
    required this.scoringModel,
    required this.flashcardModel,
    required this.flashcardTtsModel,
    required this.bilingualBeginnerSupport,
    required this.darkMode,
    required this.unlockAllOverride,
    required this.currentStreak,
    this.lastPracticeDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['api_key'] = Variable<String>(apiKey);
    map['live_model'] = Variable<String>(liveModel);
    map['scoring_model'] = Variable<String>(scoringModel);
    map['flashcard_model'] = Variable<String>(flashcardModel);
    map['flashcard_tts_model'] = Variable<String>(flashcardTtsModel);
    map['bilingual_beginner_support'] = Variable<bool>(
      bilingualBeginnerSupport,
    );
    map['dark_mode'] = Variable<bool>(darkMode);
    map['unlock_all_override'] = Variable<bool>(unlockAllOverride);
    map['current_streak'] = Variable<int>(currentStreak);
    if (!nullToAbsent || lastPracticeDate != null) {
      map['last_practice_date'] = Variable<DateTime>(lastPracticeDate);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      apiKey: Value(apiKey),
      liveModel: Value(liveModel),
      scoringModel: Value(scoringModel),
      flashcardModel: Value(flashcardModel),
      flashcardTtsModel: Value(flashcardTtsModel),
      bilingualBeginnerSupport: Value(bilingualBeginnerSupport),
      darkMode: Value(darkMode),
      unlockAllOverride: Value(unlockAllOverride),
      currentStreak: Value(currentStreak),
      lastPracticeDate: lastPracticeDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPracticeDate),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      apiKey: serializer.fromJson<String>(json['apiKey']),
      liveModel: serializer.fromJson<String>(json['liveModel']),
      scoringModel: serializer.fromJson<String>(json['scoringModel']),
      flashcardModel: serializer.fromJson<String>(json['flashcardModel']),
      flashcardTtsModel: serializer.fromJson<String>(json['flashcardTtsModel']),
      bilingualBeginnerSupport: serializer.fromJson<bool>(
        json['bilingualBeginnerSupport'],
      ),
      darkMode: serializer.fromJson<bool>(json['darkMode']),
      unlockAllOverride: serializer.fromJson<bool>(json['unlockAllOverride']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      lastPracticeDate: serializer.fromJson<DateTime?>(
        json['lastPracticeDate'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'apiKey': serializer.toJson<String>(apiKey),
      'liveModel': serializer.toJson<String>(liveModel),
      'scoringModel': serializer.toJson<String>(scoringModel),
      'flashcardModel': serializer.toJson<String>(flashcardModel),
      'flashcardTtsModel': serializer.toJson<String>(flashcardTtsModel),
      'bilingualBeginnerSupport': serializer.toJson<bool>(
        bilingualBeginnerSupport,
      ),
      'darkMode': serializer.toJson<bool>(darkMode),
      'unlockAllOverride': serializer.toJson<bool>(unlockAllOverride),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'lastPracticeDate': serializer.toJson<DateTime?>(lastPracticeDate),
    };
  }

  AppSetting copyWith({
    int? id,
    String? apiKey,
    String? liveModel,
    String? scoringModel,
    String? flashcardModel,
    String? flashcardTtsModel,
    bool? bilingualBeginnerSupport,
    bool? darkMode,
    bool? unlockAllOverride,
    int? currentStreak,
    Value<DateTime?> lastPracticeDate = const Value.absent(),
  }) => AppSetting(
    id: id ?? this.id,
    apiKey: apiKey ?? this.apiKey,
    liveModel: liveModel ?? this.liveModel,
    scoringModel: scoringModel ?? this.scoringModel,
    flashcardModel: flashcardModel ?? this.flashcardModel,
    flashcardTtsModel: flashcardTtsModel ?? this.flashcardTtsModel,
    bilingualBeginnerSupport:
        bilingualBeginnerSupport ?? this.bilingualBeginnerSupport,
    darkMode: darkMode ?? this.darkMode,
    unlockAllOverride: unlockAllOverride ?? this.unlockAllOverride,
    currentStreak: currentStreak ?? this.currentStreak,
    lastPracticeDate: lastPracticeDate.present
        ? lastPracticeDate.value
        : this.lastPracticeDate,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      liveModel: data.liveModel.present ? data.liveModel.value : this.liveModel,
      scoringModel: data.scoringModel.present
          ? data.scoringModel.value
          : this.scoringModel,
      flashcardModel: data.flashcardModel.present
          ? data.flashcardModel.value
          : this.flashcardModel,
      flashcardTtsModel: data.flashcardTtsModel.present
          ? data.flashcardTtsModel.value
          : this.flashcardTtsModel,
      bilingualBeginnerSupport: data.bilingualBeginnerSupport.present
          ? data.bilingualBeginnerSupport.value
          : this.bilingualBeginnerSupport,
      darkMode: data.darkMode.present ? data.darkMode.value : this.darkMode,
      unlockAllOverride: data.unlockAllOverride.present
          ? data.unlockAllOverride.value
          : this.unlockAllOverride,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      lastPracticeDate: data.lastPracticeDate.present
          ? data.lastPracticeDate.value
          : this.lastPracticeDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('apiKey: $apiKey, ')
          ..write('liveModel: $liveModel, ')
          ..write('scoringModel: $scoringModel, ')
          ..write('flashcardModel: $flashcardModel, ')
          ..write('flashcardTtsModel: $flashcardTtsModel, ')
          ..write('bilingualBeginnerSupport: $bilingualBeginnerSupport, ')
          ..write('darkMode: $darkMode, ')
          ..write('unlockAllOverride: $unlockAllOverride, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('lastPracticeDate: $lastPracticeDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    apiKey,
    liveModel,
    scoringModel,
    flashcardModel,
    flashcardTtsModel,
    bilingualBeginnerSupport,
    darkMode,
    unlockAllOverride,
    currentStreak,
    lastPracticeDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.apiKey == this.apiKey &&
          other.liveModel == this.liveModel &&
          other.scoringModel == this.scoringModel &&
          other.flashcardModel == this.flashcardModel &&
          other.flashcardTtsModel == this.flashcardTtsModel &&
          other.bilingualBeginnerSupport == this.bilingualBeginnerSupport &&
          other.darkMode == this.darkMode &&
          other.unlockAllOverride == this.unlockAllOverride &&
          other.currentStreak == this.currentStreak &&
          other.lastPracticeDate == this.lastPracticeDate);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> apiKey;
  final Value<String> liveModel;
  final Value<String> scoringModel;
  final Value<String> flashcardModel;
  final Value<String> flashcardTtsModel;
  final Value<bool> bilingualBeginnerSupport;
  final Value<bool> darkMode;
  final Value<bool> unlockAllOverride;
  final Value<int> currentStreak;
  final Value<DateTime?> lastPracticeDate;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.liveModel = const Value.absent(),
    this.scoringModel = const Value.absent(),
    this.flashcardModel = const Value.absent(),
    this.flashcardTtsModel = const Value.absent(),
    this.bilingualBeginnerSupport = const Value.absent(),
    this.darkMode = const Value.absent(),
    this.unlockAllOverride = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.lastPracticeDate = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.liveModel = const Value.absent(),
    this.scoringModel = const Value.absent(),
    this.flashcardModel = const Value.absent(),
    this.flashcardTtsModel = const Value.absent(),
    this.bilingualBeginnerSupport = const Value.absent(),
    this.darkMode = const Value.absent(),
    this.unlockAllOverride = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.lastPracticeDate = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? apiKey,
    Expression<String>? liveModel,
    Expression<String>? scoringModel,
    Expression<String>? flashcardModel,
    Expression<String>? flashcardTtsModel,
    Expression<bool>? bilingualBeginnerSupport,
    Expression<bool>? darkMode,
    Expression<bool>? unlockAllOverride,
    Expression<int>? currentStreak,
    Expression<DateTime>? lastPracticeDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (apiKey != null) 'api_key': apiKey,
      if (liveModel != null) 'live_model': liveModel,
      if (scoringModel != null) 'scoring_model': scoringModel,
      if (flashcardModel != null) 'flashcard_model': flashcardModel,
      if (flashcardTtsModel != null) 'flashcard_tts_model': flashcardTtsModel,
      if (bilingualBeginnerSupport != null)
        'bilingual_beginner_support': bilingualBeginnerSupport,
      if (darkMode != null) 'dark_mode': darkMode,
      if (unlockAllOverride != null) 'unlock_all_override': unlockAllOverride,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (lastPracticeDate != null) 'last_practice_date': lastPracticeDate,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? apiKey,
    Value<String>? liveModel,
    Value<String>? scoringModel,
    Value<String>? flashcardModel,
    Value<String>? flashcardTtsModel,
    Value<bool>? bilingualBeginnerSupport,
    Value<bool>? darkMode,
    Value<bool>? unlockAllOverride,
    Value<int>? currentStreak,
    Value<DateTime?>? lastPracticeDate,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      apiKey: apiKey ?? this.apiKey,
      liveModel: liveModel ?? this.liveModel,
      scoringModel: scoringModel ?? this.scoringModel,
      flashcardModel: flashcardModel ?? this.flashcardModel,
      flashcardTtsModel: flashcardTtsModel ?? this.flashcardTtsModel,
      bilingualBeginnerSupport:
          bilingualBeginnerSupport ?? this.bilingualBeginnerSupport,
      darkMode: darkMode ?? this.darkMode,
      unlockAllOverride: unlockAllOverride ?? this.unlockAllOverride,
      currentStreak: currentStreak ?? this.currentStreak,
      lastPracticeDate: lastPracticeDate ?? this.lastPracticeDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (liveModel.present) {
      map['live_model'] = Variable<String>(liveModel.value);
    }
    if (scoringModel.present) {
      map['scoring_model'] = Variable<String>(scoringModel.value);
    }
    if (flashcardModel.present) {
      map['flashcard_model'] = Variable<String>(flashcardModel.value);
    }
    if (flashcardTtsModel.present) {
      map['flashcard_tts_model'] = Variable<String>(flashcardTtsModel.value);
    }
    if (bilingualBeginnerSupport.present) {
      map['bilingual_beginner_support'] = Variable<bool>(
        bilingualBeginnerSupport.value,
      );
    }
    if (darkMode.present) {
      map['dark_mode'] = Variable<bool>(darkMode.value);
    }
    if (unlockAllOverride.present) {
      map['unlock_all_override'] = Variable<bool>(unlockAllOverride.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (lastPracticeDate.present) {
      map['last_practice_date'] = Variable<DateTime>(lastPracticeDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('apiKey: $apiKey, ')
          ..write('liveModel: $liveModel, ')
          ..write('scoringModel: $scoringModel, ')
          ..write('flashcardModel: $flashcardModel, ')
          ..write('flashcardTtsModel: $flashcardTtsModel, ')
          ..write('bilingualBeginnerSupport: $bilingualBeginnerSupport, ')
          ..write('darkMode: $darkMode, ')
          ..write('unlockAllOverride: $unlockAllOverride, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('lastPracticeDate: $lastPracticeDate')
          ..write(')'))
        .toString();
  }
}

class $FlashcardDecksTable extends FlashcardDecks
    with TableInfo<$FlashcardDecksTable, FlashcardDeck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlashcardDecksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flashcard_decks';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlashcardDeck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FlashcardDeck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlashcardDeck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FlashcardDecksTable createAlias(String alias) {
    return $FlashcardDecksTable(attachedDatabase, alias);
  }
}

class FlashcardDeck extends DataClass implements Insertable<FlashcardDeck> {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FlashcardDeck({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FlashcardDecksCompanion toCompanion(bool nullToAbsent) {
    return FlashcardDecksCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FlashcardDeck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlashcardDeck(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FlashcardDeck copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FlashcardDeck(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FlashcardDeck copyWithCompanion(FlashcardDecksCompanion data) {
    return FlashcardDeck(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardDeck(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlashcardDeck &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FlashcardDecksCompanion extends UpdateCompanion<FlashcardDeck> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FlashcardDecksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FlashcardDecksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<FlashcardDeck> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FlashcardDecksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return FlashcardDecksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardDecksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FlashcardSubDecksTable extends FlashcardSubDecks
    with TableInfo<$FlashcardSubDecksTable, FlashcardSubDeck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlashcardSubDecksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<int> deckId = GeneratedColumn<int>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES flashcard_decks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    name,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flashcard_sub_decks';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlashcardSubDeck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FlashcardSubDeck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlashcardSubDeck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deck_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FlashcardSubDecksTable createAlias(String alias) {
    return $FlashcardSubDecksTable(attachedDatabase, alias);
  }
}

class FlashcardSubDeck extends DataClass
    implements Insertable<FlashcardSubDeck> {
  final int id;
  final int deckId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FlashcardSubDeck({
    required this.id,
    required this.deckId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['deck_id'] = Variable<int>(deckId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FlashcardSubDecksCompanion toCompanion(bool nullToAbsent) {
    return FlashcardSubDecksCompanion(
      id: Value(id),
      deckId: Value(deckId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FlashcardSubDeck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlashcardSubDeck(
      id: serializer.fromJson<int>(json['id']),
      deckId: serializer.fromJson<int>(json['deckId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deckId': serializer.toJson<int>(deckId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FlashcardSubDeck copyWith({
    int? id,
    int? deckId,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FlashcardSubDeck(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FlashcardSubDeck copyWithCompanion(FlashcardSubDecksCompanion data) {
    return FlashcardSubDeck(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardSubDeck(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, deckId, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlashcardSubDeck &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FlashcardSubDecksCompanion extends UpdateCompanion<FlashcardSubDeck> {
  final Value<int> id;
  final Value<int> deckId;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const FlashcardSubDecksCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FlashcardSubDecksCompanion.insert({
    this.id = const Value.absent(),
    required int deckId,
    required String name,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : deckId = Value(deckId),
       name = Value(name);
  static Insertable<FlashcardSubDeck> custom({
    Expression<int>? id,
    Expression<int>? deckId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FlashcardSubDecksCompanion copyWith({
    Value<int>? id,
    Value<int>? deckId,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return FlashcardSubDecksCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<int>(deckId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardSubDecksCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FlashcardsTable extends Flashcards
    with TableInfo<$FlashcardsTable, Flashcard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlashcardsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _subDeckIdMeta = const VerificationMeta(
    'subDeckId',
  );
  @override
  late final GeneratedColumn<int> subDeckId = GeneratedColumn<int>(
    'sub_deck_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES flashcard_sub_decks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneticMeta = const VerificationMeta(
    'phonetic',
  );
  @override
  late final GeneratedColumn<String> phonetic = GeneratedColumn<String>(
    'phonetic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meaningIdMeta = const VerificationMeta(
    'meaningId',
  );
  @override
  late final GeneratedColumn<String> meaningId = GeneratedColumn<String>(
    'meaning_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _wordTypeMeta = const VerificationMeta(
    'wordType',
  );
  @override
  late final GeneratedColumn<String> wordType = GeneratedColumn<String>(
    'word_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('non_verb'),
  );
  static const VerificationMeta _partsOfSpeechJsonMeta = const VerificationMeta(
    'partsOfSpeechJson',
  );
  @override
  late final GeneratedColumn<String> partsOfSpeechJson =
      GeneratedColumn<String>(
        'parts_of_speech_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _examplesJsonMeta = const VerificationMeta(
    'examplesJson',
  );
  @override
  late final GeneratedColumn<String> examplesJson = GeneratedColumn<String>(
    'examples_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _verbTensesExamplesJsonMeta =
      const VerificationMeta('verbTensesExamplesJson');
  @override
  late final GeneratedColumn<String> verbTensesExamplesJson =
      GeneratedColumn<String>(
        'verb_tenses_examples_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _aiConversationMeta = const VerificationMeta(
    'aiConversation',
  );
  @override
  late final GeneratedColumn<String> aiConversation = GeneratedColumn<String>(
    'ai_conversation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _masteryLevelMeta = const VerificationMeta(
    'masteryLevel',
  );
  @override
  late final GeneratedColumn<int> masteryLevel = GeneratedColumn<int>(
    'mastery_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _studyStatusMeta = const VerificationMeta(
    'studyStatus',
  );
  @override
  late final GeneratedColumn<int> studyStatus = GeneratedColumn<int>(
    'study_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subDeckId,
    word,
    phonetic,
    meaningId,
    wordType,
    partsOfSpeechJson,
    examplesJson,
    verbTensesExamplesJson,
    aiConversation,
    masteryLevel,
    studyStatus,
    reviewCount,
    lastReviewedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flashcards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Flashcard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sub_deck_id')) {
      context.handle(
        _subDeckIdMeta,
        subDeckId.isAcceptableOrUnknown(data['sub_deck_id']!, _subDeckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subDeckIdMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('phonetic')) {
      context.handle(
        _phoneticMeta,
        phonetic.isAcceptableOrUnknown(data['phonetic']!, _phoneticMeta),
      );
    }
    if (data.containsKey('meaning_id')) {
      context.handle(
        _meaningIdMeta,
        meaningId.isAcceptableOrUnknown(data['meaning_id']!, _meaningIdMeta),
      );
    }
    if (data.containsKey('word_type')) {
      context.handle(
        _wordTypeMeta,
        wordType.isAcceptableOrUnknown(data['word_type']!, _wordTypeMeta),
      );
    }
    if (data.containsKey('parts_of_speech_json')) {
      context.handle(
        _partsOfSpeechJsonMeta,
        partsOfSpeechJson.isAcceptableOrUnknown(
          data['parts_of_speech_json']!,
          _partsOfSpeechJsonMeta,
        ),
      );
    }
    if (data.containsKey('examples_json')) {
      context.handle(
        _examplesJsonMeta,
        examplesJson.isAcceptableOrUnknown(
          data['examples_json']!,
          _examplesJsonMeta,
        ),
      );
    }
    if (data.containsKey('verb_tenses_examples_json')) {
      context.handle(
        _verbTensesExamplesJsonMeta,
        verbTensesExamplesJson.isAcceptableOrUnknown(
          data['verb_tenses_examples_json']!,
          _verbTensesExamplesJsonMeta,
        ),
      );
    }
    if (data.containsKey('ai_conversation')) {
      context.handle(
        _aiConversationMeta,
        aiConversation.isAcceptableOrUnknown(
          data['ai_conversation']!,
          _aiConversationMeta,
        ),
      );
    }
    if (data.containsKey('mastery_level')) {
      context.handle(
        _masteryLevelMeta,
        masteryLevel.isAcceptableOrUnknown(
          data['mastery_level']!,
          _masteryLevelMeta,
        ),
      );
    }
    if (data.containsKey('study_status')) {
      context.handle(
        _studyStatusMeta,
        studyStatus.isAcceptableOrUnknown(
          data['study_status']!,
          _studyStatusMeta,
        ),
      );
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Flashcard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Flashcard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      subDeckId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sub_deck_id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      phonetic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phonetic'],
      ),
      meaningId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning_id'],
      )!,
      wordType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_type'],
      )!,
      partsOfSpeechJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parts_of_speech_json'],
      )!,
      examplesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examples_json'],
      )!,
      verbTensesExamplesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verb_tenses_examples_json'],
      )!,
      aiConversation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_conversation'],
      )!,
      masteryLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mastery_level'],
      )!,
      studyStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}study_status'],
      )!,
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FlashcardsTable createAlias(String alias) {
    return $FlashcardsTable(attachedDatabase, alias);
  }
}

class Flashcard extends DataClass implements Insertable<Flashcard> {
  final int id;
  final int subDeckId;
  final String word;
  final String? phonetic;
  final String meaningId;
  final String wordType;
  final String partsOfSpeechJson;
  final String examplesJson;
  final String verbTensesExamplesJson;
  final String aiConversation;
  final int masteryLevel;
  final int studyStatus;
  final int reviewCount;
  final DateTime? lastReviewedAt;
  final DateTime createdAt;
  const Flashcard({
    required this.id,
    required this.subDeckId,
    required this.word,
    this.phonetic,
    required this.meaningId,
    required this.wordType,
    required this.partsOfSpeechJson,
    required this.examplesJson,
    required this.verbTensesExamplesJson,
    required this.aiConversation,
    required this.masteryLevel,
    required this.studyStatus,
    required this.reviewCount,
    this.lastReviewedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sub_deck_id'] = Variable<int>(subDeckId);
    map['word'] = Variable<String>(word);
    if (!nullToAbsent || phonetic != null) {
      map['phonetic'] = Variable<String>(phonetic);
    }
    map['meaning_id'] = Variable<String>(meaningId);
    map['word_type'] = Variable<String>(wordType);
    map['parts_of_speech_json'] = Variable<String>(partsOfSpeechJson);
    map['examples_json'] = Variable<String>(examplesJson);
    map['verb_tenses_examples_json'] = Variable<String>(verbTensesExamplesJson);
    map['ai_conversation'] = Variable<String>(aiConversation);
    map['mastery_level'] = Variable<int>(masteryLevel);
    map['study_status'] = Variable<int>(studyStatus);
    map['review_count'] = Variable<int>(reviewCount);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FlashcardsCompanion toCompanion(bool nullToAbsent) {
    return FlashcardsCompanion(
      id: Value(id),
      subDeckId: Value(subDeckId),
      word: Value(word),
      phonetic: phonetic == null && nullToAbsent
          ? const Value.absent()
          : Value(phonetic),
      meaningId: Value(meaningId),
      wordType: Value(wordType),
      partsOfSpeechJson: Value(partsOfSpeechJson),
      examplesJson: Value(examplesJson),
      verbTensesExamplesJson: Value(verbTensesExamplesJson),
      aiConversation: Value(aiConversation),
      masteryLevel: Value(masteryLevel),
      studyStatus: Value(studyStatus),
      reviewCount: Value(reviewCount),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Flashcard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Flashcard(
      id: serializer.fromJson<int>(json['id']),
      subDeckId: serializer.fromJson<int>(json['subDeckId']),
      word: serializer.fromJson<String>(json['word']),
      phonetic: serializer.fromJson<String?>(json['phonetic']),
      meaningId: serializer.fromJson<String>(json['meaningId']),
      wordType: serializer.fromJson<String>(json['wordType']),
      partsOfSpeechJson: serializer.fromJson<String>(json['partsOfSpeechJson']),
      examplesJson: serializer.fromJson<String>(json['examplesJson']),
      verbTensesExamplesJson: serializer.fromJson<String>(
        json['verbTensesExamplesJson'],
      ),
      aiConversation: serializer.fromJson<String>(json['aiConversation']),
      masteryLevel: serializer.fromJson<int>(json['masteryLevel']),
      studyStatus: serializer.fromJson<int>(json['studyStatus']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'subDeckId': serializer.toJson<int>(subDeckId),
      'word': serializer.toJson<String>(word),
      'phonetic': serializer.toJson<String?>(phonetic),
      'meaningId': serializer.toJson<String>(meaningId),
      'wordType': serializer.toJson<String>(wordType),
      'partsOfSpeechJson': serializer.toJson<String>(partsOfSpeechJson),
      'examplesJson': serializer.toJson<String>(examplesJson),
      'verbTensesExamplesJson': serializer.toJson<String>(
        verbTensesExamplesJson,
      ),
      'aiConversation': serializer.toJson<String>(aiConversation),
      'masteryLevel': serializer.toJson<int>(masteryLevel),
      'studyStatus': serializer.toJson<int>(studyStatus),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Flashcard copyWith({
    int? id,
    int? subDeckId,
    String? word,
    Value<String?> phonetic = const Value.absent(),
    String? meaningId,
    String? wordType,
    String? partsOfSpeechJson,
    String? examplesJson,
    String? verbTensesExamplesJson,
    String? aiConversation,
    int? masteryLevel,
    int? studyStatus,
    int? reviewCount,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    DateTime? createdAt,
  }) => Flashcard(
    id: id ?? this.id,
    subDeckId: subDeckId ?? this.subDeckId,
    word: word ?? this.word,
    phonetic: phonetic.present ? phonetic.value : this.phonetic,
    meaningId: meaningId ?? this.meaningId,
    wordType: wordType ?? this.wordType,
    partsOfSpeechJson: partsOfSpeechJson ?? this.partsOfSpeechJson,
    examplesJson: examplesJson ?? this.examplesJson,
    verbTensesExamplesJson:
        verbTensesExamplesJson ?? this.verbTensesExamplesJson,
    aiConversation: aiConversation ?? this.aiConversation,
    masteryLevel: masteryLevel ?? this.masteryLevel,
    studyStatus: studyStatus ?? this.studyStatus,
    reviewCount: reviewCount ?? this.reviewCount,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Flashcard copyWithCompanion(FlashcardsCompanion data) {
    return Flashcard(
      id: data.id.present ? data.id.value : this.id,
      subDeckId: data.subDeckId.present ? data.subDeckId.value : this.subDeckId,
      word: data.word.present ? data.word.value : this.word,
      phonetic: data.phonetic.present ? data.phonetic.value : this.phonetic,
      meaningId: data.meaningId.present ? data.meaningId.value : this.meaningId,
      wordType: data.wordType.present ? data.wordType.value : this.wordType,
      partsOfSpeechJson: data.partsOfSpeechJson.present
          ? data.partsOfSpeechJson.value
          : this.partsOfSpeechJson,
      examplesJson: data.examplesJson.present
          ? data.examplesJson.value
          : this.examplesJson,
      verbTensesExamplesJson: data.verbTensesExamplesJson.present
          ? data.verbTensesExamplesJson.value
          : this.verbTensesExamplesJson,
      aiConversation: data.aiConversation.present
          ? data.aiConversation.value
          : this.aiConversation,
      masteryLevel: data.masteryLevel.present
          ? data.masteryLevel.value
          : this.masteryLevel,
      studyStatus: data.studyStatus.present
          ? data.studyStatus.value
          : this.studyStatus,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Flashcard(')
          ..write('id: $id, ')
          ..write('subDeckId: $subDeckId, ')
          ..write('word: $word, ')
          ..write('phonetic: $phonetic, ')
          ..write('meaningId: $meaningId, ')
          ..write('wordType: $wordType, ')
          ..write('partsOfSpeechJson: $partsOfSpeechJson, ')
          ..write('examplesJson: $examplesJson, ')
          ..write('verbTensesExamplesJson: $verbTensesExamplesJson, ')
          ..write('aiConversation: $aiConversation, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('studyStatus: $studyStatus, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subDeckId,
    word,
    phonetic,
    meaningId,
    wordType,
    partsOfSpeechJson,
    examplesJson,
    verbTensesExamplesJson,
    aiConversation,
    masteryLevel,
    studyStatus,
    reviewCount,
    lastReviewedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Flashcard &&
          other.id == this.id &&
          other.subDeckId == this.subDeckId &&
          other.word == this.word &&
          other.phonetic == this.phonetic &&
          other.meaningId == this.meaningId &&
          other.wordType == this.wordType &&
          other.partsOfSpeechJson == this.partsOfSpeechJson &&
          other.examplesJson == this.examplesJson &&
          other.verbTensesExamplesJson == this.verbTensesExamplesJson &&
          other.aiConversation == this.aiConversation &&
          other.masteryLevel == this.masteryLevel &&
          other.studyStatus == this.studyStatus &&
          other.reviewCount == this.reviewCount &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.createdAt == this.createdAt);
}

class FlashcardsCompanion extends UpdateCompanion<Flashcard> {
  final Value<int> id;
  final Value<int> subDeckId;
  final Value<String> word;
  final Value<String?> phonetic;
  final Value<String> meaningId;
  final Value<String> wordType;
  final Value<String> partsOfSpeechJson;
  final Value<String> examplesJson;
  final Value<String> verbTensesExamplesJson;
  final Value<String> aiConversation;
  final Value<int> masteryLevel;
  final Value<int> studyStatus;
  final Value<int> reviewCount;
  final Value<DateTime?> lastReviewedAt;
  final Value<DateTime> createdAt;
  const FlashcardsCompanion({
    this.id = const Value.absent(),
    this.subDeckId = const Value.absent(),
    this.word = const Value.absent(),
    this.phonetic = const Value.absent(),
    this.meaningId = const Value.absent(),
    this.wordType = const Value.absent(),
    this.partsOfSpeechJson = const Value.absent(),
    this.examplesJson = const Value.absent(),
    this.verbTensesExamplesJson = const Value.absent(),
    this.aiConversation = const Value.absent(),
    this.masteryLevel = const Value.absent(),
    this.studyStatus = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FlashcardsCompanion.insert({
    this.id = const Value.absent(),
    required int subDeckId,
    required String word,
    this.phonetic = const Value.absent(),
    this.meaningId = const Value.absent(),
    this.wordType = const Value.absent(),
    this.partsOfSpeechJson = const Value.absent(),
    this.examplesJson = const Value.absent(),
    this.verbTensesExamplesJson = const Value.absent(),
    this.aiConversation = const Value.absent(),
    this.masteryLevel = const Value.absent(),
    this.studyStatus = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : subDeckId = Value(subDeckId),
       word = Value(word);
  static Insertable<Flashcard> custom({
    Expression<int>? id,
    Expression<int>? subDeckId,
    Expression<String>? word,
    Expression<String>? phonetic,
    Expression<String>? meaningId,
    Expression<String>? wordType,
    Expression<String>? partsOfSpeechJson,
    Expression<String>? examplesJson,
    Expression<String>? verbTensesExamplesJson,
    Expression<String>? aiConversation,
    Expression<int>? masteryLevel,
    Expression<int>? studyStatus,
    Expression<int>? reviewCount,
    Expression<DateTime>? lastReviewedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subDeckId != null) 'sub_deck_id': subDeckId,
      if (word != null) 'word': word,
      if (phonetic != null) 'phonetic': phonetic,
      if (meaningId != null) 'meaning_id': meaningId,
      if (wordType != null) 'word_type': wordType,
      if (partsOfSpeechJson != null) 'parts_of_speech_json': partsOfSpeechJson,
      if (examplesJson != null) 'examples_json': examplesJson,
      if (verbTensesExamplesJson != null)
        'verb_tenses_examples_json': verbTensesExamplesJson,
      if (aiConversation != null) 'ai_conversation': aiConversation,
      if (masteryLevel != null) 'mastery_level': masteryLevel,
      if (studyStatus != null) 'study_status': studyStatus,
      if (reviewCount != null) 'review_count': reviewCount,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FlashcardsCompanion copyWith({
    Value<int>? id,
    Value<int>? subDeckId,
    Value<String>? word,
    Value<String?>? phonetic,
    Value<String>? meaningId,
    Value<String>? wordType,
    Value<String>? partsOfSpeechJson,
    Value<String>? examplesJson,
    Value<String>? verbTensesExamplesJson,
    Value<String>? aiConversation,
    Value<int>? masteryLevel,
    Value<int>? studyStatus,
    Value<int>? reviewCount,
    Value<DateTime?>? lastReviewedAt,
    Value<DateTime>? createdAt,
  }) {
    return FlashcardsCompanion(
      id: id ?? this.id,
      subDeckId: subDeckId ?? this.subDeckId,
      word: word ?? this.word,
      phonetic: phonetic ?? this.phonetic,
      meaningId: meaningId ?? this.meaningId,
      wordType: wordType ?? this.wordType,
      partsOfSpeechJson: partsOfSpeechJson ?? this.partsOfSpeechJson,
      examplesJson: examplesJson ?? this.examplesJson,
      verbTensesExamplesJson:
          verbTensesExamplesJson ?? this.verbTensesExamplesJson,
      aiConversation: aiConversation ?? this.aiConversation,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      studyStatus: studyStatus ?? this.studyStatus,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (subDeckId.present) {
      map['sub_deck_id'] = Variable<int>(subDeckId.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (phonetic.present) {
      map['phonetic'] = Variable<String>(phonetic.value);
    }
    if (meaningId.present) {
      map['meaning_id'] = Variable<String>(meaningId.value);
    }
    if (wordType.present) {
      map['word_type'] = Variable<String>(wordType.value);
    }
    if (partsOfSpeechJson.present) {
      map['parts_of_speech_json'] = Variable<String>(partsOfSpeechJson.value);
    }
    if (examplesJson.present) {
      map['examples_json'] = Variable<String>(examplesJson.value);
    }
    if (verbTensesExamplesJson.present) {
      map['verb_tenses_examples_json'] = Variable<String>(
        verbTensesExamplesJson.value,
      );
    }
    if (aiConversation.present) {
      map['ai_conversation'] = Variable<String>(aiConversation.value);
    }
    if (masteryLevel.present) {
      map['mastery_level'] = Variable<int>(masteryLevel.value);
    }
    if (studyStatus.present) {
      map['study_status'] = Variable<int>(studyStatus.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardsCompanion(')
          ..write('id: $id, ')
          ..write('subDeckId: $subDeckId, ')
          ..write('word: $word, ')
          ..write('phonetic: $phonetic, ')
          ..write('meaningId: $meaningId, ')
          ..write('wordType: $wordType, ')
          ..write('partsOfSpeechJson: $partsOfSpeechJson, ')
          ..write('examplesJson: $examplesJson, ')
          ..write('verbTensesExamplesJson: $verbTensesExamplesJson, ')
          ..write('aiConversation: $aiConversation, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('studyStatus: $studyStatus, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LevelsTable levels = $LevelsTable(this);
  late final $LessonsTable lessons = $LessonsTable(this);
  late final $PracticeSessionsTable practiceSessions = $PracticeSessionsTable(
    this,
  );
  late final $MistakesTable mistakes = $MistakesTable(this);
  late final $VocabItemsTable vocabItems = $VocabItemsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $FlashcardDecksTable flashcardDecks = $FlashcardDecksTable(this);
  late final $FlashcardSubDecksTable flashcardSubDecks =
      $FlashcardSubDecksTable(this);
  late final $FlashcardsTable flashcards = $FlashcardsTable(this);
  late final RoadmapDao roadmapDao = RoadmapDao(this as AppDatabase);
  late final PracticeDao practiceDao = PracticeDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final FlashcardDao flashcardDao = FlashcardDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    levels,
    lessons,
    practiceSessions,
    mistakes,
    vocabItems,
    appSettings,
    flashcardDecks,
    flashcardSubDecks,
    flashcards,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'levels',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lessons', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'lessons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('practice_sessions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('mistakes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('vocab_items', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'flashcard_decks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('flashcard_sub_decks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'flashcard_sub_decks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('flashcards', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LevelsTableCreateCompanionBuilder =
    LevelsCompanion Function({
      Value<int> id,
      required String code,
      required String title,
      required String description,
      required int orderIndex,
      Value<int> minPassScore,
      Value<bool> isUnlocked,
    });
typedef $$LevelsTableUpdateCompanionBuilder =
    LevelsCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String> title,
      Value<String> description,
      Value<int> orderIndex,
      Value<int> minPassScore,
      Value<bool> isUnlocked,
    });

final class $$LevelsTableReferences
    extends BaseReferences<_$AppDatabase, $LevelsTable, Level> {
  $$LevelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LessonsTable, List<Lesson>> _lessonsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.lessons,
    aliasName: 'levels__id__lessons__level_id',
  );

  $$LessonsTableProcessedTableManager get lessonsRefs {
    final manager = $$LessonsTableTableManager(
      $_db,
      $_db.lessons,
    ).filter((f) => f.levelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lessonsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LevelsTableFilterComposer
    extends Composer<_$AppDatabase, $LevelsTable> {
  $$LevelsTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minPassScore => $composableBuilder(
    column: $table.minPassScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> lessonsRefs(
    Expression<bool> Function($$LessonsTableFilterComposer f) f,
  ) {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.levelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableFilterComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LevelsTableOrderingComposer
    extends Composer<_$AppDatabase, $LevelsTable> {
  $$LevelsTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minPassScore => $composableBuilder(
    column: $table.minPassScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LevelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LevelsTable> {
  $$LevelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minPassScore => $composableBuilder(
    column: $table.minPassScore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => column,
  );

  Expression<T> lessonsRefs<T extends Object>(
    Expression<T> Function($$LessonsTableAnnotationComposer a) f,
  ) {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.levelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableAnnotationComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LevelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LevelsTable,
          Level,
          $$LevelsTableFilterComposer,
          $$LevelsTableOrderingComposer,
          $$LevelsTableAnnotationComposer,
          $$LevelsTableCreateCompanionBuilder,
          $$LevelsTableUpdateCompanionBuilder,
          (Level, $$LevelsTableReferences),
          Level,
          PrefetchHooks Function({bool lessonsRefs})
        > {
  $$LevelsTableTableManager(_$AppDatabase db, $LevelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LevelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LevelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LevelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> minPassScore = const Value.absent(),
                Value<bool> isUnlocked = const Value.absent(),
              }) => LevelsCompanion(
                id: id,
                code: code,
                title: title,
                description: description,
                orderIndex: orderIndex,
                minPassScore: minPassScore,
                isUnlocked: isUnlocked,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required String title,
                required String description,
                required int orderIndex,
                Value<int> minPassScore = const Value.absent(),
                Value<bool> isUnlocked = const Value.absent(),
              }) => LevelsCompanion.insert(
                id: id,
                code: code,
                title: title,
                description: description,
                orderIndex: orderIndex,
                minPassScore: minPassScore,
                isUnlocked: isUnlocked,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$LevelsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({lessonsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (lessonsRefs) db.lessons],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lessonsRefs)
                    await $_getPrefetchedData<Level, $LevelsTable, Lesson>(
                      currentTable: table,
                      referencedTable: $$LevelsTableReferences
                          ._lessonsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LevelsTableReferences(db, table, p0).lessonsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.levelId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LevelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LevelsTable,
      Level,
      $$LevelsTableFilterComposer,
      $$LevelsTableOrderingComposer,
      $$LevelsTableAnnotationComposer,
      $$LevelsTableCreateCompanionBuilder,
      $$LevelsTableUpdateCompanionBuilder,
      (Level, $$LevelsTableReferences),
      Level,
      PrefetchHooks Function({bool lessonsRefs})
    >;
typedef $$LessonsTableCreateCompanionBuilder =
    LessonsCompanion Function({
      Value<int> id,
      required int levelId,
      required String title,
      required String scenarioPrompt,
      required String systemInstruction,
      required String mode,
      Value<int> targetDurationSec,
      required int orderIndex,
      Value<bool> isUnlocked,
      Value<int> bestScore,
      Value<bool> isCompleted,
    });
typedef $$LessonsTableUpdateCompanionBuilder =
    LessonsCompanion Function({
      Value<int> id,
      Value<int> levelId,
      Value<String> title,
      Value<String> scenarioPrompt,
      Value<String> systemInstruction,
      Value<String> mode,
      Value<int> targetDurationSec,
      Value<int> orderIndex,
      Value<bool> isUnlocked,
      Value<int> bestScore,
      Value<bool> isCompleted,
    });

final class $$LessonsTableReferences
    extends BaseReferences<_$AppDatabase, $LessonsTable, Lesson> {
  $$LessonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LevelsTable _levelIdTable(_$AppDatabase db) =>
      db.levels.createAlias('lessons__level_id__levels__id');

  $$LevelsTableProcessedTableManager get levelId {
    final $_column = $_itemColumn<int>('level_id')!;

    final manager = $$LevelsTableTableManager(
      $_db,
      $_db.levels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_levelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PracticeSessionsTable, List<PracticeSession>>
  _practiceSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.practiceSessions,
    aliasName: 'lessons__id__practice_sessions__lesson_id',
  );

  $$PracticeSessionsTableProcessedTableManager get practiceSessionsRefs {
    final manager = $$PracticeSessionsTableTableManager(
      $_db,
      $_db.practiceSessions,
    ).filter((f) => f.lessonId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _practiceSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LessonsTableFilterComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scenarioPrompt => $composableBuilder(
    column: $table.scenarioPrompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get systemInstruction => $composableBuilder(
    column: $table.systemInstruction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDurationSec => $composableBuilder(
    column: $table.targetDurationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestScore => $composableBuilder(
    column: $table.bestScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  $$LevelsTableFilterComposer get levelId {
    final $$LevelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.levelId,
      referencedTable: $db.levels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LevelsTableFilterComposer(
            $db: $db,
            $table: $db.levels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> practiceSessionsRefs(
    Expression<bool> Function($$PracticeSessionsTableFilterComposer f) f,
  ) {
    final $$PracticeSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.lessonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableFilterComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LessonsTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scenarioPrompt => $composableBuilder(
    column: $table.scenarioPrompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get systemInstruction => $composableBuilder(
    column: $table.systemInstruction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDurationSec => $composableBuilder(
    column: $table.targetDurationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestScore => $composableBuilder(
    column: $table.bestScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$LevelsTableOrderingComposer get levelId {
    final $$LevelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.levelId,
      referencedTable: $db.levels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LevelsTableOrderingComposer(
            $db: $db,
            $table: $db.levels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonsTable> {
  $$LessonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get scenarioPrompt => $composableBuilder(
    column: $table.scenarioPrompt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get systemInstruction => $composableBuilder(
    column: $table.systemInstruction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get targetDurationSec => $composableBuilder(
    column: $table.targetDurationSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bestScore =>
      $composableBuilder(column: $table.bestScore, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  $$LevelsTableAnnotationComposer get levelId {
    final $$LevelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.levelId,
      referencedTable: $db.levels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LevelsTableAnnotationComposer(
            $db: $db,
            $table: $db.levels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> practiceSessionsRefs<T extends Object>(
    Expression<T> Function($$PracticeSessionsTableAnnotationComposer a) f,
  ) {
    final $$PracticeSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.lessonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LessonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonsTable,
          Lesson,
          $$LessonsTableFilterComposer,
          $$LessonsTableOrderingComposer,
          $$LessonsTableAnnotationComposer,
          $$LessonsTableCreateCompanionBuilder,
          $$LessonsTableUpdateCompanionBuilder,
          (Lesson, $$LessonsTableReferences),
          Lesson,
          PrefetchHooks Function({bool levelId, bool practiceSessionsRefs})
        > {
  $$LessonsTableTableManager(_$AppDatabase db, $LessonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> levelId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> scenarioPrompt = const Value.absent(),
                Value<String> systemInstruction = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int> targetDurationSec = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> isUnlocked = const Value.absent(),
                Value<int> bestScore = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
              }) => LessonsCompanion(
                id: id,
                levelId: levelId,
                title: title,
                scenarioPrompt: scenarioPrompt,
                systemInstruction: systemInstruction,
                mode: mode,
                targetDurationSec: targetDurationSec,
                orderIndex: orderIndex,
                isUnlocked: isUnlocked,
                bestScore: bestScore,
                isCompleted: isCompleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int levelId,
                required String title,
                required String scenarioPrompt,
                required String systemInstruction,
                required String mode,
                Value<int> targetDurationSec = const Value.absent(),
                required int orderIndex,
                Value<bool> isUnlocked = const Value.absent(),
                Value<int> bestScore = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
              }) => LessonsCompanion.insert(
                id: id,
                levelId: levelId,
                title: title,
                scenarioPrompt: scenarioPrompt,
                systemInstruction: systemInstruction,
                mode: mode,
                targetDurationSec: targetDurationSec,
                orderIndex: orderIndex,
                isUnlocked: isUnlocked,
                bestScore: bestScore,
                isCompleted: isCompleted,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LessonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({levelId = false, practiceSessionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (practiceSessionsRefs) db.practiceSessions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (levelId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.levelId,
                                    referencedTable: $$LessonsTableReferences
                                        ._levelIdTable(db),
                                    referencedColumn: $$LessonsTableReferences
                                        ._levelIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (practiceSessionsRefs)
                        await $_getPrefetchedData<
                          Lesson,
                          $LessonsTable,
                          PracticeSession
                        >(
                          currentTable: table,
                          referencedTable: $$LessonsTableReferences
                              ._practiceSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LessonsTableReferences(
                                db,
                                table,
                                p0,
                              ).practiceSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.lessonId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LessonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonsTable,
      Lesson,
      $$LessonsTableFilterComposer,
      $$LessonsTableOrderingComposer,
      $$LessonsTableAnnotationComposer,
      $$LessonsTableCreateCompanionBuilder,
      $$LessonsTableUpdateCompanionBuilder,
      (Lesson, $$LessonsTableReferences),
      Lesson,
      PrefetchHooks Function({bool levelId, bool practiceSessionsRefs})
    >;
typedef $$PracticeSessionsTableCreateCompanionBuilder =
    PracticeSessionsCompanion Function({
      Value<int> id,
      Value<int?> lessonId,
      required String sessionType,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int> durationSec,
      Value<String> transcriptJson,
      Value<int> overallScore,
      Value<int> fluencyScore,
      Value<int> grammarScore,
      Value<int> vocabScore,
      Value<int> pronunciationScore,
      Value<int> fillerCount,
      Value<String> aiSummary,
      Value<bool> passed,
    });
typedef $$PracticeSessionsTableUpdateCompanionBuilder =
    PracticeSessionsCompanion Function({
      Value<int> id,
      Value<int?> lessonId,
      Value<String> sessionType,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> durationSec,
      Value<String> transcriptJson,
      Value<int> overallScore,
      Value<int> fluencyScore,
      Value<int> grammarScore,
      Value<int> vocabScore,
      Value<int> pronunciationScore,
      Value<int> fillerCount,
      Value<String> aiSummary,
      Value<bool> passed,
    });

final class $$PracticeSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PracticeSessionsTable, PracticeSession> {
  $$PracticeSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LessonsTable _lessonIdTable(_$AppDatabase db) =>
      db.lessons.createAlias('practice_sessions__lesson_id__lessons__id');

  $$LessonsTableProcessedTableManager? get lessonId {
    final $_column = $_itemColumn<int>('lesson_id');
    if ($_column == null) return null;
    final manager = $$LessonsTableTableManager(
      $_db,
      $_db.lessons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MistakesTable, List<Mistake>> _mistakesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.mistakes,
    aliasName: 'practice_sessions__id__mistakes__session_id',
  );

  $$MistakesTableProcessedTableManager get mistakesRefs {
    final manager = $$MistakesTableTableManager(
      $_db,
      $_db.mistakes,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mistakesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VocabItemsTable, List<VocabItem>>
  _vocabItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.vocabItems,
    aliasName: 'practice_sessions__id__vocab_items__session_id',
  );

  $$VocabItemsTableProcessedTableManager get vocabItemsRefs {
    final manager = $$VocabItemsTableTableManager(
      $_db,
      $_db.vocabItems,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_vocabItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PracticeSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableFilterComposer({
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

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcriptJson => $composableBuilder(
    column: $table.transcriptJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overallScore => $composableBuilder(
    column: $table.overallScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fluencyScore => $composableBuilder(
    column: $table.fluencyScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grammarScore => $composableBuilder(
    column: $table.grammarScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vocabScore => $composableBuilder(
    column: $table.vocabScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pronunciationScore => $composableBuilder(
    column: $table.pronunciationScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fillerCount => $composableBuilder(
    column: $table.fillerCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiSummary => $composableBuilder(
    column: $table.aiSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get passed => $composableBuilder(
    column: $table.passed,
    builder: (column) => ColumnFilters(column),
  );

  $$LessonsTableFilterComposer get lessonId {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableFilterComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> mistakesRefs(
    Expression<bool> Function($$MistakesTableFilterComposer f) f,
  ) {
    final $$MistakesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mistakes,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MistakesTableFilterComposer(
            $db: $db,
            $table: $db.mistakes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> vocabItemsRefs(
    Expression<bool> Function($$VocabItemsTableFilterComposer f) f,
  ) {
    final $$VocabItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vocabItems,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabItemsTableFilterComposer(
            $db: $db,
            $table: $db.vocabItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcriptJson => $composableBuilder(
    column: $table.transcriptJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overallScore => $composableBuilder(
    column: $table.overallScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fluencyScore => $composableBuilder(
    column: $table.fluencyScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grammarScore => $composableBuilder(
    column: $table.grammarScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vocabScore => $composableBuilder(
    column: $table.vocabScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pronunciationScore => $composableBuilder(
    column: $table.pronunciationScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fillerCount => $composableBuilder(
    column: $table.fillerCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiSummary => $composableBuilder(
    column: $table.aiSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get passed => $composableBuilder(
    column: $table.passed,
    builder: (column) => ColumnOrderings(column),
  );

  $$LessonsTableOrderingComposer get lessonId {
    final $$LessonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableOrderingComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transcriptJson => $composableBuilder(
    column: $table.transcriptJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overallScore => $composableBuilder(
    column: $table.overallScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fluencyScore => $composableBuilder(
    column: $table.fluencyScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grammarScore => $composableBuilder(
    column: $table.grammarScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vocabScore => $composableBuilder(
    column: $table.vocabScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pronunciationScore => $composableBuilder(
    column: $table.pronunciationScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fillerCount => $composableBuilder(
    column: $table.fillerCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiSummary =>
      $composableBuilder(column: $table.aiSummary, builder: (column) => column);

  GeneratedColumn<bool> get passed =>
      $composableBuilder(column: $table.passed, builder: (column) => column);

  $$LessonsTableAnnotationComposer get lessonId {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableAnnotationComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> mistakesRefs<T extends Object>(
    Expression<T> Function($$MistakesTableAnnotationComposer a) f,
  ) {
    final $$MistakesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mistakes,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MistakesTableAnnotationComposer(
            $db: $db,
            $table: $db.mistakes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> vocabItemsRefs<T extends Object>(
    Expression<T> Function($$VocabItemsTableAnnotationComposer a) f,
  ) {
    final $$VocabItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vocabItems,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VocabItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.vocabItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PracticeSessionsTable,
          PracticeSession,
          $$PracticeSessionsTableFilterComposer,
          $$PracticeSessionsTableOrderingComposer,
          $$PracticeSessionsTableAnnotationComposer,
          $$PracticeSessionsTableCreateCompanionBuilder,
          $$PracticeSessionsTableUpdateCompanionBuilder,
          (PracticeSession, $$PracticeSessionsTableReferences),
          PracticeSession,
          PrefetchHooks Function({
            bool lessonId,
            bool mistakesRefs,
            bool vocabItemsRefs,
          })
        > {
  $$PracticeSessionsTableTableManager(
    _$AppDatabase db,
    $PracticeSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> lessonId = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<String> transcriptJson = const Value.absent(),
                Value<int> overallScore = const Value.absent(),
                Value<int> fluencyScore = const Value.absent(),
                Value<int> grammarScore = const Value.absent(),
                Value<int> vocabScore = const Value.absent(),
                Value<int> pronunciationScore = const Value.absent(),
                Value<int> fillerCount = const Value.absent(),
                Value<String> aiSummary = const Value.absent(),
                Value<bool> passed = const Value.absent(),
              }) => PracticeSessionsCompanion(
                id: id,
                lessonId: lessonId,
                sessionType: sessionType,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSec: durationSec,
                transcriptJson: transcriptJson,
                overallScore: overallScore,
                fluencyScore: fluencyScore,
                grammarScore: grammarScore,
                vocabScore: vocabScore,
                pronunciationScore: pronunciationScore,
                fillerCount: fillerCount,
                aiSummary: aiSummary,
                passed: passed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> lessonId = const Value.absent(),
                required String sessionType,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> durationSec = const Value.absent(),
                Value<String> transcriptJson = const Value.absent(),
                Value<int> overallScore = const Value.absent(),
                Value<int> fluencyScore = const Value.absent(),
                Value<int> grammarScore = const Value.absent(),
                Value<int> vocabScore = const Value.absent(),
                Value<int> pronunciationScore = const Value.absent(),
                Value<int> fillerCount = const Value.absent(),
                Value<String> aiSummary = const Value.absent(),
                Value<bool> passed = const Value.absent(),
              }) => PracticeSessionsCompanion.insert(
                id: id,
                lessonId: lessonId,
                sessionType: sessionType,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSec: durationSec,
                transcriptJson: transcriptJson,
                overallScore: overallScore,
                fluencyScore: fluencyScore,
                grammarScore: grammarScore,
                vocabScore: vocabScore,
                pronunciationScore: pronunciationScore,
                fillerCount: fillerCount,
                aiSummary: aiSummary,
                passed: passed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                lessonId = false,
                mistakesRefs = false,
                vocabItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mistakesRefs) db.mistakes,
                    if (vocabItemsRefs) db.vocabItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (lessonId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lessonId,
                                    referencedTable:
                                        $$PracticeSessionsTableReferences
                                            ._lessonIdTable(db),
                                    referencedColumn:
                                        $$PracticeSessionsTableReferences
                                            ._lessonIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mistakesRefs)
                        await $_getPrefetchedData<
                          PracticeSession,
                          $PracticeSessionsTable,
                          Mistake
                        >(
                          currentTable: table,
                          referencedTable: $$PracticeSessionsTableReferences
                              ._mistakesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PracticeSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).mistakesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (vocabItemsRefs)
                        await $_getPrefetchedData<
                          PracticeSession,
                          $PracticeSessionsTable,
                          VocabItem
                        >(
                          currentTable: table,
                          referencedTable: $$PracticeSessionsTableReferences
                              ._vocabItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PracticeSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).vocabItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PracticeSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PracticeSessionsTable,
      PracticeSession,
      $$PracticeSessionsTableFilterComposer,
      $$PracticeSessionsTableOrderingComposer,
      $$PracticeSessionsTableAnnotationComposer,
      $$PracticeSessionsTableCreateCompanionBuilder,
      $$PracticeSessionsTableUpdateCompanionBuilder,
      (PracticeSession, $$PracticeSessionsTableReferences),
      PracticeSession,
      PrefetchHooks Function({
        bool lessonId,
        bool mistakesRefs,
        bool vocabItemsRefs,
      })
    >;
typedef $$MistakesTableCreateCompanionBuilder =
    MistakesCompanion Function({
      Value<int> id,
      required int sessionId,
      required String originalSentence,
      required String correctedSentence,
      required String explanation,
      required String category,
      required DateTime createdAt,
    });
typedef $$MistakesTableUpdateCompanionBuilder =
    MistakesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> originalSentence,
      Value<String> correctedSentence,
      Value<String> explanation,
      Value<String> category,
      Value<DateTime> createdAt,
    });

final class $$MistakesTableReferences
    extends BaseReferences<_$AppDatabase, $MistakesTable, Mistake> {
  $$MistakesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PracticeSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .practiceSessions
      .createAlias('mistakes__session_id__practice_sessions__id');

  $$PracticeSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$PracticeSessionsTableTableManager(
      $_db,
      $_db.practiceSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MistakesTableFilterComposer
    extends Composer<_$AppDatabase, $MistakesTable> {
  $$MistakesTableFilterComposer({
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

  ColumnFilters<String> get originalSentence => $composableBuilder(
    column: $table.originalSentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctedSentence => $composableBuilder(
    column: $table.correctedSentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PracticeSessionsTableFilterComposer get sessionId {
    final $$PracticeSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableFilterComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MistakesTableOrderingComposer
    extends Composer<_$AppDatabase, $MistakesTable> {
  $$MistakesTableOrderingComposer({
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

  ColumnOrderings<String> get originalSentence => $composableBuilder(
    column: $table.originalSentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctedSentence => $composableBuilder(
    column: $table.correctedSentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PracticeSessionsTableOrderingComposer get sessionId {
    final $$PracticeSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MistakesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MistakesTable> {
  $$MistakesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalSentence => $composableBuilder(
    column: $table.originalSentence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correctedSentence => $composableBuilder(
    column: $table.correctedSentence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PracticeSessionsTableAnnotationComposer get sessionId {
    final $$PracticeSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MistakesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MistakesTable,
          Mistake,
          $$MistakesTableFilterComposer,
          $$MistakesTableOrderingComposer,
          $$MistakesTableAnnotationComposer,
          $$MistakesTableCreateCompanionBuilder,
          $$MistakesTableUpdateCompanionBuilder,
          (Mistake, $$MistakesTableReferences),
          Mistake,
          PrefetchHooks Function({bool sessionId})
        > {
  $$MistakesTableTableManager(_$AppDatabase db, $MistakesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MistakesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MistakesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MistakesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> originalSentence = const Value.absent(),
                Value<String> correctedSentence = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MistakesCompanion(
                id: id,
                sessionId: sessionId,
                originalSentence: originalSentence,
                correctedSentence: correctedSentence,
                explanation: explanation,
                category: category,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String originalSentence,
                required String correctedSentence,
                required String explanation,
                required String category,
                required DateTime createdAt,
              }) => MistakesCompanion.insert(
                id: id,
                sessionId: sessionId,
                originalSentence: originalSentence,
                correctedSentence: correctedSentence,
                explanation: explanation,
                category: category,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MistakesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$MistakesTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$MistakesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MistakesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MistakesTable,
      Mistake,
      $$MistakesTableFilterComposer,
      $$MistakesTableOrderingComposer,
      $$MistakesTableAnnotationComposer,
      $$MistakesTableCreateCompanionBuilder,
      $$MistakesTableUpdateCompanionBuilder,
      (Mistake, $$MistakesTableReferences),
      Mistake,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$VocabItemsTableCreateCompanionBuilder =
    VocabItemsCompanion Function({
      Value<int> id,
      Value<int?> sessionId,
      required String word,
      required String meaningId,
      required String exampleSentence,
      required String cefrLevel,
      Value<int> masteryCount,
      required DateTime createdAt,
    });
typedef $$VocabItemsTableUpdateCompanionBuilder =
    VocabItemsCompanion Function({
      Value<int> id,
      Value<int?> sessionId,
      Value<String> word,
      Value<String> meaningId,
      Value<String> exampleSentence,
      Value<String> cefrLevel,
      Value<int> masteryCount,
      Value<DateTime> createdAt,
    });

final class $$VocabItemsTableReferences
    extends BaseReferences<_$AppDatabase, $VocabItemsTable, VocabItem> {
  $$VocabItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PracticeSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .practiceSessions
      .createAlias('vocab_items__session_id__practice_sessions__id');

  $$PracticeSessionsTableProcessedTableManager? get sessionId {
    final $_column = $_itemColumn<int>('session_id');
    if ($_column == null) return null;
    final manager = $$PracticeSessionsTableTableManager(
      $_db,
      $_db.practiceSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VocabItemsTableFilterComposer
    extends Composer<_$AppDatabase, $VocabItemsTable> {
  $$VocabItemsTableFilterComposer({
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

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaningId => $composableBuilder(
    column: $table.meaningId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cefrLevel => $composableBuilder(
    column: $table.cefrLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get masteryCount => $composableBuilder(
    column: $table.masteryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PracticeSessionsTableFilterComposer get sessionId {
    final $$PracticeSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableFilterComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VocabItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabItemsTable> {
  $$VocabItemsTableOrderingComposer({
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

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaningId => $composableBuilder(
    column: $table.meaningId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cefrLevel => $composableBuilder(
    column: $table.cefrLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get masteryCount => $composableBuilder(
    column: $table.masteryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PracticeSessionsTableOrderingComposer get sessionId {
    final $$PracticeSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VocabItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabItemsTable> {
  $$VocabItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get meaningId =>
      $composableBuilder(column: $table.meaningId, builder: (column) => column);

  GeneratedColumn<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cefrLevel =>
      $composableBuilder(column: $table.cefrLevel, builder: (column) => column);

  GeneratedColumn<int> get masteryCount => $composableBuilder(
    column: $table.masteryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PracticeSessionsTableAnnotationComposer get sessionId {
    final $$PracticeSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VocabItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VocabItemsTable,
          VocabItem,
          $$VocabItemsTableFilterComposer,
          $$VocabItemsTableOrderingComposer,
          $$VocabItemsTableAnnotationComposer,
          $$VocabItemsTableCreateCompanionBuilder,
          $$VocabItemsTableUpdateCompanionBuilder,
          (VocabItem, $$VocabItemsTableReferences),
          VocabItem,
          PrefetchHooks Function({bool sessionId})
        > {
  $$VocabItemsTableTableManager(_$AppDatabase db, $VocabItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> meaningId = const Value.absent(),
                Value<String> exampleSentence = const Value.absent(),
                Value<String> cefrLevel = const Value.absent(),
                Value<int> masteryCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => VocabItemsCompanion(
                id: id,
                sessionId: sessionId,
                word: word,
                meaningId: meaningId,
                exampleSentence: exampleSentence,
                cefrLevel: cefrLevel,
                masteryCount: masteryCount,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
                required String word,
                required String meaningId,
                required String exampleSentence,
                required String cefrLevel,
                Value<int> masteryCount = const Value.absent(),
                required DateTime createdAt,
              }) => VocabItemsCompanion.insert(
                id: id,
                sessionId: sessionId,
                word: word,
                meaningId: meaningId,
                exampleSentence: exampleSentence,
                cefrLevel: cefrLevel,
                masteryCount: masteryCount,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VocabItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$VocabItemsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$VocabItemsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VocabItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VocabItemsTable,
      VocabItem,
      $$VocabItemsTableFilterComposer,
      $$VocabItemsTableOrderingComposer,
      $$VocabItemsTableAnnotationComposer,
      $$VocabItemsTableCreateCompanionBuilder,
      $$VocabItemsTableUpdateCompanionBuilder,
      (VocabItem, $$VocabItemsTableReferences),
      VocabItem,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> apiKey,
      Value<String> liveModel,
      Value<String> scoringModel,
      Value<String> flashcardModel,
      Value<String> flashcardTtsModel,
      Value<bool> bilingualBeginnerSupport,
      Value<bool> darkMode,
      Value<bool> unlockAllOverride,
      Value<int> currentStreak,
      Value<DateTime?> lastPracticeDate,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> apiKey,
      Value<String> liveModel,
      Value<String> scoringModel,
      Value<String> flashcardModel,
      Value<String> flashcardTtsModel,
      Value<bool> bilingualBeginnerSupport,
      Value<bool> darkMode,
      Value<bool> unlockAllOverride,
      Value<int> currentStreak,
      Value<DateTime?> lastPracticeDate,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get liveModel => $composableBuilder(
    column: $table.liveModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoringModel => $composableBuilder(
    column: $table.scoringModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flashcardModel => $composableBuilder(
    column: $table.flashcardModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flashcardTtsModel => $composableBuilder(
    column: $table.flashcardTtsModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bilingualBeginnerSupport => $composableBuilder(
    column: $table.bilingualBeginnerSupport,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get darkMode => $composableBuilder(
    column: $table.darkMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get unlockAllOverride => $composableBuilder(
    column: $table.unlockAllOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPracticeDate => $composableBuilder(
    column: $table.lastPracticeDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get liveModel => $composableBuilder(
    column: $table.liveModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoringModel => $composableBuilder(
    column: $table.scoringModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flashcardModel => $composableBuilder(
    column: $table.flashcardModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flashcardTtsModel => $composableBuilder(
    column: $table.flashcardTtsModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bilingualBeginnerSupport => $composableBuilder(
    column: $table.bilingualBeginnerSupport,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get darkMode => $composableBuilder(
    column: $table.darkMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get unlockAllOverride => $composableBuilder(
    column: $table.unlockAllOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPracticeDate => $composableBuilder(
    column: $table.lastPracticeDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get liveModel =>
      $composableBuilder(column: $table.liveModel, builder: (column) => column);

  GeneratedColumn<String> get scoringModel => $composableBuilder(
    column: $table.scoringModel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get flashcardModel => $composableBuilder(
    column: $table.flashcardModel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get flashcardTtsModel => $composableBuilder(
    column: $table.flashcardTtsModel,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bilingualBeginnerSupport => $composableBuilder(
    column: $table.bilingualBeginnerSupport,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get darkMode =>
      $composableBuilder(column: $table.darkMode, builder: (column) => column);

  GeneratedColumn<bool> get unlockAllOverride => $composableBuilder(
    column: $table.unlockAllOverride,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPracticeDate => $composableBuilder(
    column: $table.lastPracticeDate,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> apiKey = const Value.absent(),
                Value<String> liveModel = const Value.absent(),
                Value<String> scoringModel = const Value.absent(),
                Value<String> flashcardModel = const Value.absent(),
                Value<String> flashcardTtsModel = const Value.absent(),
                Value<bool> bilingualBeginnerSupport = const Value.absent(),
                Value<bool> darkMode = const Value.absent(),
                Value<bool> unlockAllOverride = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<DateTime?> lastPracticeDate = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                apiKey: apiKey,
                liveModel: liveModel,
                scoringModel: scoringModel,
                flashcardModel: flashcardModel,
                flashcardTtsModel: flashcardTtsModel,
                bilingualBeginnerSupport: bilingualBeginnerSupport,
                darkMode: darkMode,
                unlockAllOverride: unlockAllOverride,
                currentStreak: currentStreak,
                lastPracticeDate: lastPracticeDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> apiKey = const Value.absent(),
                Value<String> liveModel = const Value.absent(),
                Value<String> scoringModel = const Value.absent(),
                Value<String> flashcardModel = const Value.absent(),
                Value<String> flashcardTtsModel = const Value.absent(),
                Value<bool> bilingualBeginnerSupport = const Value.absent(),
                Value<bool> darkMode = const Value.absent(),
                Value<bool> unlockAllOverride = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<DateTime?> lastPracticeDate = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                apiKey: apiKey,
                liveModel: liveModel,
                scoringModel: scoringModel,
                flashcardModel: flashcardModel,
                flashcardTtsModel: flashcardTtsModel,
                bilingualBeginnerSupport: bilingualBeginnerSupport,
                darkMode: darkMode,
                unlockAllOverride: unlockAllOverride,
                currentStreak: currentStreak,
                lastPracticeDate: lastPracticeDate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$FlashcardDecksTableCreateCompanionBuilder =
    FlashcardDecksCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$FlashcardDecksTableUpdateCompanionBuilder =
    FlashcardDecksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$FlashcardDecksTableReferences
    extends BaseReferences<_$AppDatabase, $FlashcardDecksTable, FlashcardDeck> {
  $$FlashcardDecksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$FlashcardSubDecksTable, List<FlashcardSubDeck>>
  _flashcardSubDecksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.flashcardSubDecks,
        aliasName: 'flashcard_decks__id__flashcard_sub_decks__deck_id',
      );

  $$FlashcardSubDecksTableProcessedTableManager get flashcardSubDecksRefs {
    final manager = $$FlashcardSubDecksTableTableManager(
      $_db,
      $_db.flashcardSubDecks,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _flashcardSubDecksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FlashcardDecksTableFilterComposer
    extends Composer<_$AppDatabase, $FlashcardDecksTable> {
  $$FlashcardDecksTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> flashcardSubDecksRefs(
    Expression<bool> Function($$FlashcardSubDecksTableFilterComposer f) f,
  ) {
    final $$FlashcardSubDecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcardSubDecks,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardSubDecksTableFilterComposer(
            $db: $db,
            $table: $db.flashcardSubDecks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlashcardDecksTableOrderingComposer
    extends Composer<_$AppDatabase, $FlashcardDecksTable> {
  $$FlashcardDecksTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FlashcardDecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlashcardDecksTable> {
  $$FlashcardDecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> flashcardSubDecksRefs<T extends Object>(
    Expression<T> Function($$FlashcardSubDecksTableAnnotationComposer a) f,
  ) {
    final $$FlashcardSubDecksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.flashcardSubDecks,
          getReferencedColumn: (t) => t.deckId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FlashcardSubDecksTableAnnotationComposer(
                $db: $db,
                $table: $db.flashcardSubDecks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FlashcardDecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlashcardDecksTable,
          FlashcardDeck,
          $$FlashcardDecksTableFilterComposer,
          $$FlashcardDecksTableOrderingComposer,
          $$FlashcardDecksTableAnnotationComposer,
          $$FlashcardDecksTableCreateCompanionBuilder,
          $$FlashcardDecksTableUpdateCompanionBuilder,
          (FlashcardDeck, $$FlashcardDecksTableReferences),
          FlashcardDeck,
          PrefetchHooks Function({bool flashcardSubDecksRefs})
        > {
  $$FlashcardDecksTableTableManager(
    _$AppDatabase db,
    $FlashcardDecksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlashcardDecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlashcardDecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlashcardDecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FlashcardDecksCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FlashcardDecksCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FlashcardDecksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({flashcardSubDecksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (flashcardSubDecksRefs) db.flashcardSubDecks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (flashcardSubDecksRefs)
                    await $_getPrefetchedData<
                      FlashcardDeck,
                      $FlashcardDecksTable,
                      FlashcardSubDeck
                    >(
                      currentTable: table,
                      referencedTable: $$FlashcardDecksTableReferences
                          ._flashcardSubDecksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FlashcardDecksTableReferences(
                            db,
                            table,
                            p0,
                          ).flashcardSubDecksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.deckId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FlashcardDecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlashcardDecksTable,
      FlashcardDeck,
      $$FlashcardDecksTableFilterComposer,
      $$FlashcardDecksTableOrderingComposer,
      $$FlashcardDecksTableAnnotationComposer,
      $$FlashcardDecksTableCreateCompanionBuilder,
      $$FlashcardDecksTableUpdateCompanionBuilder,
      (FlashcardDeck, $$FlashcardDecksTableReferences),
      FlashcardDeck,
      PrefetchHooks Function({bool flashcardSubDecksRefs})
    >;
typedef $$FlashcardSubDecksTableCreateCompanionBuilder =
    FlashcardSubDecksCompanion Function({
      Value<int> id,
      required int deckId,
      required String name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$FlashcardSubDecksTableUpdateCompanionBuilder =
    FlashcardSubDecksCompanion Function({
      Value<int> id,
      Value<int> deckId,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$FlashcardSubDecksTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FlashcardSubDecksTable,
          FlashcardSubDeck
        > {
  $$FlashcardSubDecksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FlashcardDecksTable _deckIdTable(_$AppDatabase db) => db
      .flashcardDecks
      .createAlias('flashcard_sub_decks__deck_id__flashcard_decks__id');

  $$FlashcardDecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<int>('deck_id')!;

    final manager = $$FlashcardDecksTableTableManager(
      $_db,
      $_db.flashcardDecks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FlashcardsTable, List<Flashcard>>
  _flashcardsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.flashcards,
    aliasName: 'flashcard_sub_decks__id__flashcards__sub_deck_id',
  );

  $$FlashcardsTableProcessedTableManager get flashcardsRefs {
    final manager = $$FlashcardsTableTableManager(
      $_db,
      $_db.flashcards,
    ).filter((f) => f.subDeckId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_flashcardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FlashcardSubDecksTableFilterComposer
    extends Composer<_$AppDatabase, $FlashcardSubDecksTable> {
  $$FlashcardSubDecksTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FlashcardDecksTableFilterComposer get deckId {
    final $$FlashcardDecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.flashcardDecks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardDecksTableFilterComposer(
            $db: $db,
            $table: $db.flashcardDecks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> flashcardsRefs(
    Expression<bool> Function($$FlashcardsTableFilterComposer f) f,
  ) {
    final $$FlashcardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcards,
      getReferencedColumn: (t) => t.subDeckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardsTableFilterComposer(
            $db: $db,
            $table: $db.flashcards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlashcardSubDecksTableOrderingComposer
    extends Composer<_$AppDatabase, $FlashcardSubDecksTable> {
  $$FlashcardSubDecksTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FlashcardDecksTableOrderingComposer get deckId {
    final $$FlashcardDecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.flashcardDecks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardDecksTableOrderingComposer(
            $db: $db,
            $table: $db.flashcardDecks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlashcardSubDecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlashcardSubDecksTable> {
  $$FlashcardSubDecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FlashcardDecksTableAnnotationComposer get deckId {
    final $$FlashcardDecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.flashcardDecks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardDecksTableAnnotationComposer(
            $db: $db,
            $table: $db.flashcardDecks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> flashcardsRefs<T extends Object>(
    Expression<T> Function($$FlashcardsTableAnnotationComposer a) f,
  ) {
    final $$FlashcardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcards,
      getReferencedColumn: (t) => t.subDeckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardsTableAnnotationComposer(
            $db: $db,
            $table: $db.flashcards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FlashcardSubDecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlashcardSubDecksTable,
          FlashcardSubDeck,
          $$FlashcardSubDecksTableFilterComposer,
          $$FlashcardSubDecksTableOrderingComposer,
          $$FlashcardSubDecksTableAnnotationComposer,
          $$FlashcardSubDecksTableCreateCompanionBuilder,
          $$FlashcardSubDecksTableUpdateCompanionBuilder,
          (FlashcardSubDeck, $$FlashcardSubDecksTableReferences),
          FlashcardSubDeck,
          PrefetchHooks Function({bool deckId, bool flashcardsRefs})
        > {
  $$FlashcardSubDecksTableTableManager(
    _$AppDatabase db,
    $FlashcardSubDecksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlashcardSubDecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlashcardSubDecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlashcardSubDecksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> deckId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FlashcardSubDecksCompanion(
                id: id,
                deckId: deckId,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int deckId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FlashcardSubDecksCompanion.insert(
                id: id,
                deckId: deckId,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FlashcardSubDecksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deckId = false, flashcardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (flashcardsRefs) db.flashcards],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckId,
                                referencedTable:
                                    $$FlashcardSubDecksTableReferences
                                        ._deckIdTable(db),
                                referencedColumn:
                                    $$FlashcardSubDecksTableReferences
                                        ._deckIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (flashcardsRefs)
                    await $_getPrefetchedData<
                      FlashcardSubDeck,
                      $FlashcardSubDecksTable,
                      Flashcard
                    >(
                      currentTable: table,
                      referencedTable: $$FlashcardSubDecksTableReferences
                          ._flashcardsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FlashcardSubDecksTableReferences(
                            db,
                            table,
                            p0,
                          ).flashcardsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.subDeckId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FlashcardSubDecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlashcardSubDecksTable,
      FlashcardSubDeck,
      $$FlashcardSubDecksTableFilterComposer,
      $$FlashcardSubDecksTableOrderingComposer,
      $$FlashcardSubDecksTableAnnotationComposer,
      $$FlashcardSubDecksTableCreateCompanionBuilder,
      $$FlashcardSubDecksTableUpdateCompanionBuilder,
      (FlashcardSubDeck, $$FlashcardSubDecksTableReferences),
      FlashcardSubDeck,
      PrefetchHooks Function({bool deckId, bool flashcardsRefs})
    >;
typedef $$FlashcardsTableCreateCompanionBuilder =
    FlashcardsCompanion Function({
      Value<int> id,
      required int subDeckId,
      required String word,
      Value<String?> phonetic,
      Value<String> meaningId,
      Value<String> wordType,
      Value<String> partsOfSpeechJson,
      Value<String> examplesJson,
      Value<String> verbTensesExamplesJson,
      Value<String> aiConversation,
      Value<int> masteryLevel,
      Value<int> studyStatus,
      Value<int> reviewCount,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime> createdAt,
    });
typedef $$FlashcardsTableUpdateCompanionBuilder =
    FlashcardsCompanion Function({
      Value<int> id,
      Value<int> subDeckId,
      Value<String> word,
      Value<String?> phonetic,
      Value<String> meaningId,
      Value<String> wordType,
      Value<String> partsOfSpeechJson,
      Value<String> examplesJson,
      Value<String> verbTensesExamplesJson,
      Value<String> aiConversation,
      Value<int> masteryLevel,
      Value<int> studyStatus,
      Value<int> reviewCount,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime> createdAt,
    });

final class $$FlashcardsTableReferences
    extends BaseReferences<_$AppDatabase, $FlashcardsTable, Flashcard> {
  $$FlashcardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FlashcardSubDecksTable _subDeckIdTable(_$AppDatabase db) => db
      .flashcardSubDecks
      .createAlias('flashcards__sub_deck_id__flashcard_sub_decks__id');

  $$FlashcardSubDecksTableProcessedTableManager get subDeckId {
    final $_column = $_itemColumn<int>('sub_deck_id')!;

    final manager = $$FlashcardSubDecksTableTableManager(
      $_db,
      $_db.flashcardSubDecks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subDeckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FlashcardsTableFilterComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableFilterComposer({
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

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phonetic => $composableBuilder(
    column: $table.phonetic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaningId => $composableBuilder(
    column: $table.meaningId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordType => $composableBuilder(
    column: $table.wordType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partsOfSpeechJson => $composableBuilder(
    column: $table.partsOfSpeechJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get examplesJson => $composableBuilder(
    column: $table.examplesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verbTensesExamplesJson => $composableBuilder(
    column: $table.verbTensesExamplesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiConversation => $composableBuilder(
    column: $table.aiConversation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get masteryLevel => $composableBuilder(
    column: $table.masteryLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get studyStatus => $composableBuilder(
    column: $table.studyStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FlashcardSubDecksTableFilterComposer get subDeckId {
    final $$FlashcardSubDecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subDeckId,
      referencedTable: $db.flashcardSubDecks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardSubDecksTableFilterComposer(
            $db: $db,
            $table: $db.flashcardSubDecks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlashcardsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableOrderingComposer({
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

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phonetic => $composableBuilder(
    column: $table.phonetic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaningId => $composableBuilder(
    column: $table.meaningId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordType => $composableBuilder(
    column: $table.wordType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partsOfSpeechJson => $composableBuilder(
    column: $table.partsOfSpeechJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examplesJson => $composableBuilder(
    column: $table.examplesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verbTensesExamplesJson => $composableBuilder(
    column: $table.verbTensesExamplesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiConversation => $composableBuilder(
    column: $table.aiConversation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get masteryLevel => $composableBuilder(
    column: $table.masteryLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get studyStatus => $composableBuilder(
    column: $table.studyStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FlashcardSubDecksTableOrderingComposer get subDeckId {
    final $$FlashcardSubDecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subDeckId,
      referencedTable: $db.flashcardSubDecks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardSubDecksTableOrderingComposer(
            $db: $db,
            $table: $db.flashcardSubDecks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlashcardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get phonetic =>
      $composableBuilder(column: $table.phonetic, builder: (column) => column);

  GeneratedColumn<String> get meaningId =>
      $composableBuilder(column: $table.meaningId, builder: (column) => column);

  GeneratedColumn<String> get wordType =>
      $composableBuilder(column: $table.wordType, builder: (column) => column);

  GeneratedColumn<String> get partsOfSpeechJson => $composableBuilder(
    column: $table.partsOfSpeechJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get examplesJson => $composableBuilder(
    column: $table.examplesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verbTensesExamplesJson => $composableBuilder(
    column: $table.verbTensesExamplesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiConversation => $composableBuilder(
    column: $table.aiConversation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get masteryLevel => $composableBuilder(
    column: $table.masteryLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get studyStatus => $composableBuilder(
    column: $table.studyStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FlashcardSubDecksTableAnnotationComposer get subDeckId {
    final $$FlashcardSubDecksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.subDeckId,
          referencedTable: $db.flashcardSubDecks,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FlashcardSubDecksTableAnnotationComposer(
                $db: $db,
                $table: $db.flashcardSubDecks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$FlashcardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlashcardsTable,
          Flashcard,
          $$FlashcardsTableFilterComposer,
          $$FlashcardsTableOrderingComposer,
          $$FlashcardsTableAnnotationComposer,
          $$FlashcardsTableCreateCompanionBuilder,
          $$FlashcardsTableUpdateCompanionBuilder,
          (Flashcard, $$FlashcardsTableReferences),
          Flashcard,
          PrefetchHooks Function({bool subDeckId})
        > {
  $$FlashcardsTableTableManager(_$AppDatabase db, $FlashcardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlashcardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlashcardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlashcardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> subDeckId = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String?> phonetic = const Value.absent(),
                Value<String> meaningId = const Value.absent(),
                Value<String> wordType = const Value.absent(),
                Value<String> partsOfSpeechJson = const Value.absent(),
                Value<String> examplesJson = const Value.absent(),
                Value<String> verbTensesExamplesJson = const Value.absent(),
                Value<String> aiConversation = const Value.absent(),
                Value<int> masteryLevel = const Value.absent(),
                Value<int> studyStatus = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FlashcardsCompanion(
                id: id,
                subDeckId: subDeckId,
                word: word,
                phonetic: phonetic,
                meaningId: meaningId,
                wordType: wordType,
                partsOfSpeechJson: partsOfSpeechJson,
                examplesJson: examplesJson,
                verbTensesExamplesJson: verbTensesExamplesJson,
                aiConversation: aiConversation,
                masteryLevel: masteryLevel,
                studyStatus: studyStatus,
                reviewCount: reviewCount,
                lastReviewedAt: lastReviewedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int subDeckId,
                required String word,
                Value<String?> phonetic = const Value.absent(),
                Value<String> meaningId = const Value.absent(),
                Value<String> wordType = const Value.absent(),
                Value<String> partsOfSpeechJson = const Value.absent(),
                Value<String> examplesJson = const Value.absent(),
                Value<String> verbTensesExamplesJson = const Value.absent(),
                Value<String> aiConversation = const Value.absent(),
                Value<int> masteryLevel = const Value.absent(),
                Value<int> studyStatus = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FlashcardsCompanion.insert(
                id: id,
                subDeckId: subDeckId,
                word: word,
                phonetic: phonetic,
                meaningId: meaningId,
                wordType: wordType,
                partsOfSpeechJson: partsOfSpeechJson,
                examplesJson: examplesJson,
                verbTensesExamplesJson: verbTensesExamplesJson,
                aiConversation: aiConversation,
                masteryLevel: masteryLevel,
                studyStatus: studyStatus,
                reviewCount: reviewCount,
                lastReviewedAt: lastReviewedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FlashcardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({subDeckId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (subDeckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.subDeckId,
                                referencedTable: $$FlashcardsTableReferences
                                    ._subDeckIdTable(db),
                                referencedColumn: $$FlashcardsTableReferences
                                    ._subDeckIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FlashcardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlashcardsTable,
      Flashcard,
      $$FlashcardsTableFilterComposer,
      $$FlashcardsTableOrderingComposer,
      $$FlashcardsTableAnnotationComposer,
      $$FlashcardsTableCreateCompanionBuilder,
      $$FlashcardsTableUpdateCompanionBuilder,
      (Flashcard, $$FlashcardsTableReferences),
      Flashcard,
      PrefetchHooks Function({bool subDeckId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LevelsTableTableManager get levels =>
      $$LevelsTableTableManager(_db, _db.levels);
  $$LessonsTableTableManager get lessons =>
      $$LessonsTableTableManager(_db, _db.lessons);
  $$PracticeSessionsTableTableManager get practiceSessions =>
      $$PracticeSessionsTableTableManager(_db, _db.practiceSessions);
  $$MistakesTableTableManager get mistakes =>
      $$MistakesTableTableManager(_db, _db.mistakes);
  $$VocabItemsTableTableManager get vocabItems =>
      $$VocabItemsTableTableManager(_db, _db.vocabItems);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$FlashcardDecksTableTableManager get flashcardDecks =>
      $$FlashcardDecksTableTableManager(_db, _db.flashcardDecks);
  $$FlashcardSubDecksTableTableManager get flashcardSubDecks =>
      $$FlashcardSubDecksTableTableManager(_db, _db.flashcardSubDecks);
  $$FlashcardsTableTableManager get flashcards =>
      $$FlashcardsTableTableManager(_db, _db.flashcards);
}
