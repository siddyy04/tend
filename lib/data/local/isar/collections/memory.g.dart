// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMemoryCollection on Isar {
  IsarCollection<Memory> get memorys => this.collection();
}

const MemorySchema = CollectionSchema(
  name: r'Memory',
  id: 6426130528628242831,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.byte,
      enumMap: _MemorycategoryEnumValueMap,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'datePrecision': PropertySchema(
      id: 2,
      name: r'datePrecision',
      type: IsarType.byte,
      enumMap: _MemorydatePrecisionEnumValueMap,
    ),
    r'dateValue': PropertySchema(
      id: 3,
      name: r'dateValue',
      type: IsarType.dateTime,
    ),
    r'dateValueRaw': PropertySchema(
      id: 4,
      name: r'dateValueRaw',
      type: IsarType.string,
    ),
    r'deletedAt': PropertySchema(
      id: 5,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'embedding': PropertySchema(
      id: 6,
      name: r'embedding',
      type: IsarType.doubleList,
    ),
    r'embeddingModelVersion': PropertySchema(
      id: 7,
      name: r'embeddingModelVersion',
      type: IsarType.string,
    ),
    r'eventText': PropertySchema(
      id: 8,
      name: r'eventText',
      type: IsarType.string,
    ),
    r'extractionConfidence': PropertySchema(
      id: 9,
      name: r'extractionConfidence',
      type: IsarType.double,
    ),
    r'importanceScore': PropertySchema(
      id: 10,
      name: r'importanceScore',
      type: IsarType.long,
    ),
    r'needsUserConfirmation': PropertySchema(
      id: 11,
      name: r'needsUserConfirmation',
      type: IsarType.bool,
    ),
    r'personMatchConfidence': PropertySchema(
      id: 12,
      name: r'personMatchConfidence',
      type: IsarType.double,
    ),
    r'personUuid': PropertySchema(
      id: 13,
      name: r'personUuid',
      type: IsarType.string,
    ),
    r'quoteEvidence': PropertySchema(
      id: 14,
      name: r'quoteEvidence',
      type: IsarType.string,
    ),
    r'sensitivityFlag': PropertySchema(
      id: 15,
      name: r'sensitivityFlag',
      type: IsarType.byte,
      enumMap: _MemorysensitivityFlagEnumValueMap,
    ),
    r'sourceRef': PropertySchema(
      id: 16,
      name: r'sourceRef',
      type: IsarType.string,
    ),
    r'sourceType': PropertySchema(
      id: 17,
      name: r'sourceType',
      type: IsarType.byte,
      enumMap: _MemorysourceTypeEnumValueMap,
    ),
    r'syncStatus': PropertySchema(
      id: 18,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _MemorysyncStatusEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 19,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(id: 20, name: r'uuid', type: IsarType.string),
  },

  estimateSize: _memoryEstimateSize,
  serialize: _memorySerialize,
  deserialize: _memoryDeserialize,
  deserializeProp: _memoryDeserializeProp,
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
    r'personUuid': IndexSchema(
      id: -2347702038642741989,
      name: r'personUuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'personUuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'category': IndexSchema(
      id: -7560358558326323820,
      name: r'category',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'category',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'dateValue': IndexSchema(
      id: 7494659051703925341,
      name: r'dateValue',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dateValue',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'embeddingModelVersion': IndexSchema(
      id: 1779734734228596330,
      name: r'embeddingModelVersion',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'embeddingModelVersion',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _memoryGetId,
  getLinks: _memoryGetLinks,
  attach: _memoryAttach,
  version: '3.3.2',
);

int _memoryEstimateSize(
  Memory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.dateValueRaw;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.embedding;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  {
    final value = object.embeddingModelVersion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.eventText.length * 3;
  bytesCount += 3 + object.personUuid.length * 3;
  {
    final value = object.quoteEvidence;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sourceRef;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _memorySerialize(
  Memory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeByte(offsets[0], object.category.index);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeByte(offsets[2], object.datePrecision.index);
  writer.writeDateTime(offsets[3], object.dateValue);
  writer.writeString(offsets[4], object.dateValueRaw);
  writer.writeDateTime(offsets[5], object.deletedAt);
  writer.writeDoubleList(offsets[6], object.embedding);
  writer.writeString(offsets[7], object.embeddingModelVersion);
  writer.writeString(offsets[8], object.eventText);
  writer.writeDouble(offsets[9], object.extractionConfidence);
  writer.writeLong(offsets[10], object.importanceScore);
  writer.writeBool(offsets[11], object.needsUserConfirmation);
  writer.writeDouble(offsets[12], object.personMatchConfidence);
  writer.writeString(offsets[13], object.personUuid);
  writer.writeString(offsets[14], object.quoteEvidence);
  writer.writeByte(offsets[15], object.sensitivityFlag.index);
  writer.writeString(offsets[16], object.sourceRef);
  writer.writeByte(offsets[17], object.sourceType.index);
  writer.writeByte(offsets[18], object.syncStatus.index);
  writer.writeDateTime(offsets[19], object.updatedAt);
  writer.writeString(offsets[20], object.uuid);
}

Memory _memoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Memory();
  object.category =
      _MemorycategoryValueEnumMap[reader.readByteOrNull(offsets[0])] ??
      MemoryCategory.family;
  object.createdAt = reader.readDateTime(offsets[1]);
  object.datePrecision =
      _MemorydatePrecisionValueEnumMap[reader.readByteOrNull(offsets[2])] ??
      DatePrecision.explicit;
  object.dateValue = reader.readDateTimeOrNull(offsets[3]);
  object.dateValueRaw = reader.readStringOrNull(offsets[4]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[5]);
  object.embedding = reader.readDoubleList(offsets[6]);
  object.embeddingModelVersion = reader.readStringOrNull(offsets[7]);
  object.eventText = reader.readString(offsets[8]);
  object.extractionConfidence = reader.readDoubleOrNull(offsets[9]);
  object.id = id;
  object.importanceScore = reader.readLong(offsets[10]);
  object.needsUserConfirmation = reader.readBool(offsets[11]);
  object.personMatchConfidence = reader.readDoubleOrNull(offsets[12]);
  object.personUuid = reader.readString(offsets[13]);
  object.quoteEvidence = reader.readStringOrNull(offsets[14]);
  object.sensitivityFlag =
      _MemorysensitivityFlagValueEnumMap[reader.readByteOrNull(offsets[15])] ??
      SensitivityLevel.low;
  object.sourceRef = reader.readStringOrNull(offsets[16]);
  object.sourceType =
      _MemorysourceTypeValueEnumMap[reader.readByteOrNull(offsets[17])] ??
      SourceType.voice;
  object.syncStatus =
      _MemorysyncStatusValueEnumMap[reader.readByteOrNull(offsets[18])] ??
      SyncStatus.pending;
  object.updatedAt = reader.readDateTime(offsets[19]);
  object.uuid = reader.readString(offsets[20]);
  return object;
}

P _memoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_MemorycategoryValueEnumMap[reader.readByteOrNull(offset)] ??
              MemoryCategory.family)
          as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (_MemorydatePrecisionValueEnumMap[reader.readByteOrNull(offset)] ??
              DatePrecision.explicit)
          as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleList(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (_MemorysensitivityFlagValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              SensitivityLevel.low)
          as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (_MemorysourceTypeValueEnumMap[reader.readByteOrNull(offset)] ??
              SourceType.voice)
          as P;
    case 18:
      return (_MemorysyncStatusValueEnumMap[reader.readByteOrNull(offset)] ??
              SyncStatus.pending)
          as P;
    case 19:
      return (reader.readDateTime(offset)) as P;
    case 20:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _MemorycategoryEnumValueMap = {
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
const _MemorycategoryValueEnumMap = {
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
const _MemorydatePrecisionEnumValueMap = {
  'explicit': 0,
  'relative': 1,
  'none': 2,
};
const _MemorydatePrecisionValueEnumMap = {
  0: DatePrecision.explicit,
  1: DatePrecision.relative,
  2: DatePrecision.none,
};
const _MemorysensitivityFlagEnumValueMap = {'low': 0, 'medium': 1, 'high': 2};
const _MemorysensitivityFlagValueEnumMap = {
  0: SensitivityLevel.low,
  1: SensitivityLevel.medium,
  2: SensitivityLevel.high,
};
const _MemorysourceTypeEnumValueMap = {
  'voice': 0,
  'text': 1,
  'photo': 2,
  'share': 3,
};
const _MemorysourceTypeValueEnumMap = {
  0: SourceType.voice,
  1: SourceType.text,
  2: SourceType.photo,
  3: SourceType.share,
};
const _MemorysyncStatusEnumValueMap = {
  'pending': 0,
  'synced': 1,
  'conflict': 2,
};
const _MemorysyncStatusValueEnumMap = {
  0: SyncStatus.pending,
  1: SyncStatus.synced,
  2: SyncStatus.conflict,
};

Id _memoryGetId(Memory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _memoryGetLinks(Memory object) {
  return [];
}

void _memoryAttach(IsarCollection<dynamic> col, Id id, Memory object) {
  object.id = id;
}

extension MemoryByIndex on IsarCollection<Memory> {
  Future<Memory?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  Memory? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<Memory?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<Memory?> getAllByUuidSync(List<String> uuidValues) {
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

  Future<Id> putByUuid(Memory object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(Memory object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<Memory> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<Memory> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension MemoryQueryWhereSort on QueryBuilder<Memory, Memory, QWhere> {
  QueryBuilder<Memory, Memory, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhere> anyCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'category'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhere> anyDateValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dateValue'),
      );
    });
  }
}

extension MemoryQueryWhere on QueryBuilder<Memory, Memory, QWhereClause> {
  QueryBuilder<Memory, Memory, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Memory, Memory, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> idBetween(
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

  QueryBuilder<Memory, Memory, QAfterWhereClause> uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> uuidNotEqualTo(String uuid) {
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

  QueryBuilder<Memory, Memory, QAfterWhereClause> personUuidEqualTo(
    String personUuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'personUuid', value: [personUuid]),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> personUuidNotEqualTo(
    String personUuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'personUuid',
                lower: [],
                upper: [personUuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'personUuid',
                lower: [personUuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'personUuid',
                lower: [personUuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'personUuid',
                lower: [],
                upper: [personUuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> categoryEqualTo(
    MemoryCategory category,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'category', value: [category]),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> categoryNotEqualTo(
    MemoryCategory category,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'category',
                lower: [],
                upper: [category],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'category',
                lower: [category],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'category',
                lower: [category],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'category',
                lower: [],
                upper: [category],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> categoryGreaterThan(
    MemoryCategory category, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'category',
          lower: [category],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> categoryLessThan(
    MemoryCategory category, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'category',
          lower: [],
          upper: [category],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> categoryBetween(
    MemoryCategory lowerCategory,
    MemoryCategory upperCategory, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'category',
          lower: [lowerCategory],
          includeLower: includeLower,
          upper: [upperCategory],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> dateValueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dateValue', value: [null]),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> dateValueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dateValue',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> dateValueEqualTo(
    DateTime? dateValue,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'dateValue', value: [dateValue]),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> dateValueNotEqualTo(
    DateTime? dateValue,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateValue',
                lower: [],
                upper: [dateValue],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateValue',
                lower: [dateValue],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateValue',
                lower: [dateValue],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'dateValue',
                lower: [],
                upper: [dateValue],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> dateValueGreaterThan(
    DateTime? dateValue, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dateValue',
          lower: [dateValue],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> dateValueLessThan(
    DateTime? dateValue, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dateValue',
          lower: [],
          upper: [dateValue],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> dateValueBetween(
    DateTime? lowerDateValue,
    DateTime? upperDateValue, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'dateValue',
          lower: [lowerDateValue],
          includeLower: includeLower,
          upper: [upperDateValue],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause>
  embeddingModelVersionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'embeddingModelVersion',
          value: [null],
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause>
  embeddingModelVersionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'embeddingModelVersion',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause> embeddingModelVersionEqualTo(
    String? embeddingModelVersion,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'embeddingModelVersion',
          value: [embeddingModelVersion],
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterWhereClause>
  embeddingModelVersionNotEqualTo(String? embeddingModelVersion) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'embeddingModelVersion',
                lower: [],
                upper: [embeddingModelVersion],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'embeddingModelVersion',
                lower: [embeddingModelVersion],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'embeddingModelVersion',
                lower: [embeddingModelVersion],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'embeddingModelVersion',
                lower: [],
                upper: [embeddingModelVersion],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension MemoryQueryFilter on QueryBuilder<Memory, Memory, QFilterCondition> {
  QueryBuilder<Memory, Memory, QAfterFilterCondition> categoryEqualTo(
    MemoryCategory value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: value),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> categoryGreaterThan(
    MemoryCategory value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> categoryLessThan(
    MemoryCategory value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> categoryBetween(
    MemoryCategory lower,
    MemoryCategory upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> datePrecisionEqualTo(
    DatePrecision value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'datePrecision', value: value),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> datePrecisionGreaterThan(
    DatePrecision value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'datePrecision',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> datePrecisionLessThan(
    DatePrecision value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'datePrecision',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> datePrecisionBetween(
    DatePrecision lower,
    DatePrecision upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'datePrecision',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'dateValue'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'dateValue'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateValue', value: value),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateValue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateValue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateValue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueRawIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'dateValueRaw'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueRawIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'dateValueRaw'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueRawEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dateValueRaw',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueRawGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateValueRaw',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueRawLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateValueRaw',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueRawBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateValueRaw',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueRawStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dateValueRaw',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueRawEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dateValueRaw',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueRawContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dateValueRaw',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueRawMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dateValueRaw',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueRawIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateValueRaw', value: ''),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> dateValueRawIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dateValueRaw', value: ''),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> deletedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deletedAt', value: value),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> deletedAtGreaterThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> deletedAtLessThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> deletedAtBetween(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> embeddingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'embedding'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> embeddingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'embedding'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> embeddingElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'embedding',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'embedding',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> embeddingElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'embedding',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> embeddingElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'embedding',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> embeddingLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'embedding', length, true, length, true);
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> embeddingIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'embedding', 0, true, 0, true);
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> embeddingIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'embedding', 0, false, 999999, true);
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> embeddingLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'embedding', 0, true, length, include);
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'embedding', length, include, 999999, true);
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> embeddingLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'embedding',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingModelVersionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'embeddingModelVersion'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingModelVersionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'embeddingModelVersion'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingModelVersionEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'embeddingModelVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingModelVersionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'embeddingModelVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingModelVersionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'embeddingModelVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingModelVersionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'embeddingModelVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingModelVersionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'embeddingModelVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingModelVersionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'embeddingModelVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingModelVersionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'embeddingModelVersion',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingModelVersionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'embeddingModelVersion',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingModelVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'embeddingModelVersion', value: ''),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  embeddingModelVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'embeddingModelVersion',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> eventTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'eventText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> eventTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'eventText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> eventTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'eventText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> eventTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'eventText',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> eventTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'eventText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> eventTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'eventText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> eventTextContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'eventText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> eventTextMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'eventText',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> eventTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventText', value: ''),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> eventTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventText', value: ''),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  extractionConfidenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'extractionConfidence'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  extractionConfidenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'extractionConfidence'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  extractionConfidenceEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'extractionConfidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  extractionConfidenceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'extractionConfidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  extractionConfidenceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'extractionConfidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  extractionConfidenceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'extractionConfidence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> importanceScoreEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'importanceScore', value: value),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  importanceScoreGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'importanceScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> importanceScoreLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'importanceScore',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> importanceScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'importanceScore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  needsUserConfirmationEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'needsUserConfirmation',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  personMatchConfidenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'personMatchConfidence'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  personMatchConfidenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'personMatchConfidence'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  personMatchConfidenceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'personMatchConfidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  personMatchConfidenceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'personMatchConfidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  personMatchConfidenceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'personMatchConfidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  personMatchConfidenceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'personMatchConfidence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> personUuidEqualTo(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> personUuidGreaterThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> personUuidLessThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> personUuidBetween(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> personUuidStartsWith(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> personUuidEndsWith(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> personUuidContains(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> personUuidMatches(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> personUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'personUuid', value: ''),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> personUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'personUuid', value: ''),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> quoteEvidenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'quoteEvidence'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> quoteEvidenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'quoteEvidence'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> quoteEvidenceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'quoteEvidence',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> quoteEvidenceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'quoteEvidence',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> quoteEvidenceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'quoteEvidence',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> quoteEvidenceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'quoteEvidence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> quoteEvidenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'quoteEvidence',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> quoteEvidenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'quoteEvidence',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> quoteEvidenceContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'quoteEvidence',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> quoteEvidenceMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'quoteEvidence',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> quoteEvidenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'quoteEvidence', value: ''),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  quoteEvidenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'quoteEvidence', value: ''),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sensitivityFlagEqualTo(
    SensitivityLevel value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sensitivityFlag', value: value),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition>
  sensitivityFlagGreaterThan(SensitivityLevel value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sensitivityFlag',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sensitivityFlagLessThan(
    SensitivityLevel value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sensitivityFlag',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sensitivityFlagBetween(
    SensitivityLevel lower,
    SensitivityLevel upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sensitivityFlag',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceRefIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceRef'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceRefIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceRef'),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceRefEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceRef',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceRefGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceRef',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceRefLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceRef',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceRefBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceRef',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceRefStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceRef',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceRefEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceRef',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceRefContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceRef',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceRefMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceRef',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceRefIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceRef', value: ''),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceRefIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceRef', value: ''),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceTypeEqualTo(
    SourceType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceType', value: value),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceTypeGreaterThan(
    SourceType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceTypeLessThan(
    SourceType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> sourceTypeBetween(
    SourceType lower,
    SourceType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> syncStatusEqualTo(
    SyncStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncStatus', value: value),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> syncStatusGreaterThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> syncStatusLessThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> syncStatusBetween(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> updatedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> updatedAtBetween(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> uuidEqualTo(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> uuidGreaterThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> uuidLessThan(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> uuidBetween(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> uuidStartsWith(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> uuidEndsWith(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> uuidContains(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> uuidMatches(
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

  QueryBuilder<Memory, Memory, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<Memory, Memory, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }
}

extension MemoryQueryObject on QueryBuilder<Memory, Memory, QFilterCondition> {}

extension MemoryQueryLinks on QueryBuilder<Memory, Memory, QFilterCondition> {}

extension MemoryQuerySortBy on QueryBuilder<Memory, Memory, QSortBy> {
  QueryBuilder<Memory, Memory, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByDatePrecision() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datePrecision', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByDatePrecisionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datePrecision', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByDateValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateValue', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByDateValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateValue', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByDateValueRaw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateValueRaw', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByDateValueRawDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateValueRaw', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByEmbeddingModelVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingModelVersion', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByEmbeddingModelVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingModelVersion', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByEventText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventText', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByEventTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventText', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByExtractionConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extractionConfidence', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByExtractionConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extractionConfidence', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByImportanceScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importanceScore', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByImportanceScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importanceScore', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByNeedsUserConfirmation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsUserConfirmation', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByNeedsUserConfirmationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsUserConfirmation', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByPersonMatchConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personMatchConfidence', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByPersonMatchConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personMatchConfidence', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByPersonUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personUuid', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByPersonUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personUuid', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByQuoteEvidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quoteEvidence', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByQuoteEvidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quoteEvidence', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortBySensitivityFlag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sensitivityFlag', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortBySensitivityFlagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sensitivityFlag', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortBySourceRef() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceRef', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortBySourceRefDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceRef', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension MemoryQuerySortThenBy on QueryBuilder<Memory, Memory, QSortThenBy> {
  QueryBuilder<Memory, Memory, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByDatePrecision() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datePrecision', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByDatePrecisionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'datePrecision', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByDateValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateValue', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByDateValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateValue', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByDateValueRaw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateValueRaw', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByDateValueRawDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateValueRaw', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByEmbeddingModelVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingModelVersion', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByEmbeddingModelVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'embeddingModelVersion', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByEventText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventText', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByEventTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventText', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByExtractionConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extractionConfidence', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByExtractionConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extractionConfidence', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByImportanceScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importanceScore', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByImportanceScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importanceScore', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByNeedsUserConfirmation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsUserConfirmation', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByNeedsUserConfirmationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsUserConfirmation', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByPersonMatchConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personMatchConfidence', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByPersonMatchConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personMatchConfidence', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByPersonUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personUuid', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByPersonUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personUuid', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByQuoteEvidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quoteEvidence', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByQuoteEvidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quoteEvidence', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenBySensitivityFlag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sensitivityFlag', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenBySensitivityFlagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sensitivityFlag', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenBySourceRef() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceRef', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenBySourceRefDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceRef', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Memory, Memory, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension MemoryQueryWhereDistinct on QueryBuilder<Memory, Memory, QDistinct> {
  QueryBuilder<Memory, Memory, QDistinct> distinctByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByDatePrecision() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'datePrecision');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByDateValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateValue');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByDateValueRaw({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateValueRaw', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByEmbedding() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'embedding');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByEmbeddingModelVersion({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'embeddingModelVersion',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByEventText({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByExtractionConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'extractionConfidence');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByImportanceScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'importanceScore');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByNeedsUserConfirmation() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsUserConfirmation');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByPersonMatchConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personMatchConfidence');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByPersonUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByQuoteEvidence({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'quoteEvidence',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctBySensitivityFlag() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sensitivityFlag');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctBySourceRef({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceRef', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceType');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<Memory, Memory, QDistinct> distinctByUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension MemoryQueryProperty on QueryBuilder<Memory, Memory, QQueryProperty> {
  QueryBuilder<Memory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Memory, MemoryCategory, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<Memory, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Memory, DatePrecision, QQueryOperations>
  datePrecisionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'datePrecision');
    });
  }

  QueryBuilder<Memory, DateTime?, QQueryOperations> dateValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateValue');
    });
  }

  QueryBuilder<Memory, String?, QQueryOperations> dateValueRawProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateValueRaw');
    });
  }

  QueryBuilder<Memory, DateTime?, QQueryOperations> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<Memory, List<double>?, QQueryOperations> embeddingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'embedding');
    });
  }

  QueryBuilder<Memory, String?, QQueryOperations>
  embeddingModelVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'embeddingModelVersion');
    });
  }

  QueryBuilder<Memory, String, QQueryOperations> eventTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventText');
    });
  }

  QueryBuilder<Memory, double?, QQueryOperations>
  extractionConfidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'extractionConfidence');
    });
  }

  QueryBuilder<Memory, int, QQueryOperations> importanceScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'importanceScore');
    });
  }

  QueryBuilder<Memory, bool, QQueryOperations> needsUserConfirmationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsUserConfirmation');
    });
  }

  QueryBuilder<Memory, double?, QQueryOperations>
  personMatchConfidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personMatchConfidence');
    });
  }

  QueryBuilder<Memory, String, QQueryOperations> personUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personUuid');
    });
  }

  QueryBuilder<Memory, String?, QQueryOperations> quoteEvidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quoteEvidence');
    });
  }

  QueryBuilder<Memory, SensitivityLevel, QQueryOperations>
  sensitivityFlagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sensitivityFlag');
    });
  }

  QueryBuilder<Memory, String?, QQueryOperations> sourceRefProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceRef');
    });
  }

  QueryBuilder<Memory, SourceType, QQueryOperations> sourceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceType');
    });
  }

  QueryBuilder<Memory, SyncStatus, QQueryOperations> syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<Memory, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<Memory, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
