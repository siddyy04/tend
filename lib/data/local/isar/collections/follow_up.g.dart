// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_up.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFollowUpCollection on Isar {
  IsarCollection<FollowUp> get followUps => this.collection();
}

const FollowUpSchema = CollectionSchema(
  name: r'FollowUp',
  id: -3976074331475440442,
  properties: {
    r'categorySnapshot': PropertySchema(
      id: 0,
      name: r'categorySnapshot',
      type: IsarType.byte,
      enumMap: _FollowUpcategorySnapshotEnumValueMap,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deletedAt': PropertySchema(
      id: 2,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'expectedDate': PropertySchema(
      id: 3,
      name: r'expectedDate',
      type: IsarType.dateTime,
    ),
    r'importanceScoreSnapshot': PropertySchema(
      id: 4,
      name: r'importanceScoreSnapshot',
      type: IsarType.long,
    ),
    r'memoryUuid': PropertySchema(
      id: 5,
      name: r'memoryUuid',
      type: IsarType.string,
    ),
    r'note': PropertySchema(id: 6, name: r'note', type: IsarType.string),
    r'personUuid': PropertySchema(
      id: 7,
      name: r'personUuid',
      type: IsarType.string,
    ),
    r'resolvedAt': PropertySchema(
      id: 8,
      name: r'resolvedAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 9,
      name: r'status',
      type: IsarType.byte,
      enumMap: _FollowUpstatusEnumValueMap,
    ),
    r'syncStatus': PropertySchema(
      id: 10,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _FollowUpsyncStatusEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 11,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(id: 12, name: r'uuid', type: IsarType.string),
  },

  estimateSize: _followUpEstimateSize,
  serialize: _followUpSerialize,
  deserialize: _followUpDeserialize,
  deserializeProp: _followUpDeserializeProp,
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
    r'memoryUuid': IndexSchema(
      id: 3168432064361027343,
      name: r'memoryUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'memoryUuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'expectedDate': IndexSchema(
      id: -5420717690305763913,
      name: r'expectedDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'expectedDate',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'status': IndexSchema(
      id: -107785170620420283,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _followUpGetId,
  getLinks: _followUpGetLinks,
  attach: _followUpAttach,
  version: '3.3.2',
);

int _followUpEstimateSize(
  FollowUp object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.memoryUuid.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.personUuid.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _followUpSerialize(
  FollowUp object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeByte(offsets[0], object.categorySnapshot.index);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDateTime(offsets[2], object.deletedAt);
  writer.writeDateTime(offsets[3], object.expectedDate);
  writer.writeLong(offsets[4], object.importanceScoreSnapshot);
  writer.writeString(offsets[5], object.memoryUuid);
  writer.writeString(offsets[6], object.note);
  writer.writeString(offsets[7], object.personUuid);
  writer.writeDateTime(offsets[8], object.resolvedAt);
  writer.writeByte(offsets[9], object.status.index);
  writer.writeByte(offsets[10], object.syncStatus.index);
  writer.writeDateTime(offsets[11], object.updatedAt);
  writer.writeString(offsets[12], object.uuid);
}

FollowUp _followUpDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FollowUp();
  object.categorySnapshot =
      _FollowUpcategorySnapshotValueEnumMap[reader.readByteOrNull(
        offsets[0],
      )] ??
      MemoryCategory.family;
  object.createdAt = reader.readDateTime(offsets[1]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[2]);
  object.expectedDate = reader.readDateTimeOrNull(offsets[3]);
  object.id = id;
  object.importanceScoreSnapshot = reader.readLong(offsets[4]);
  object.memoryUuid = reader.readString(offsets[5]);
  object.note = reader.readStringOrNull(offsets[6]);
  object.personUuid = reader.readString(offsets[7]);
  object.resolvedAt = reader.readDateTimeOrNull(offsets[8]);
  object.status =
      _FollowUpstatusValueEnumMap[reader.readByteOrNull(offsets[9])] ??
      FollowUpStatus.open;
  object.syncStatus =
      _FollowUpsyncStatusValueEnumMap[reader.readByteOrNull(offsets[10])] ??
      SyncStatus.pending;
  object.updatedAt = reader.readDateTime(offsets[11]);
  object.uuid = reader.readString(offsets[12]);
  return object;
}

P _followUpDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_FollowUpcategorySnapshotValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              MemoryCategory.family)
          as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (_FollowUpstatusValueEnumMap[reader.readByteOrNull(offset)] ??
              FollowUpStatus.open)
          as P;
    case 10:
      return (_FollowUpsyncStatusValueEnumMap[reader.readByteOrNull(offset)] ??
              SyncStatus.pending)
          as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _FollowUpcategorySnapshotEnumValueMap = {
  'family': 0,
  'career': 1,
  'health': 2,
  'education': 3,
  'travel': 4,
  'finance': 5,
  'goals': 6,
  'hobbies': 7,
  'preferences': 8,
  'promises': 9,
  'milestones': 10,
};
const _FollowUpcategorySnapshotValueEnumMap = {
  0: MemoryCategory.family,
  1: MemoryCategory.career,
  2: MemoryCategory.health,
  3: MemoryCategory.education,
  4: MemoryCategory.travel,
  5: MemoryCategory.finance,
  6: MemoryCategory.goals,
  7: MemoryCategory.hobbies,
  8: MemoryCategory.preferences,
  9: MemoryCategory.promises,
  10: MemoryCategory.milestones,
};
const _FollowUpstatusEnumValueMap = {'open': 0, 'done': 1, 'dismissed': 2};
const _FollowUpstatusValueEnumMap = {
  0: FollowUpStatus.open,
  1: FollowUpStatus.done,
  2: FollowUpStatus.dismissed,
};
const _FollowUpsyncStatusEnumValueMap = {
  'pending': 0,
  'synced': 1,
  'conflict': 2,
};
const _FollowUpsyncStatusValueEnumMap = {
  0: SyncStatus.pending,
  1: SyncStatus.synced,
  2: SyncStatus.conflict,
};

Id _followUpGetId(FollowUp object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _followUpGetLinks(FollowUp object) {
  return [];
}

void _followUpAttach(IsarCollection<dynamic> col, Id id, FollowUp object) {
  object.id = id;
}

extension FollowUpByIndex on IsarCollection<FollowUp> {
  Future<FollowUp?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  FollowUp? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<FollowUp?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<FollowUp?> getAllByUuidSync(List<String> uuidValues) {
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

  Future<Id> putByUuid(FollowUp object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(FollowUp object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<FollowUp> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<FollowUp> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension FollowUpQueryWhereSort on QueryBuilder<FollowUp, FollowUp, QWhere> {
  QueryBuilder<FollowUp, FollowUp, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhere> anyExpectedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'expectedDate'),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhere> anyStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'status'),
      );
    });
  }
}

extension FollowUpQueryWhere on QueryBuilder<FollowUp, FollowUp, QWhereClause> {
  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> idBetween(
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

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> uuidNotEqualTo(
    String uuid,
  ) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> memoryUuidEqualTo(
    String memoryUuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'memoryUuid', value: [memoryUuid]),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> memoryUuidNotEqualTo(
    String memoryUuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'memoryUuid',
                lower: [],
                upper: [memoryUuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'memoryUuid',
                lower: [memoryUuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'memoryUuid',
                lower: [memoryUuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'memoryUuid',
                lower: [],
                upper: [memoryUuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> expectedDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'expectedDate', value: [null]),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> expectedDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'expectedDate',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> expectedDateEqualTo(
    DateTime? expectedDate,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'expectedDate',
          value: [expectedDate],
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> expectedDateNotEqualTo(
    DateTime? expectedDate,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'expectedDate',
                lower: [],
                upper: [expectedDate],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'expectedDate',
                lower: [expectedDate],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'expectedDate',
                lower: [expectedDate],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'expectedDate',
                lower: [],
                upper: [expectedDate],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> expectedDateGreaterThan(
    DateTime? expectedDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'expectedDate',
          lower: [expectedDate],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> expectedDateLessThan(
    DateTime? expectedDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'expectedDate',
          lower: [],
          upper: [expectedDate],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> expectedDateBetween(
    DateTime? lowerExpectedDate,
    DateTime? upperExpectedDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'expectedDate',
          lower: [lowerExpectedDate],
          includeLower: includeLower,
          upper: [upperExpectedDate],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> statusEqualTo(
    FollowUpStatus status,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'status', value: [status]),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> statusNotEqualTo(
    FollowUpStatus status,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [],
                upper: [status],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [status],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [status],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [],
                upper: [status],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> statusGreaterThan(
    FollowUpStatus status, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'status',
          lower: [status],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> statusLessThan(
    FollowUpStatus status, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'status',
          lower: [],
          upper: [status],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterWhereClause> statusBetween(
    FollowUpStatus lowerStatus,
    FollowUpStatus upperStatus, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'status',
          lower: [lowerStatus],
          includeLower: includeLower,
          upper: [upperStatus],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension FollowUpQueryFilter
    on QueryBuilder<FollowUp, FollowUp, QFilterCondition> {
  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  categorySnapshotEqualTo(MemoryCategory value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'categorySnapshot', value: value),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  categorySnapshotGreaterThan(MemoryCategory value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'categorySnapshot',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  categorySnapshotLessThan(MemoryCategory value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'categorySnapshot',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  categorySnapshotBetween(
    MemoryCategory lower,
    MemoryCategory upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'categorySnapshot',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> deletedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deletedAt', value: value),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> deletedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deletedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> deletedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deletedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deletedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> expectedDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'expectedDate'),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  expectedDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'expectedDate'),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> expectedDateEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'expectedDate', value: value),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  expectedDateGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'expectedDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> expectedDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'expectedDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> expectedDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'expectedDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> idBetween(
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  importanceScoreSnapshotEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'importanceScoreSnapshot',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  importanceScoreSnapshotGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'importanceScoreSnapshot',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  importanceScoreSnapshotLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'importanceScoreSnapshot',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  importanceScoreSnapshotBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'importanceScoreSnapshot',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> memoryUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'memoryUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> memoryUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'memoryUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> memoryUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'memoryUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> memoryUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'memoryUuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> memoryUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'memoryUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> memoryUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'memoryUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> memoryUuidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'memoryUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> memoryUuidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'memoryUuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> memoryUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'memoryUuid', value: ''),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  memoryUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'memoryUuid', value: ''),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'note'),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'note'),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'note',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> noteContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> noteMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'note',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> personUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'personUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> personUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'personUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> personUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'personUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> personUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'personUuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> personUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'personUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> personUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'personUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> personUuidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'personUuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> personUuidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'personUuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> personUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'personUuid', value: ''),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  personUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'personUuid', value: ''),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> resolvedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'resolvedAt'),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition>
  resolvedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'resolvedAt'),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> resolvedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'resolvedAt', value: value),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> resolvedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'resolvedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> resolvedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'resolvedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> resolvedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'resolvedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> statusEqualTo(
    FollowUpStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: value),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> statusGreaterThan(
    FollowUpStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> statusLessThan(
    FollowUpStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> statusBetween(
    FollowUpStatus lower,
    FollowUpStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> syncStatusEqualTo(
    SyncStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> syncStatusGreaterThan(
    SyncStatus value, {
    bool include = false,
  }) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> syncStatusLessThan(
    SyncStatus value, {
    bool include = false,
  }) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> syncStatusBetween(
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> updatedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> updatedAtBetween(
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> uuidGreaterThan(
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> uuidLessThan(
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> uuidBetween(
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> uuidContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> uuidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }
}

extension FollowUpQueryObject
    on QueryBuilder<FollowUp, FollowUp, QFilterCondition> {}

extension FollowUpQueryLinks
    on QueryBuilder<FollowUp, FollowUp, QFilterCondition> {}

extension FollowUpQuerySortBy on QueryBuilder<FollowUp, FollowUp, QSortBy> {
  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByCategorySnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categorySnapshot', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByCategorySnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categorySnapshot', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByExpectedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDate', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByExpectedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDate', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy>
  sortByImportanceScoreSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importanceScoreSnapshot', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy>
  sortByImportanceScoreSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importanceScoreSnapshot', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByMemoryUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryUuid', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByMemoryUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryUuid', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByPersonUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personUuid', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByPersonUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personUuid', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByResolvedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAt', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByResolvedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAt', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension FollowUpQuerySortThenBy
    on QueryBuilder<FollowUp, FollowUp, QSortThenBy> {
  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByCategorySnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categorySnapshot', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByCategorySnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'categorySnapshot', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByExpectedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDate', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByExpectedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDate', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy>
  thenByImportanceScoreSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importanceScoreSnapshot', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy>
  thenByImportanceScoreSnapshotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importanceScoreSnapshot', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByMemoryUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryUuid', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByMemoryUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'memoryUuid', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByPersonUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personUuid', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByPersonUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personUuid', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByResolvedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAt', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByResolvedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAt', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension FollowUpQueryWhereDistinct
    on QueryBuilder<FollowUp, FollowUp, QDistinct> {
  QueryBuilder<FollowUp, FollowUp, QDistinct> distinctByCategorySnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'categorySnapshot');
    });
  }

  QueryBuilder<FollowUp, FollowUp, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<FollowUp, FollowUp, QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<FollowUp, FollowUp, QDistinct> distinctByExpectedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expectedDate');
    });
  }

  QueryBuilder<FollowUp, FollowUp, QDistinct>
  distinctByImportanceScoreSnapshot() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'importanceScoreSnapshot');
    });
  }

  QueryBuilder<FollowUp, FollowUp, QDistinct> distinctByMemoryUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'memoryUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QDistinct> distinctByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QDistinct> distinctByPersonUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FollowUp, FollowUp, QDistinct> distinctByResolvedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'resolvedAt');
    });
  }

  QueryBuilder<FollowUp, FollowUp, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<FollowUp, FollowUp, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<FollowUp, FollowUp, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<FollowUp, FollowUp, QDistinct> distinctByUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension FollowUpQueryProperty
    on QueryBuilder<FollowUp, FollowUp, QQueryProperty> {
  QueryBuilder<FollowUp, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FollowUp, MemoryCategory, QQueryOperations>
  categorySnapshotProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'categorySnapshot');
    });
  }

  QueryBuilder<FollowUp, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<FollowUp, DateTime?, QQueryOperations> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<FollowUp, DateTime?, QQueryOperations> expectedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expectedDate');
    });
  }

  QueryBuilder<FollowUp, int, QQueryOperations>
  importanceScoreSnapshotProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'importanceScoreSnapshot');
    });
  }

  QueryBuilder<FollowUp, String, QQueryOperations> memoryUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'memoryUuid');
    });
  }

  QueryBuilder<FollowUp, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<FollowUp, String, QQueryOperations> personUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personUuid');
    });
  }

  QueryBuilder<FollowUp, DateTime?, QQueryOperations> resolvedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resolvedAt');
    });
  }

  QueryBuilder<FollowUp, FollowUpStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<FollowUp, SyncStatus, QQueryOperations> syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<FollowUp, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<FollowUp, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
