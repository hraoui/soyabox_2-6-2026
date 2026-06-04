// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_register_state.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCashRegisterStateCollection on Isar {
  IsarCollection<CashRegisterState> get cashRegisterStates => this.collection();
}

const CashRegisterStateSchema = CollectionSchema(
  name: r'CashRegisterState',
  id: 7409288949221835168,
  properties: {
    r'closedAt': PropertySchema(
      id: 0,
      name: r'closedAt',
      type: IsarType.dateTime,
    ),
    r'closedByStaffId': PropertySchema(
      id: 1,
      name: r'closedByStaffId',
      type: IsarType.long,
    ),
    r'closedByStaffName': PropertySchema(
      id: 2,
      name: r'closedByStaffName',
      type: IsarType.string,
    ),
    r'closingReport': PropertySchema(
      id: 3,
      name: r'closingReport',
      type: IsarType.string,
    ),
    r'date': PropertySchema(
      id: 4,
      name: r'date',
      type: IsarType.string,
    ),
    r'isLockedByAdmin': PropertySchema(
      id: 5,
      name: r'isLockedByAdmin',
      type: IsarType.bool,
    ),
    r'isOpen': PropertySchema(
      id: 6,
      name: r'isOpen',
      type: IsarType.bool,
    ),
    r'isZeroDataActivated': PropertySchema(
      id: 7,
      name: r'isZeroDataActivated',
      type: IsarType.bool,
    ),
    r'openedAt': PropertySchema(
      id: 8,
      name: r'openedAt',
      type: IsarType.dateTime,
    ),
    r'openedByStaffId': PropertySchema(
      id: 9,
      name: r'openedByStaffId',
      type: IsarType.long,
    ),
    r'openedByStaffName': PropertySchema(
      id: 10,
      name: r'openedByStaffName',
      type: IsarType.string,
    ),
    r'zeroDataActivatedAt': PropertySchema(
      id: 11,
      name: r'zeroDataActivatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _cashRegisterStateEstimateSize,
  serialize: _cashRegisterStateSerialize,
  deserialize: _cashRegisterStateDeserialize,
  deserializeProp: _cashRegisterStateDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cashRegisterStateGetId,
  getLinks: _cashRegisterStateGetLinks,
  attach: _cashRegisterStateAttach,
  version: '3.1.0+1',
);

int _cashRegisterStateEstimateSize(
  CashRegisterState object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.closedByStaffName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.closingReport;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.date.length * 3;
  {
    final value = object.openedByStaffName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _cashRegisterStateSerialize(
  CashRegisterState object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.closedAt);
  writer.writeLong(offsets[1], object.closedByStaffId);
  writer.writeString(offsets[2], object.closedByStaffName);
  writer.writeString(offsets[3], object.closingReport);
  writer.writeString(offsets[4], object.date);
  writer.writeBool(offsets[5], object.isLockedByAdmin);
  writer.writeBool(offsets[6], object.isOpen);
  writer.writeBool(offsets[7], object.isZeroDataActivated);
  writer.writeDateTime(offsets[8], object.openedAt);
  writer.writeLong(offsets[9], object.openedByStaffId);
  writer.writeString(offsets[10], object.openedByStaffName);
  writer.writeDateTime(offsets[11], object.zeroDataActivatedAt);
}

CashRegisterState _cashRegisterStateDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CashRegisterState();
  object.closedAt = reader.readDateTimeOrNull(offsets[0]);
  object.closedByStaffId = reader.readLongOrNull(offsets[1]);
  object.closedByStaffName = reader.readStringOrNull(offsets[2]);
  object.closingReport = reader.readStringOrNull(offsets[3]);
  object.date = reader.readString(offsets[4]);
  object.id = id;
  object.isLockedByAdmin = reader.readBool(offsets[5]);
  object.isOpen = reader.readBool(offsets[6]);
  object.isZeroDataActivated = reader.readBool(offsets[7]);
  object.openedAt = reader.readDateTimeOrNull(offsets[8]);
  object.openedByStaffId = reader.readLongOrNull(offsets[9]);
  object.openedByStaffName = reader.readStringOrNull(offsets[10]);
  object.zeroDataActivatedAt = reader.readDateTimeOrNull(offsets[11]);
  return object;
}

P _cashRegisterStateDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cashRegisterStateGetId(CashRegisterState object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cashRegisterStateGetLinks(
    CashRegisterState object) {
  return [];
}

void _cashRegisterStateAttach(
    IsarCollection<dynamic> col, Id id, CashRegisterState object) {
  object.id = id;
}

extension CashRegisterStateByIndex on IsarCollection<CashRegisterState> {
  Future<CashRegisterState?> getByDate(String date) {
    return getByIndex(r'date', [date]);
  }

  CashRegisterState? getByDateSync(String date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(String date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(String date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<CashRegisterState?>> getAllByDate(List<String> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<CashRegisterState?> getAllByDateSync(List<String> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'date', values);
  }

  Future<int> deleteAllByDate(List<String> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'date', values);
  }

  int deleteAllByDateSync(List<String> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'date', values);
  }

  Future<Id> putByDate(CashRegisterState object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(CashRegisterState object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<CashRegisterState> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<CashRegisterState> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension CashRegisterStateQueryWhereSort
    on QueryBuilder<CashRegisterState, CashRegisterState, QWhere> {
  QueryBuilder<CashRegisterState, CashRegisterState, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CashRegisterStateQueryWhere
    on QueryBuilder<CashRegisterState, CashRegisterState, QWhereClause> {
  QueryBuilder<CashRegisterState, CashRegisterState, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterWhereClause>
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

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterWhereClause>
      dateEqualTo(String date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterWhereClause>
      dateNotEqualTo(String date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CashRegisterStateQueryFilter
    on QueryBuilder<CashRegisterState, CashRegisterState, QFilterCondition> {
  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'closedAt',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'closedAt',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'closedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'closedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'closedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'closedByStaffId',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'closedByStaffId',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closedByStaffId',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'closedByStaffId',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'closedByStaffId',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'closedByStaffId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'closedByStaffName',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'closedByStaffName',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closedByStaffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'closedByStaffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'closedByStaffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'closedByStaffName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'closedByStaffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'closedByStaffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'closedByStaffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'closedByStaffName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closedByStaffName',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closedByStaffNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'closedByStaffName',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closingReportIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'closingReport',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closingReportIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'closingReport',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closingReportEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closingReport',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closingReportGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'closingReport',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closingReportLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'closingReport',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closingReportBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'closingReport',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closingReportStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'closingReport',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closingReportEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'closingReport',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closingReportContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'closingReport',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closingReportMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'closingReport',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closingReportIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'closingReport',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      closingReportIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'closingReport',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      dateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      dateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      dateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      dateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      dateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      dateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      dateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'date',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      dateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'date',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'date',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      isLockedByAdminEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLockedByAdmin',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      isOpenEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isOpen',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      isZeroDataActivatedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isZeroDataActivated',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'openedAt',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'openedAt',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'openedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'openedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'openedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'openedByStaffId',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'openedByStaffId',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openedByStaffId',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'openedByStaffId',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'openedByStaffId',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'openedByStaffId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'openedByStaffName',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'openedByStaffName',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openedByStaffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'openedByStaffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'openedByStaffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'openedByStaffName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'openedByStaffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'openedByStaffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'openedByStaffName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'openedByStaffName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'openedByStaffName',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      openedByStaffNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'openedByStaffName',
        value: '',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      zeroDataActivatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'zeroDataActivatedAt',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      zeroDataActivatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'zeroDataActivatedAt',
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      zeroDataActivatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'zeroDataActivatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      zeroDataActivatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'zeroDataActivatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      zeroDataActivatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'zeroDataActivatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterFilterCondition>
      zeroDataActivatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'zeroDataActivatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CashRegisterStateQueryObject
    on QueryBuilder<CashRegisterState, CashRegisterState, QFilterCondition> {}

extension CashRegisterStateQueryLinks
    on QueryBuilder<CashRegisterState, CashRegisterState, QFilterCondition> {}

extension CashRegisterStateQuerySortBy
    on QueryBuilder<CashRegisterState, CashRegisterState, QSortBy> {
  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByClosedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedAt', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByClosedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedAt', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByClosedByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedByStaffId', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByClosedByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedByStaffId', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByClosedByStaffName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedByStaffName', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByClosedByStaffNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedByStaffName', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByClosingReport() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closingReport', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByClosingReportDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closingReport', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByIsLockedByAdmin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLockedByAdmin', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByIsLockedByAdminDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLockedByAdmin', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByIsOpen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOpen', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByIsOpenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOpen', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByIsZeroDataActivated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isZeroDataActivated', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByIsZeroDataActivatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isZeroDataActivated', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedAt', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByOpenedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedAt', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByOpenedByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedByStaffId', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByOpenedByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedByStaffId', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByOpenedByStaffName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedByStaffName', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByOpenedByStaffNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedByStaffName', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByZeroDataActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zeroDataActivatedAt', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      sortByZeroDataActivatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zeroDataActivatedAt', Sort.desc);
    });
  }
}

extension CashRegisterStateQuerySortThenBy
    on QueryBuilder<CashRegisterState, CashRegisterState, QSortThenBy> {
  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByClosedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedAt', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByClosedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedAt', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByClosedByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedByStaffId', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByClosedByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedByStaffId', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByClosedByStaffName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedByStaffName', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByClosedByStaffNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closedByStaffName', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByClosingReport() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closingReport', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByClosingReportDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'closingReport', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByIsLockedByAdmin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLockedByAdmin', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByIsLockedByAdminDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLockedByAdmin', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByIsOpen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOpen', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByIsOpenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOpen', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByIsZeroDataActivated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isZeroDataActivated', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByIsZeroDataActivatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isZeroDataActivated', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedAt', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByOpenedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedAt', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByOpenedByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedByStaffId', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByOpenedByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedByStaffId', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByOpenedByStaffName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedByStaffName', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByOpenedByStaffNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'openedByStaffName', Sort.desc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByZeroDataActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zeroDataActivatedAt', Sort.asc);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QAfterSortBy>
      thenByZeroDataActivatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zeroDataActivatedAt', Sort.desc);
    });
  }
}

extension CashRegisterStateQueryWhereDistinct
    on QueryBuilder<CashRegisterState, CashRegisterState, QDistinct> {
  QueryBuilder<CashRegisterState, CashRegisterState, QDistinct>
      distinctByClosedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'closedAt');
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QDistinct>
      distinctByClosedByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'closedByStaffId');
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QDistinct>
      distinctByClosedByStaffName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'closedByStaffName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QDistinct>
      distinctByClosingReport({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'closingReport',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QDistinct> distinctByDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QDistinct>
      distinctByIsLockedByAdmin() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLockedByAdmin');
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QDistinct>
      distinctByIsOpen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOpen');
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QDistinct>
      distinctByIsZeroDataActivated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isZeroDataActivated');
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QDistinct>
      distinctByOpenedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'openedAt');
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QDistinct>
      distinctByOpenedByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'openedByStaffId');
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QDistinct>
      distinctByOpenedByStaffName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'openedByStaffName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CashRegisterState, CashRegisterState, QDistinct>
      distinctByZeroDataActivatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'zeroDataActivatedAt');
    });
  }
}

extension CashRegisterStateQueryProperty
    on QueryBuilder<CashRegisterState, CashRegisterState, QQueryProperty> {
  QueryBuilder<CashRegisterState, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CashRegisterState, DateTime?, QQueryOperations>
      closedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'closedAt');
    });
  }

  QueryBuilder<CashRegisterState, int?, QQueryOperations>
      closedByStaffIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'closedByStaffId');
    });
  }

  QueryBuilder<CashRegisterState, String?, QQueryOperations>
      closedByStaffNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'closedByStaffName');
    });
  }

  QueryBuilder<CashRegisterState, String?, QQueryOperations>
      closingReportProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'closingReport');
    });
  }

  QueryBuilder<CashRegisterState, String, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<CashRegisterState, bool, QQueryOperations>
      isLockedByAdminProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLockedByAdmin');
    });
  }

  QueryBuilder<CashRegisterState, bool, QQueryOperations> isOpenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOpen');
    });
  }

  QueryBuilder<CashRegisterState, bool, QQueryOperations>
      isZeroDataActivatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isZeroDataActivated');
    });
  }

  QueryBuilder<CashRegisterState, DateTime?, QQueryOperations>
      openedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'openedAt');
    });
  }

  QueryBuilder<CashRegisterState, int?, QQueryOperations>
      openedByStaffIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'openedByStaffId');
    });
  }

  QueryBuilder<CashRegisterState, String?, QQueryOperations>
      openedByStaffNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'openedByStaffName');
    });
  }

  QueryBuilder<CashRegisterState, DateTime?, QQueryOperations>
      zeroDataActivatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'zeroDataActivatedAt');
    });
  }
}
