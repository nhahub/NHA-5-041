// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, FavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<String> mealId = GeneratedColumn<String>(
    'meal_id',
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
  static const VerificationMeta _thumbMeta = const VerificationMeta('thumb');
  @override
  late final GeneratedColumn<String> thumb = GeneratedColumn<String>(
    'thumb',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _areaMeta = const VerificationMeta('area');
  @override
  late final GeneratedColumn<String> area = GeneratedColumn<String>(
    'area',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _youtubeMeta = const VerificationMeta(
    'youtube',
  );
  @override
  late final GeneratedColumn<String> youtube = GeneratedColumn<String>(
    'youtube',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ingredientsJsonMeta = const VerificationMeta(
    'ingredientsJson',
  );
  @override
  late final GeneratedColumn<String> ingredientsJson = GeneratedColumn<String>(
    'ingredients_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    mealId,
    name,
    thumb,
    category,
    area,
    instructions,
    youtube,
    ingredientsJson,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('thumb')) {
      context.handle(
        _thumbMeta,
        thumb.isAcceptableOrUnknown(data['thumb']!, _thumbMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('area')) {
      context.handle(
        _areaMeta,
        area.isAcceptableOrUnknown(data['area']!, _areaMeta),
      );
    }
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('youtube')) {
      context.handle(
        _youtubeMeta,
        youtube.isAcceptableOrUnknown(data['youtube']!, _youtubeMeta),
      );
    }
    if (data.containsKey('ingredients_json')) {
      context.handle(
        _ingredientsJsonMeta,
        ingredientsJson.isAcceptableOrUnknown(
          data['ingredients_json']!,
          _ingredientsJsonMeta,
        ),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, mealId};
  @override
  FavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      thumb: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      area: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area'],
      )!,
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      )!,
      youtube: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}youtube'],
      )!,
      ingredientsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredients_json'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class FavoriteRow extends DataClass implements Insertable<FavoriteRow> {
  final String userId;
  final String mealId;
  final String name;
  final String thumb;
  final String category;
  final String area;
  final String instructions;
  final String youtube;
  final String ingredientsJson;
  final DateTime addedAt;
  const FavoriteRow({
    required this.userId,
    required this.mealId,
    required this.name,
    required this.thumb,
    required this.category,
    required this.area,
    required this.instructions,
    required this.youtube,
    required this.ingredientsJson,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['meal_id'] = Variable<String>(mealId);
    map['name'] = Variable<String>(name);
    map['thumb'] = Variable<String>(thumb);
    map['category'] = Variable<String>(category);
    map['area'] = Variable<String>(area);
    map['instructions'] = Variable<String>(instructions);
    map['youtube'] = Variable<String>(youtube);
    map['ingredients_json'] = Variable<String>(ingredientsJson);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      userId: Value(userId),
      mealId: Value(mealId),
      name: Value(name),
      thumb: Value(thumb),
      category: Value(category),
      area: Value(area),
      instructions: Value(instructions),
      youtube: Value(youtube),
      ingredientsJson: Value(ingredientsJson),
      addedAt: Value(addedAt),
    );
  }

  factory FavoriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteRow(
      userId: serializer.fromJson<String>(json['userId']),
      mealId: serializer.fromJson<String>(json['mealId']),
      name: serializer.fromJson<String>(json['name']),
      thumb: serializer.fromJson<String>(json['thumb']),
      category: serializer.fromJson<String>(json['category']),
      area: serializer.fromJson<String>(json['area']),
      instructions: serializer.fromJson<String>(json['instructions']),
      youtube: serializer.fromJson<String>(json['youtube']),
      ingredientsJson: serializer.fromJson<String>(json['ingredientsJson']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'mealId': serializer.toJson<String>(mealId),
      'name': serializer.toJson<String>(name),
      'thumb': serializer.toJson<String>(thumb),
      'category': serializer.toJson<String>(category),
      'area': serializer.toJson<String>(area),
      'instructions': serializer.toJson<String>(instructions),
      'youtube': serializer.toJson<String>(youtube),
      'ingredientsJson': serializer.toJson<String>(ingredientsJson),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  FavoriteRow copyWith({
    String? userId,
    String? mealId,
    String? name,
    String? thumb,
    String? category,
    String? area,
    String? instructions,
    String? youtube,
    String? ingredientsJson,
    DateTime? addedAt,
  }) => FavoriteRow(
    userId: userId ?? this.userId,
    mealId: mealId ?? this.mealId,
    name: name ?? this.name,
    thumb: thumb ?? this.thumb,
    category: category ?? this.category,
    area: area ?? this.area,
    instructions: instructions ?? this.instructions,
    youtube: youtube ?? this.youtube,
    ingredientsJson: ingredientsJson ?? this.ingredientsJson,
    addedAt: addedAt ?? this.addedAt,
  );
  FavoriteRow copyWithCompanion(FavoritesCompanion data) {
    return FavoriteRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      name: data.name.present ? data.name.value : this.name,
      thumb: data.thumb.present ? data.thumb.value : this.thumb,
      category: data.category.present ? data.category.value : this.category,
      area: data.area.present ? data.area.value : this.area,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      youtube: data.youtube.present ? data.youtube.value : this.youtube,
      ingredientsJson: data.ingredientsJson.present
          ? data.ingredientsJson.value
          : this.ingredientsJson,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteRow(')
          ..write('userId: $userId, ')
          ..write('mealId: $mealId, ')
          ..write('name: $name, ')
          ..write('thumb: $thumb, ')
          ..write('category: $category, ')
          ..write('area: $area, ')
          ..write('instructions: $instructions, ')
          ..write('youtube: $youtube, ')
          ..write('ingredientsJson: $ingredientsJson, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    mealId,
    name,
    thumb,
    category,
    area,
    instructions,
    youtube,
    ingredientsJson,
    addedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteRow &&
          other.userId == this.userId &&
          other.mealId == this.mealId &&
          other.name == this.name &&
          other.thumb == this.thumb &&
          other.category == this.category &&
          other.area == this.area &&
          other.instructions == this.instructions &&
          other.youtube == this.youtube &&
          other.ingredientsJson == this.ingredientsJson &&
          other.addedAt == this.addedAt);
}

class FavoritesCompanion extends UpdateCompanion<FavoriteRow> {
  final Value<String> userId;
  final Value<String> mealId;
  final Value<String> name;
  final Value<String> thumb;
  final Value<String> category;
  final Value<String> area;
  final Value<String> instructions;
  final Value<String> youtube;
  final Value<String> ingredientsJson;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.userId = const Value.absent(),
    this.mealId = const Value.absent(),
    this.name = const Value.absent(),
    this.thumb = const Value.absent(),
    this.category = const Value.absent(),
    this.area = const Value.absent(),
    this.instructions = const Value.absent(),
    this.youtube = const Value.absent(),
    this.ingredientsJson = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required String userId,
    required String mealId,
    required String name,
    this.thumb = const Value.absent(),
    this.category = const Value.absent(),
    this.area = const Value.absent(),
    this.instructions = const Value.absent(),
    this.youtube = const Value.absent(),
    this.ingredientsJson = const Value.absent(),
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       mealId = Value(mealId),
       name = Value(name),
       addedAt = Value(addedAt);
  static Insertable<FavoriteRow> custom({
    Expression<String>? userId,
    Expression<String>? mealId,
    Expression<String>? name,
    Expression<String>? thumb,
    Expression<String>? category,
    Expression<String>? area,
    Expression<String>? instructions,
    Expression<String>? youtube,
    Expression<String>? ingredientsJson,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (mealId != null) 'meal_id': mealId,
      if (name != null) 'name': name,
      if (thumb != null) 'thumb': thumb,
      if (category != null) 'category': category,
      if (area != null) 'area': area,
      if (instructions != null) 'instructions': instructions,
      if (youtube != null) 'youtube': youtube,
      if (ingredientsJson != null) 'ingredients_json': ingredientsJson,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({
    Value<String>? userId,
    Value<String>? mealId,
    Value<String>? name,
    Value<String>? thumb,
    Value<String>? category,
    Value<String>? area,
    Value<String>? instructions,
    Value<String>? youtube,
    Value<String>? ingredientsJson,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return FavoritesCompanion(
      userId: userId ?? this.userId,
      mealId: mealId ?? this.mealId,
      name: name ?? this.name,
      thumb: thumb ?? this.thumb,
      category: category ?? this.category,
      area: area ?? this.area,
      instructions: instructions ?? this.instructions,
      youtube: youtube ?? this.youtube,
      ingredientsJson: ingredientsJson ?? this.ingredientsJson,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<String>(mealId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (thumb.present) {
      map['thumb'] = Variable<String>(thumb.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (area.present) {
      map['area'] = Variable<String>(area.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (youtube.present) {
      map['youtube'] = Variable<String>(youtube.value);
    }
    if (ingredientsJson.present) {
      map['ingredients_json'] = Variable<String>(ingredientsJson.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('userId: $userId, ')
          ..write('mealId: $mealId, ')
          ..write('name: $name, ')
          ..write('thumb: $thumb, ')
          ..write('category: $category, ')
          ..write('area: $area, ')
          ..write('instructions: $instructions, ')
          ..write('youtube: $youtube, ')
          ..write('ingredientsJson: $ingredientsJson, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlannedMealsTable extends PlannedMeals
    with TableInfo<$PlannedMealsTable, PlannedRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedMealsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<String> mealId = GeneratedColumn<String>(
    'meal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotMeta = const VerificationMeta(
    'snapshot',
  );
  @override
  late final GeneratedColumn<String> snapshot = GeneratedColumn<String>(
    'snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderAtMeta = const VerificationMeta(
    'reminderAt',
  );
  @override
  late final GeneratedColumn<DateTime> reminderAt = GeneratedColumn<DateTime>(
    'reminder_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mealId,
    day,
    snapshot,
    reminderAt,
    userId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_meals';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('meal_id')) {
      context.handle(
        _mealIdMeta,
        mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('snapshot')) {
      context.handle(
        _snapshotMeta,
        snapshot.isAcceptableOrUnknown(data['snapshot']!, _snapshotMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotMeta);
    }
    if (data.containsKey('reminder_at')) {
      context.handle(
        _reminderAtMeta,
        reminderAt.isAcceptableOrUnknown(data['reminder_at']!, _reminderAtMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, mealId, day},
  ];
  @override
  PlannedRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mealId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      snapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot'],
      )!,
      reminderAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reminder_at'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
    );
  }

  @override
  $PlannedMealsTable createAlias(String alias) {
    return $PlannedMealsTable(attachedDatabase, alias);
  }
}

class PlannedRow extends DataClass implements Insertable<PlannedRow> {
  final int id;
  final String mealId;
  final String day;
  final String snapshot;
  final DateTime? reminderAt;
  final String userId;
  const PlannedRow({
    required this.id,
    required this.mealId,
    required this.day,
    required this.snapshot,
    this.reminderAt,
    required this.userId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['meal_id'] = Variable<String>(mealId);
    map['day'] = Variable<String>(day);
    map['snapshot'] = Variable<String>(snapshot);
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<DateTime>(reminderAt);
    }
    map['user_id'] = Variable<String>(userId);
    return map;
  }

  PlannedMealsCompanion toCompanion(bool nullToAbsent) {
    return PlannedMealsCompanion(
      id: Value(id),
      mealId: Value(mealId),
      day: Value(day),
      snapshot: Value(snapshot),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      userId: Value(userId),
    );
  }

  factory PlannedRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedRow(
      id: serializer.fromJson<int>(json['id']),
      mealId: serializer.fromJson<String>(json['mealId']),
      day: serializer.fromJson<String>(json['day']),
      snapshot: serializer.fromJson<String>(json['snapshot']),
      reminderAt: serializer.fromJson<DateTime?>(json['reminderAt']),
      userId: serializer.fromJson<String>(json['userId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mealId': serializer.toJson<String>(mealId),
      'day': serializer.toJson<String>(day),
      'snapshot': serializer.toJson<String>(snapshot),
      'reminderAt': serializer.toJson<DateTime?>(reminderAt),
      'userId': serializer.toJson<String>(userId),
    };
  }

  PlannedRow copyWith({
    int? id,
    String? mealId,
    String? day,
    String? snapshot,
    Value<DateTime?> reminderAt = const Value.absent(),
    String? userId,
  }) => PlannedRow(
    id: id ?? this.id,
    mealId: mealId ?? this.mealId,
    day: day ?? this.day,
    snapshot: snapshot ?? this.snapshot,
    reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
    userId: userId ?? this.userId,
  );
  PlannedRow copyWithCompanion(PlannedMealsCompanion data) {
    return PlannedRow(
      id: data.id.present ? data.id.value : this.id,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      day: data.day.present ? data.day.value : this.day,
      snapshot: data.snapshot.present ? data.snapshot.value : this.snapshot,
      reminderAt: data.reminderAt.present
          ? data.reminderAt.value
          : this.reminderAt,
      userId: data.userId.present ? data.userId.value : this.userId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedRow(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('day: $day, ')
          ..write('snapshot: $snapshot, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, mealId, day, snapshot, reminderAt, userId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedRow &&
          other.id == this.id &&
          other.mealId == this.mealId &&
          other.day == this.day &&
          other.snapshot == this.snapshot &&
          other.reminderAt == this.reminderAt &&
          other.userId == this.userId);
}

class PlannedMealsCompanion extends UpdateCompanion<PlannedRow> {
  final Value<int> id;
  final Value<String> mealId;
  final Value<String> day;
  final Value<String> snapshot;
  final Value<DateTime?> reminderAt;
  final Value<String> userId;
  const PlannedMealsCompanion({
    this.id = const Value.absent(),
    this.mealId = const Value.absent(),
    this.day = const Value.absent(),
    this.snapshot = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.userId = const Value.absent(),
  });
  PlannedMealsCompanion.insert({
    this.id = const Value.absent(),
    required String mealId,
    required String day,
    required String snapshot,
    this.reminderAt = const Value.absent(),
    required String userId,
  }) : mealId = Value(mealId),
       day = Value(day),
       snapshot = Value(snapshot),
       userId = Value(userId);
  static Insertable<PlannedRow> custom({
    Expression<int>? id,
    Expression<String>? mealId,
    Expression<String>? day,
    Expression<String>? snapshot,
    Expression<DateTime>? reminderAt,
    Expression<String>? userId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealId != null) 'meal_id': mealId,
      if (day != null) 'day': day,
      if (snapshot != null) 'snapshot': snapshot,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (userId != null) 'user_id': userId,
    });
  }

  PlannedMealsCompanion copyWith({
    Value<int>? id,
    Value<String>? mealId,
    Value<String>? day,
    Value<String>? snapshot,
    Value<DateTime?>? reminderAt,
    Value<String>? userId,
  }) {
    return PlannedMealsCompanion(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      day: day ?? this.day,
      snapshot: snapshot ?? this.snapshot,
      reminderAt: reminderAt ?? this.reminderAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<String>(mealId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (snapshot.present) {
      map['snapshot'] = Variable<String>(snapshot.value);
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<DateTime>(reminderAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedMealsCompanion(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('day: $day, ')
          ..write('snapshot: $snapshot, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $PlannedMealsTable plannedMeals = $PlannedMealsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [favorites, plannedMeals];
}

typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  required String userId,
  required String mealId,
  required String name,
  Value<String> thumb,
  Value<String> category,
  Value<String> area,
  Value<String> instructions,
  Value<String> youtube,
  Value<String> ingredientsJson,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<String> userId,
  Value<String> mealId,
  Value<String> name,
  Value<String> thumb,
  Value<String> category,
  Value<String> area,
  Value<String> instructions,
  Value<String> youtube,
  Value<String> ingredientsJson,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumb => $composableBuilder(
    column: $table.thumb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get youtube => $composableBuilder(
    column: $table.youtube,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredientsJson => $composableBuilder(
    column: $table.ingredientsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumb => $composableBuilder(
    column: $table.thumb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get youtube => $composableBuilder(
    column: $table.youtube,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredientsJson => $composableBuilder(
    column: $table.ingredientsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get thumb =>
      $composableBuilder(column: $table.thumb, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get area =>
      $composableBuilder(column: $table.area, builder: (column) => column);

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get youtube =>
      $composableBuilder(column: $table.youtube, builder: (column) => column);

  GeneratedColumn<String> get ingredientsJson => $composableBuilder(
    column: $table.ingredientsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          FavoriteRow,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (
            FavoriteRow,
            BaseReferences<_$AppDatabase, $FavoritesTable, FavoriteRow>,
          ),
          FavoriteRow,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> mealId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> thumb = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> area = const Value.absent(),
                Value<String> instructions = const Value.absent(),
                Value<String> youtube = const Value.absent(),
                Value<String> ingredientsJson = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion(
                userId: userId,
                mealId: mealId,
                name: name,
                thumb: thumb,
                category: category,
                area: area,
                instructions: instructions,
                youtube: youtube,
                ingredientsJson: ingredientsJson,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String mealId,
                required String name,
                Value<String> thumb = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> area = const Value.absent(),
                Value<String> instructions = const Value.absent(),
                Value<String> youtube = const Value.absent(),
                Value<String> ingredientsJson = const Value.absent(),
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion.insert(
                userId: userId,
                mealId: mealId,
                name: name,
                thumb: thumb,
                category: category,
                area: area,
                instructions: instructions,
                youtube: youtube,
                ingredientsJson: ingredientsJson,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, FavoriteRow>(table),
                  BaseReferences<_$AppDatabase, $FavoritesTable, FavoriteRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      FavoriteRow,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (
        FavoriteRow,
        BaseReferences<_$AppDatabase, $FavoritesTable, FavoriteRow>,
      ),
      FavoriteRow,
      PrefetchHooks Function()
    >;
typedef $$PlannedMealsTableCreateCompanionBuilder =
    PlannedMealsCompanion Function({
      Value<int> id,
      required String mealId,
      required String day,
      required String snapshot,
      Value<DateTime?> reminderAt,
      required String userId,
    });
typedef $$PlannedMealsTableUpdateCompanionBuilder =
    PlannedMealsCompanion Function({
      Value<int> id,
      Value<String> mealId,
      Value<String> day,
      Value<String> snapshot,
      Value<DateTime?> reminderAt,
      Value<String> userId,
    });

class $$PlannedMealsTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedMealsTable> {
  $$PlannedMealsTableFilterComposer({
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

  ColumnFilters<String> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannedMealsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedMealsTable> {
  $$PlannedMealsTableOrderingComposer({
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

  ColumnOrderings<String> get mealId => $composableBuilder(
    column: $table.mealId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannedMealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedMealsTable> {
  $$PlannedMealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get snapshot =>
      $composableBuilder(column: $table.snapshot, builder: (column) => column);

  GeneratedColumn<DateTime> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);
}

class $$PlannedMealsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannedMealsTable,
          PlannedRow,
          $$PlannedMealsTableFilterComposer,
          $$PlannedMealsTableOrderingComposer,
          $$PlannedMealsTableAnnotationComposer,
          $$PlannedMealsTableCreateCompanionBuilder,
          $$PlannedMealsTableUpdateCompanionBuilder,
          (
            PlannedRow,
            BaseReferences<_$AppDatabase, $PlannedMealsTable, PlannedRow>,
          ),
          PlannedRow,
          PrefetchHooks Function()
        > {
  $$PlannedMealsTableTableManager(_$AppDatabase db, $PlannedMealsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedMealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedMealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedMealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> mealId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> snapshot = const Value.absent(),
                Value<DateTime?> reminderAt = const Value.absent(),
                Value<String> userId = const Value.absent(),
              }) => PlannedMealsCompanion(
                id: id,
                mealId: mealId,
                day: day,
                snapshot: snapshot,
                reminderAt: reminderAt,
                userId: userId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String mealId,
                required String day,
                required String snapshot,
                Value<DateTime?> reminderAt = const Value.absent(),
                required String userId,
              }) => PlannedMealsCompanion.insert(
                id: id,
                mealId: mealId,
                day: day,
                snapshot: snapshot,
                reminderAt: reminderAt,
                userId: userId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlannedMealsTable, PlannedRow>(table),
                  BaseReferences<_$AppDatabase, $PlannedMealsTable, PlannedRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannedMealsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannedMealsTable,
      PlannedRow,
      $$PlannedMealsTableFilterComposer,
      $$PlannedMealsTableOrderingComposer,
      $$PlannedMealsTableAnnotationComposer,
      $$PlannedMealsTableCreateCompanionBuilder,
      $$PlannedMealsTableUpdateCompanionBuilder,
      (
        PlannedRow,
        BaseReferences<_$AppDatabase, $PlannedMealsTable, PlannedRow>,
      ),
      PlannedRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$PlannedMealsTableTableManager get plannedMeals =>
      $$PlannedMealsTableTableManager(_db, _db.plannedMeals);
}
