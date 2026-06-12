// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'print_job.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPrintJobCollection on Isar {
  IsarCollection<PrintJob> get printJobs => this.collection();
}

const PrintJobSchema = CollectionSchema(
  name: r'PrintJob',
  id: -6589136277925558055,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'errorMessage': PropertySchema(
      id: 1,
      name: r'errorMessage',
      type: IsarType.string,
    ),
    r'nextAttemptAt': PropertySchema(
      id: 2,
      name: r'nextAttemptAt',
      type: IsarType.dateTime,
    ),
    r'orderRef': PropertySchema(
      id: 3,
      name: r'orderRef',
      type: IsarType.string,
    ),
    r'payloadBase64': PropertySchema(
      id: 4,
      name: r'payloadBase64',
      type: IsarType.string,
    ),
    r'payloadBytes': PropertySchema(
      id: 5,
      name: r'payloadBytes',
      type: IsarType.longList,
    ),
    r'printedAt': PropertySchema(
      id: 6,
      name: r'printedAt',
      type: IsarType.dateTime,
    ),
    r'printerHost': PropertySchema(
      id: 7,
      name: r'printerHost',
      type: IsarType.string,
    ),
    r'printerPort': PropertySchema(
      id: 8,
      name: r'printerPort',
      type: IsarType.long,
    ),
    r'retryCount': PropertySchema(
      id: 9,
      name: r'retryCount',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 10,
      name: r'status',
      type: IsarType.string,
    ),
    r'ticketType': PropertySchema(
      id: 11,
      name: r'ticketType',
      type: IsarType.string,
    )
  },
  estimateSize: _printJobEstimateSize,
  serialize: _printJobSerialize,
  deserialize: _printJobDeserialize,
  deserializeProp: _printJobDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _printJobGetId,
  getLinks: _printJobGetLinks,
  attach: _printJobAttach,
  version: '3.1.0+1',
);

int _printJobEstimateSize(
  PrintJob object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.errorMessage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.orderRef;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.payloadBase64.length * 3;
  bytesCount += 3 + object.payloadBytes.length * 8;
  bytesCount += 3 + object.printerHost.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.ticketType.length * 3;
  return bytesCount;
}

void _printJobSerialize(
  PrintJob object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.errorMessage);
  writer.writeDateTime(offsets[2], object.nextAttemptAt);
  writer.writeString(offsets[3], object.orderRef);
  writer.writeString(offsets[4], object.payloadBase64);
  writer.writeLongList(offsets[5], object.payloadBytes);
  writer.writeDateTime(offsets[6], object.printedAt);
  writer.writeString(offsets[7], object.printerHost);
  writer.writeLong(offsets[8], object.printerPort);
  writer.writeLong(offsets[9], object.retryCount);
  writer.writeString(offsets[10], object.status);
  writer.writeString(offsets[11], object.ticketType);
}

PrintJob _printJobDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PrintJob(
    createdAt: reader.readDateTimeOrNull(offsets[0]),
    errorMessage: reader.readStringOrNull(offsets[1]),
    id: id,
    orderRef: reader.readStringOrNull(offsets[3]),
    payloadBase64: reader.readString(offsets[4]),
    printedAt: reader.readDateTimeOrNull(offsets[6]),
    printerHost: reader.readString(offsets[7]),
    printerPort: reader.readLong(offsets[8]),
    retryCount: reader.readLongOrNull(offsets[9]) ?? 0,
    status: reader.readStringOrNull(offsets[10]) ?? 'pending',
    ticketType: reader.readString(offsets[11]),
  );
  object.nextAttemptAt = reader.readDateTimeOrNull(offsets[2]);
  return object;
}

P _printJobDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLongList(offset) ?? []) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 10:
      return (reader.readStringOrNull(offset) ?? 'pending') as P;
    case 11:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _printJobGetId(PrintJob object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _printJobGetLinks(PrintJob object) {
  return [];
}

void _printJobAttach(IsarCollection<dynamic> col, Id id, PrintJob object) {
  object.id = id;
}

extension PrintJobQueryWhereSort on QueryBuilder<PrintJob, PrintJob, QWhere> {
  QueryBuilder<PrintJob, PrintJob, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PrintJobQueryWhere on QueryBuilder<PrintJob, PrintJob, QWhereClause> {
  QueryBuilder<PrintJob, PrintJob, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<PrintJob, PrintJob, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterWhereClause> idBetween(
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

extension PrintJobQueryFilter
    on QueryBuilder<PrintJob, PrintJob, QFilterCondition> {
  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> createdAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> errorMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      errorMessageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'errorMessage',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> errorMessageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      errorMessageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> errorMessageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> errorMessageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorMessage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      errorMessageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> errorMessageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> errorMessageContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'errorMessage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> errorMessageMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'errorMessage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      errorMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      errorMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'errorMessage',
        value: '',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      nextAttemptAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nextAttemptAt',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      nextAttemptAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nextAttemptAt',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> nextAttemptAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextAttemptAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      nextAttemptAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextAttemptAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> nextAttemptAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextAttemptAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> nextAttemptAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextAttemptAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> orderRefIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'orderRef',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> orderRefIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'orderRef',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> orderRefEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> orderRefGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> orderRefLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> orderRefBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderRef',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> orderRefStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'orderRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> orderRefEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'orderRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> orderRefContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'orderRef',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> orderRefMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'orderRef',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> orderRefIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderRef',
        value: '',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> orderRefIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'orderRef',
        value: '',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> payloadBase64EqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadBase64',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBase64GreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payloadBase64',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> payloadBase64LessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payloadBase64',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> payloadBase64Between(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payloadBase64',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBase64StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'payloadBase64',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> payloadBase64EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'payloadBase64',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> payloadBase64Contains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payloadBase64',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> payloadBase64Matches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payloadBase64',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBase64IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadBase64',
        value: '',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBase64IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payloadBase64',
        value: '',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBytesElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payloadBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBytesElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payloadBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBytesElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payloadBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBytesElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payloadBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBytesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'payloadBytes',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBytesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'payloadBytes',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBytesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'payloadBytes',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBytesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'payloadBytes',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBytesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'payloadBytes',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      payloadBytesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'payloadBytes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'printedAt',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'printedAt',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'printedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'printedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'printedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'printedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printerHostEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'printerHost',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      printerHostGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'printerHost',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printerHostLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'printerHost',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printerHostBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'printerHost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printerHostStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'printerHost',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printerHostEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'printerHost',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printerHostContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'printerHost',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printerHostMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'printerHost',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printerHostIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'printerHost',
        value: '',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      printerHostIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'printerHost',
        value: '',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printerPortEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'printerPort',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      printerPortGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'printerPort',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printerPortLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'printerPort',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> printerPortBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'printerPort',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> retryCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> retryCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> retryCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'retryCount',
        value: value,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> retryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'retryCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> statusEqualTo(
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

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> statusGreaterThan(
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

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> statusLessThan(
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

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> statusBetween(
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

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> statusStartsWith(
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

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> statusEndsWith(
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

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> statusContains(
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

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> statusMatches(
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

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> ticketTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticketType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> ticketTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ticketType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> ticketTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ticketType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> ticketTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ticketType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> ticketTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ticketType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> ticketTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ticketType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> ticketTypeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ticketType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> ticketTypeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ticketType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition> ticketTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ticketType',
        value: '',
      ));
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterFilterCondition>
      ticketTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ticketType',
        value: '',
      ));
    });
  }
}

extension PrintJobQueryObject
    on QueryBuilder<PrintJob, PrintJob, QFilterCondition> {}

extension PrintJobQueryLinks
    on QueryBuilder<PrintJob, PrintJob, QFilterCondition> {}

extension PrintJobQuerySortBy on QueryBuilder<PrintJob, PrintJob, QSortBy> {
  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByNextAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByNextAttemptAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByOrderRef() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderRef', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByOrderRefDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderRef', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByPayloadBase64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadBase64', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByPayloadBase64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadBase64', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByPrintedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'printedAt', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByPrintedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'printedAt', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByPrinterHost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'printerHost', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByPrinterHostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'printerHost', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByPrinterPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'printerPort', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByPrinterPortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'printerPort', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByTicketType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketType', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> sortByTicketTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketType', Sort.desc);
    });
  }
}

extension PrintJobQuerySortThenBy
    on QueryBuilder<PrintJob, PrintJob, QSortThenBy> {
  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByErrorMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByErrorMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMessage', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByNextAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByNextAttemptAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByOrderRef() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderRef', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByOrderRefDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderRef', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByPayloadBase64() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadBase64', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByPayloadBase64Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadBase64', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByPrintedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'printedAt', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByPrintedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'printedAt', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByPrinterHost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'printerHost', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByPrinterHostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'printerHost', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByPrinterPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'printerPort', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByPrinterPortDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'printerPort', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByTicketType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketType', Sort.asc);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QAfterSortBy> thenByTicketTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ticketType', Sort.desc);
    });
  }
}

extension PrintJobQueryWhereDistinct
    on QueryBuilder<PrintJob, PrintJob, QDistinct> {
  QueryBuilder<PrintJob, PrintJob, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PrintJob, PrintJob, QDistinct> distinctByErrorMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorMessage', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QDistinct> distinctByNextAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextAttemptAt');
    });
  }

  QueryBuilder<PrintJob, PrintJob, QDistinct> distinctByOrderRef(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderRef', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QDistinct> distinctByPayloadBase64(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadBase64',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QDistinct> distinctByPayloadBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadBytes');
    });
  }

  QueryBuilder<PrintJob, PrintJob, QDistinct> distinctByPrintedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'printedAt');
    });
  }

  QueryBuilder<PrintJob, PrintJob, QDistinct> distinctByPrinterHost(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'printerHost', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QDistinct> distinctByPrinterPort() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'printerPort');
    });
  }

  QueryBuilder<PrintJob, PrintJob, QDistinct> distinctByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retryCount');
    });
  }

  QueryBuilder<PrintJob, PrintJob, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PrintJob, PrintJob, QDistinct> distinctByTicketType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ticketType', caseSensitive: caseSensitive);
    });
  }
}

extension PrintJobQueryProperty
    on QueryBuilder<PrintJob, PrintJob, QQueryProperty> {
  QueryBuilder<PrintJob, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PrintJob, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PrintJob, String?, QQueryOperations> errorMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorMessage');
    });
  }

  QueryBuilder<PrintJob, DateTime?, QQueryOperations> nextAttemptAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextAttemptAt');
    });
  }

  QueryBuilder<PrintJob, String?, QQueryOperations> orderRefProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderRef');
    });
  }

  QueryBuilder<PrintJob, String, QQueryOperations> payloadBase64Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadBase64');
    });
  }

  QueryBuilder<PrintJob, List<int>, QQueryOperations> payloadBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadBytes');
    });
  }

  QueryBuilder<PrintJob, DateTime?, QQueryOperations> printedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'printedAt');
    });
  }

  QueryBuilder<PrintJob, String, QQueryOperations> printerHostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'printerHost');
    });
  }

  QueryBuilder<PrintJob, int, QQueryOperations> printerPortProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'printerPort');
    });
  }

  QueryBuilder<PrintJob, int, QQueryOperations> retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retryCount');
    });
  }

  QueryBuilder<PrintJob, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<PrintJob, String, QQueryOperations> ticketTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ticketType');
    });
  }
}
