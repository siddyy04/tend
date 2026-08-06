// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion_log_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSuggestionLogEntryCollection on Isar {
  IsarCollection<SuggestionLogEntry> get suggestionLogEntrys =>
      this.collection();
}

const SuggestionLogEntrySchema = CollectionSchema(
  name: r'SuggestionLogEntry',
  id: -8311812183191200727,
  properties: {
    r'actionTaken': PropertySchema(
      id: 0,
      name: r'actionTaken',
      type: IsarType.string,
    ),
    r'followUpUuid': PropertySchema(
      id: 1,
      name: r'followUpUuid',
      type: IsarType.string,
    ),
    r'reasonShown': PropertySchema(
      id: 2,
      name: r'reasonShown',
      type: IsarType.string,
    ),
    r'surfacedAt': PropertySchema(
      id: 3,
      name: r'surfacedAt',
      type: IsarType.dateTime,
    ),
    r'syncStatus': PropertySchema(
      id: 4,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _SuggestionLogEntrysyncStatusEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userFeedback': PropertySchema(
      id: 6,
      name: r'userFeedback',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(id: 7, name: r'uuid', type: IsarType.string),
  },

  estimateSize: _suggestionLogEntryEstimateSize,
  serialize: _suggestionLogEntrySerialize,
  deserialize: _suggestionLogEntryDeserialize,
  deserializeProp: _suggestionLogEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'followUpUuid': IndexSchema(
      id: 515510050952649494,
      name: r'followUpUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'followUpUuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _suggestionLogEntryGetId,
  getLinks: _suggestionLogEntryGetLinks,
  attach: _suggestionLogEntryAttach,
  version: '3.3.2',
);

int _suggestionLogEntryEstimateSize(
  SuggestionLogEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.actionTaken;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.followUpUuid.length * 3;
  {
    final value = object.reasonShown;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.userFeedback;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _suggestionLogEntrySerialize(
  SuggestionLogEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.actionTaken);
  writer.writeString(offsets[1], object.followUpUuid);
  writer.writeString(offsets[2], object.reasonShown);
  writer.writeDateTime(offsets[3], object.surfacedAt);
  writer.writeByte(offsets[4], object.syncStatus.index);
  writer.writeDateTime(offsets[5], object.updatedAt);
  writer.writeString(offsets[6], object.userFeedback);
  writer.writeString(offsets[7], object.uuid);
}

SuggestionLogEntry _suggestionLogEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SuggestionLogEntry();
  object.actionTaken = reader.readStringOrNull(offsets[0]);
  object.followUpUuid = reader.readString(offsets[1]);
  object.id = id;
  object.reasonShown = reader.readStringOrNull(offsets[2]);
  object.surfacedAt = reader.readDateTime(offsets[3]);
  object.syncStatus =
      _SuggestionLogEntrysyncStatusValueEnumMap[reader.readByteOrNull(
        offsets[4],
      )] ??
      SyncStatus.pending;
  object.updatedAt = reader.readDateTime(offsets[5]);
  object.userFeedback = reader.readStringOrNull(offsets[6]);
  object.uuid = reader.readString(offsets[7]);
  return object;
}

P _suggestionLogEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (_SuggestionLogEntrysyncStatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              SyncStatus.pending)
          as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SuggestionLogEntrysyncStatusEnumValueMap = {
  'pending': 0,
  'synced': 1,
  'conflict': 2,
};
const _SuggestionLogEntrysyncStatusValueEnumMap = {
  0: SyncStatus.pending,
  1: SyncStatus.synced,
  2: SyncStatus.conflict,
};

Id _suggestionLogEntryGetId(SuggestionLogEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _suggestionLogEntryGetLinks(
  SuggestionLogEntry object,
) {
  return [];
}

void _suggestionLogEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  SuggestionLogEntry object,
) {
  object.id = id;
}

extension SuggestionLogEntryByIndex on IsarCollection<SuggestionLogEntry> {
  Future<SuggestionLogEntry?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  SuggestionLogEntry? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<SuggestionLogEntry?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<SuggestionLogEntry?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(SuggestionLogEntry object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(SuggestionLogEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<SuggestionLogEntry> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(
    List<SuggestionLogEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension SuggestionLogEntryQueryWhereSort
    on QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QWhere> {
  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SuggestionLogEntryQueryWhere
    on QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QWhereClause> {
  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterWhereClause>
  uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterWhereClause>
  uuidNotEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterWhereClause>
  followUpUuidEqualTo(String followUpUuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'followUpUuid',
          value: [followUpUuid],
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterWhereClause>
  followUpUuidNotEqualTo(String followUpUuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'followUpUuid',
                lower: [],
                upper: [followUpUuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'followUpUuid',
                lower: [followUpUuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'followUpUuid',
                lower: [followUpUuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'followUpUuid',
                lower: [],
                upper: [followUpUuid],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SuggestionLogEntryQueryFilter
    on QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QFilterCondition> {
  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  actionTakenIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'actionTaken'),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  actionTakenIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'actionTaken'),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  actionTakenEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'actionTaken',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  actionTakenGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'actionTaken',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  actionTakenLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'actionTaken',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  actionTakenBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'actionTaken',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  actionTakenStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'actionTaken',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  actionTakenEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'actionTaken',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  actionTakenContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'actionTaken',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  actionTakenMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'actionTaken',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  actionTakenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'actionTaken', value: ''),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  actionTakenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'actionTaken', value: ''),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  followUpUuidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'followUpUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  followUpUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'followUpUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  followUpUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'followUpUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  followUpUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'followUpUuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  followUpUuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'followUpUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  followUpUuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'followUpUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  followUpUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'followUpUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  followUpUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'followUpUuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  followUpUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'followUpUuid', value: ''),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  followUpUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'followUpUuid', value: ''),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  reasonShownIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'reasonShown'),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  reasonShownIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'reasonShown'),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  reasonShownEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'reasonShown',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  reasonShownGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'reasonShown',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  reasonShownLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'reasonShown',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  reasonShownBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'reasonShown',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  reasonShownStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'reasonShown',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  reasonShownEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'reasonShown',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  reasonShownContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'reasonShown',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  reasonShownMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'reasonShown',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  reasonShownIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reasonShown', value: ''),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  reasonShownIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'reasonShown', value: ''),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  surfacedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'surfacedAt', value: value),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  surfacedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'surfacedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  surfacedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'surfacedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  surfacedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'surfacedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  syncStatusEqualTo(SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  syncStatusGreaterThan(SyncStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  syncStatusLessThan(SyncStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  syncStatusBetween(
    SyncStatus lower,
    SyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncStatus',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  userFeedbackIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'userFeedback'),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  userFeedbackIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'userFeedback'),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  userFeedbackEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userFeedback',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  userFeedbackGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userFeedback',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  userFeedbackLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userFeedback',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  userFeedbackBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userFeedback',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  userFeedbackStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userFeedback',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  userFeedbackEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userFeedback',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  userFeedbackContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userFeedback',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  userFeedbackMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userFeedback',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  userFeedbackIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userFeedback', value: ''),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  userFeedbackIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userFeedback', value: ''),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  uuidEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  uuidStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  uuidEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterFilterCondition>
  uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }
}

extension SuggestionLogEntryQueryObject
    on QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QFilterCondition> {}

extension SuggestionLogEntryQueryLinks
    on QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QFilterCondition> {}

extension SuggestionLogEntryQuerySortBy
    on QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QSortBy> {
  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortByActionTaken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionTaken', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortByActionTakenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionTaken', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortByFollowUpUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpUuid', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortByFollowUpUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpUuid', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortByReasonShown() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasonShown', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortByReasonShownDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasonShown', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortBySurfacedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surfacedAt', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortBySurfacedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surfacedAt', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortByUserFeedback() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userFeedback', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortByUserFeedbackDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userFeedback', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension SuggestionLogEntryQuerySortThenBy
    on QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QSortThenBy> {
  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByActionTaken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionTaken', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByActionTakenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionTaken', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByFollowUpUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpUuid', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByFollowUpUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'followUpUuid', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByReasonShown() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasonShown', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByReasonShownDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reasonShown', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenBySurfacedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surfacedAt', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenBySurfacedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'surfacedAt', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByUserFeedback() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userFeedback', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByUserFeedbackDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userFeedback', Sort.desc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QAfterSortBy>
  thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension SuggestionLogEntryQueryWhereDistinct
    on QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QDistinct> {
  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QDistinct>
  distinctByActionTaken({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actionTaken', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QDistinct>
  distinctByFollowUpUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'followUpUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QDistinct>
  distinctByReasonShown({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reasonShown', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QDistinct>
  distinctBySurfacedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'surfacedAt');
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QDistinct>
  distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QDistinct>
  distinctByUserFeedback({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userFeedback', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QDistinct>
  distinctByUuid({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension SuggestionLogEntryQueryProperty
    on QueryBuilder<SuggestionLogEntry, SuggestionLogEntry, QQueryProperty> {
  QueryBuilder<SuggestionLogEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SuggestionLogEntry, String?, QQueryOperations>
  actionTakenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actionTaken');
    });
  }

  QueryBuilder<SuggestionLogEntry, String, QQueryOperations>
  followUpUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'followUpUuid');
    });
  }

  QueryBuilder<SuggestionLogEntry, String?, QQueryOperations>
  reasonShownProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reasonShown');
    });
  }

  QueryBuilder<SuggestionLogEntry, DateTime, QQueryOperations>
  surfacedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'surfacedAt');
    });
  }

  QueryBuilder<SuggestionLogEntry, SyncStatus, QQueryOperations>
  syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<SuggestionLogEntry, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<SuggestionLogEntry, String?, QQueryOperations>
  userFeedbackProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userFeedback');
    });
  }

  QueryBuilder<SuggestionLogEntry, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
