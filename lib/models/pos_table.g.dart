// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_table.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPosTableCollection on Isar {
  IsarCollection<PosTable> get posTables => this.collection();
}

const PosTableSchema = CollectionSchema(
  name: r'PosTable',
  id: 5867504445397671215,
  properties: {
    r'gridColumnEnd': PropertySchema(
      id: 0,
      name: r'gridColumnEnd',
      type: IsarType.long,
    ),
    r'gridColumnStart': PropertySchema(
      id: 1,
      name: r'gridColumnStart',
      type: IsarType.long,
    ),
    r'gridRowEnd': PropertySchema(
      id: 2,
      name: r'gridRowEnd',
      type: IsarType.long,
    ),
    r'gridRowStart': PropertySchema(
      id: 3,
      name: r'gridRowStart',
      type: IsarType.long,
    ),
    r'number': PropertySchema(
      id: 4,
      name: r'number',
      type: IsarType.string,
    ),
    r'remoteId': PropertySchema(
      id: 5,
      name: r'remoteId',
      type: IsarType.long,
    ),
    r'restaurantId': PropertySchema(
      id: 6,
      name: r'restaurantId',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 7,
      name: r'status',
      type: IsarType.string,
    )
  },
  estimateSize: _posTableEstimateSize,
  serialize: _posTableSerialize,
  deserialize: _posTableDeserialize,
  deserializeProp: _posTableDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _posTableGetId,
  getLinks: _posTableGetLinks,
  attach: _posTableAttach,
  version: '3.1.0+1',
);

int _posTableEstimateSize(
  PosTable object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.number.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _posTableSerialize(
  PosTable object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.gridColumnEnd);
  writer.writeLong(offsets[1], object.gridColumnStart);
  writer.writeLong(offsets[2], object.gridRowEnd);
  writer.writeLong(offsets[3], object.gridRowStart);
  writer.writeString(offsets[4], object.number);
  writer.writeLong(offsets[5], object.remoteId);
  writer.writeLong(offsets[6], object.restaurantId);
  writer.writeString(offsets[7], object.status);
}

PosTable _posTableDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PosTable(
    gridColumnEnd: reader.readLongOrNull(offsets[0]) ?? 2,
    gridColumnStart: reader.readLongOrNull(offsets[1]) ?? 1,
    gridRowEnd: reader.readLongOrNull(offsets[2]) ?? 2,
    gridRowStart: reader.readLongOrNull(offsets[3]) ?? 1,
    id: id,
    number: reader.readString(offsets[4]),
    remoteId: reader.readLongOrNull(offsets[5]),
    restaurantId: reader.readLongOrNull(offsets[6]),
    status: reader.readStringOrNull(offsets[7]) ?? 'available',
  );
  return object;
}

P _posTableDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset) ?? 2) as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    case 2:
      return (reader.readLongOrNull(offset) ?? 2) as P;
    case 3:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset) ?? 'available') as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _posTableGetId(PosTable object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _posTableGetLinks(PosTable object) {
  return [];
}

void _posTableAttach(IsarCollection<dynamic> col, Id id, PosTable object) {
  object.id = id;
}

extension PosTableQueryWhereSort on QueryBuilder<PosTable, PosTable, QWhere> {
  QueryBuilder<PosTable, PosTable, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PosTableQueryWhere on QueryBuilder<PosTable, PosTable, QWhereClause> {
  QueryBuilder<PosTable, PosTable, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<PosTable, PosTable, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterWhereClause> idBetween(
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
}

extension PosTableQueryFilter
    on QueryBuilder<PosTable, PosTable, QFilterCondition> {
  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> gridColumnEndEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gridColumnEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition>
      gridColumnEndGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gridColumnEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> gridColumnEndLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gridColumnEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> gridColumnEndBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gridColumnEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition>
      gridColumnStartEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gridColumnStart',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition>
      gridColumnStartGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gridColumnStart',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition>
      gridColumnStartLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gridColumnStart',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition>
      gridColumnStartBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gridColumnStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> gridRowEndEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gridRowEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> gridRowEndGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gridRowEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> gridRowEndLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gridRowEnd',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> gridRowEndBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gridRowEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> gridRowStartEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gridRowStart',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition>
      gridRowStartGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gridRowStart',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> gridRowStartLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gridRowStart',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> gridRowStartBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gridRowStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> numberEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'number',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> numberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'number',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> numberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'number',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> numberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'number',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> numberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'number',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> numberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'number',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> numberContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'number',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> numberMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'number',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> numberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'number',
        value: '',
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> numberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'number',
        value: '',
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> remoteIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> remoteIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> remoteIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> remoteIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> restaurantIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'restaurantId',
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition>
      restaurantIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'restaurantId',
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> restaurantIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'restaurantId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition>
      restaurantIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'restaurantId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> restaurantIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'restaurantId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> restaurantIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'restaurantId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> statusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> statusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }
}

extension PosTableQueryObject
    on QueryBuilder<PosTable, PosTable, QFilterCondition> {}

extension PosTableQueryLinks
    on QueryBuilder<PosTable, PosTable, QFilterCondition> {}

extension PosTableQuerySortBy on QueryBuilder<PosTable, PosTable, QSortBy> {
  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByGridColumnEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridColumnEnd', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByGridColumnEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridColumnEnd', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByGridColumnStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridColumnStart', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByGridColumnStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridColumnStart', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByGridRowEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridRowEnd', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByGridRowEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridRowEnd', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByGridRowStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridRowStart', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByGridRowStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridRowStart', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByRestaurantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restaurantId', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByRestaurantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restaurantId', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension PosTableQuerySortThenBy
    on QueryBuilder<PosTable, PosTable, QSortThenBy> {
  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByGridColumnEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridColumnEnd', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByGridColumnEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridColumnEnd', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByGridColumnStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridColumnStart', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByGridColumnStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridColumnStart', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByGridRowEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridRowEnd', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByGridRowEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridRowEnd', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByGridRowStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridRowStart', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByGridRowStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gridRowStart', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'number', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByRestaurantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restaurantId', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByRestaurantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restaurantId', Sort.desc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<PosTable, PosTable, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension PosTableQueryWhereDistinct
    on QueryBuilder<PosTable, PosTable, QDistinct> {
  QueryBuilder<PosTable, PosTable, QDistinct> distinctByGridColumnEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gridColumnEnd');
    });
  }

  QueryBuilder<PosTable, PosTable, QDistinct> distinctByGridColumnStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gridColumnStart');
    });
  }

  QueryBuilder<PosTable, PosTable, QDistinct> distinctByGridRowEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gridRowEnd');
    });
  }

  QueryBuilder<PosTable, PosTable, QDistinct> distinctByGridRowStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gridRowStart');
    });
  }

  QueryBuilder<PosTable, PosTable, QDistinct> distinctByNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'number', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosTable, PosTable, QDistinct> distinctByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId');
    });
  }

  QueryBuilder<PosTable, PosTable, QDistinct> distinctByRestaurantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'restaurantId');
    });
  }

  QueryBuilder<PosTable, PosTable, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }
}

extension PosTableQueryProperty
    on QueryBuilder<PosTable, PosTable, QQueryProperty> {
  QueryBuilder<PosTable, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PosTable, int, QQueryOperations> gridColumnEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gridColumnEnd');
    });
  }

  QueryBuilder<PosTable, int, QQueryOperations> gridColumnStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gridColumnStart');
    });
  }

  QueryBuilder<PosTable, int, QQueryOperations> gridRowEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gridRowEnd');
    });
  }

  QueryBuilder<PosTable, int, QQueryOperations> gridRowStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gridRowStart');
    });
  }

  QueryBuilder<PosTable, String, QQueryOperations> numberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'number');
    });
  }

  QueryBuilder<PosTable, int?, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<PosTable, int?, QQueryOperations> restaurantIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'restaurantId');
    });
  }

  QueryBuilder<PosTable, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }
}
