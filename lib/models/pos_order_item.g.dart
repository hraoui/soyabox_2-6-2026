// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_order_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPosOrderItemCollection on Isar {
  IsarCollection<PosOrderItem> get posOrderItems => this.collection();
}

const PosOrderItemSchema = CollectionSchema(
  name: r'PosOrderItem',
  id: -7181205812123208190,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'glovoBasePrice': PropertySchema(
      id: 1,
      name: r'glovoBasePrice',
      type: IsarType.double,
    ),
    r'groupLabel': PropertySchema(
      id: 2,
      name: r'groupLabel',
      type: IsarType.string,
    ),
    r'groupNumber': PropertySchema(
      id: 3,
      name: r'groupNumber',
      type: IsarType.long,
    ),
    r'itemNote': PropertySchema(
      id: 4,
      name: r'itemNote',
      type: IsarType.string,
    ),
    r'orderId': PropertySchema(
      id: 5,
      name: r'orderId',
      type: IsarType.long,
    ),
    r'paidAmount': PropertySchema(
      id: 6,
      name: r'paidAmount',
      type: IsarType.double,
    ),
    r'partialPaymentHistory': PropertySchema(
      id: 7,
      name: r'partialPaymentHistory',
      type: IsarType.string,
    ),
    r'paymentStatus': PropertySchema(
      id: 8,
      name: r'paymentStatus',
      type: IsarType.string,
    ),
    r'priceType': PropertySchema(
      id: 9,
      name: r'priceType',
      type: IsarType.string,
    ),
    r'productId': PropertySchema(
      id: 10,
      name: r'productId',
      type: IsarType.long,
    ),
    r'productName': PropertySchema(
      id: 11,
      name: r'productName',
      type: IsarType.string,
    ),
    r'quantity': PropertySchema(
      id: 12,
      name: r'quantity',
      type: IsarType.long,
    ),
    r'serviceCourseKey': PropertySchema(
      id: 13,
      name: r'serviceCourseKey',
      type: IsarType.string,
    ),
    r'serviceCourseLabel': PropertySchema(
      id: 14,
      name: r'serviceCourseLabel',
      type: IsarType.string,
    ),
    r'unitPrice': PropertySchema(
      id: 15,
      name: r'unitPrice',
      type: IsarType.double,
    )
  },
  estimateSize: _posOrderItemEstimateSize,
  serialize: _posOrderItemSerialize,
  deserialize: _posOrderItemDeserialize,
  deserializeProp: _posOrderItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'orderId': IndexSchema(
      id: -6176610178429382285,
      name: r'orderId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'orderId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'paymentStatus': IndexSchema(
      id: 7011973130100993011,
      name: r'paymentStatus',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'paymentStatus',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _posOrderItemGetId,
  getLinks: _posOrderItemGetLinks,
  attach: _posOrderItemAttach,
  version: '3.1.0+1',
);

int _posOrderItemEstimateSize(
  PosOrderItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.groupLabel;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.itemNote;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.partialPaymentHistory;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.paymentStatus.length * 3;
  {
    final value = object.priceType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.productName.length * 3;
  {
    final value = object.serviceCourseKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.serviceCourseLabel;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _posOrderItemSerialize(
  PosOrderItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeDouble(offsets[1], object.glovoBasePrice);
  writer.writeString(offsets[2], object.groupLabel);
  writer.writeLong(offsets[3], object.groupNumber);
  writer.writeString(offsets[4], object.itemNote);
  writer.writeLong(offsets[5], object.orderId);
  writer.writeDouble(offsets[6], object.paidAmount);
  writer.writeString(offsets[7], object.partialPaymentHistory);
  writer.writeString(offsets[8], object.paymentStatus);
  writer.writeString(offsets[9], object.priceType);
  writer.writeLong(offsets[10], object.productId);
  writer.writeString(offsets[11], object.productName);
  writer.writeLong(offsets[12], object.quantity);
  writer.writeString(offsets[13], object.serviceCourseKey);
  writer.writeString(offsets[14], object.serviceCourseLabel);
  writer.writeDouble(offsets[15], object.unitPrice);
}

PosOrderItem _posOrderItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PosOrderItem(
    createdAt: reader.readDateTime(offsets[0]),
    glovoBasePrice: reader.readDoubleOrNull(offsets[1]),
    groupLabel: reader.readStringOrNull(offsets[2]),
    groupNumber: reader.readLongOrNull(offsets[3]),
    id: id,
    itemNote: reader.readStringOrNull(offsets[4]),
    orderId: reader.readLong(offsets[5]),
    paidAmount: reader.readDoubleOrNull(offsets[6]) ?? 0.0,
    partialPaymentHistory: reader.readStringOrNull(offsets[7]),
    paymentStatus: reader.readStringOrNull(offsets[8]) ?? 'unpaid',
    priceType: reader.readStringOrNull(offsets[9]),
    productId: reader.readLong(offsets[10]),
    productName: reader.readString(offsets[11]),
    quantity: reader.readLong(offsets[12]),
    serviceCourseKey: reader.readStringOrNull(offsets[13]),
    serviceCourseLabel: reader.readStringOrNull(offsets[14]),
    unitPrice: reader.readDouble(offsets[15]),
  );
  return object;
}

P _posOrderItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset) ?? 'unpaid') as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _posOrderItemGetId(PosOrderItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _posOrderItemGetLinks(PosOrderItem object) {
  return [];
}

void _posOrderItemAttach(
    IsarCollection<dynamic> col, Id id, PosOrderItem object) {
  object.id = id;
}

extension PosOrderItemQueryWhereSort
    on QueryBuilder<PosOrderItem, PosOrderItem, QWhere> {
  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhere> anyOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'orderId'),
      );
    });
  }
}

extension PosOrderItemQueryWhere
    on QueryBuilder<PosOrderItem, PosOrderItem, QWhereClause> {
  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhereClause> idBetween(
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

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhereClause> orderIdEqualTo(
      int orderId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'orderId',
        value: [orderId],
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhereClause> orderIdNotEqualTo(
      int orderId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderId',
              lower: [],
              upper: [orderId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderId',
              lower: [orderId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderId',
              lower: [orderId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'orderId',
              lower: [],
              upper: [orderId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhereClause>
      orderIdGreaterThan(
    int orderId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderId',
        lower: [orderId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhereClause> orderIdLessThan(
    int orderId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderId',
        lower: [],
        upper: [orderId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhereClause> orderIdBetween(
    int lowerOrderId,
    int upperOrderId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'orderId',
        lower: [lowerOrderId],
        includeLower: includeLower,
        upper: [upperOrderId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhereClause>
      paymentStatusEqualTo(String paymentStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'paymentStatus',
        value: [paymentStatus],
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterWhereClause>
      paymentStatusNotEqualTo(String paymentStatus) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paymentStatus',
              lower: [],
              upper: [paymentStatus],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paymentStatus',
              lower: [paymentStatus],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paymentStatus',
              lower: [paymentStatus],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'paymentStatus',
              lower: [],
              upper: [paymentStatus],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PosOrderItemQueryFilter
    on QueryBuilder<PosOrderItem, PosOrderItem, QFilterCondition> {
  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
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

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
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

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
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

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      glovoBasePriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'glovoBasePrice',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      glovoBasePriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'glovoBasePrice',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      glovoBasePriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'glovoBasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      glovoBasePriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'glovoBasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      glovoBasePriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'glovoBasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      glovoBasePriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'glovoBasePrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupLabelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'groupLabel',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupLabelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'groupLabel',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupLabelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupLabelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'groupLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupLabelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'groupLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupLabelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'groupLabel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupLabelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'groupLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupLabelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'groupLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupLabelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'groupLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupLabelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'groupLabel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'groupLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'groupNumber',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'groupNumber',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupNumberEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupNumberGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'groupNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupNumberLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'groupNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      groupNumberBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'groupNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      itemNoteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'itemNote',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      itemNoteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'itemNote',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      itemNoteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      itemNoteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'itemNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      itemNoteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'itemNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      itemNoteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'itemNote',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      itemNoteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'itemNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      itemNoteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'itemNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      itemNoteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'itemNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      itemNoteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'itemNote',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      itemNoteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemNote',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      itemNoteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'itemNote',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      orderIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      orderIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      orderIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      orderIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paidAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paidAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paidAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paidAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paidAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paidAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paidAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paidAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      partialPaymentHistoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partialPaymentHistory',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      partialPaymentHistoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partialPaymentHistory',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      partialPaymentHistoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partialPaymentHistory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      partialPaymentHistoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'partialPaymentHistory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      partialPaymentHistoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'partialPaymentHistory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      partialPaymentHistoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'partialPaymentHistory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      partialPaymentHistoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'partialPaymentHistory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      partialPaymentHistoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'partialPaymentHistory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      partialPaymentHistoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'partialPaymentHistory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      partialPaymentHistoryMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'partialPaymentHistory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      partialPaymentHistoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partialPaymentHistory',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      partialPaymentHistoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'partialPaymentHistory',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paymentStatusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paymentStatusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paymentStatusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paymentStatusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paymentStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paymentStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paymentStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paymentStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paymentStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      paymentStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      priceTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'priceType',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      priceTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'priceType',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      priceTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      priceTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      priceTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      priceTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priceType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      priceTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'priceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      priceTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'priceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      priceTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'priceType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      priceTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'priceType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      priceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priceType',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      priceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'priceType',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      productNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      quantityEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      quantityGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      quantityLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantity',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      quantityBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'serviceCourseKey',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'serviceCourseKey',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serviceCourseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serviceCourseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serviceCourseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serviceCourseKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serviceCourseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serviceCourseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serviceCourseKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serviceCourseKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serviceCourseKey',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serviceCourseKey',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseLabelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'serviceCourseLabel',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseLabelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'serviceCourseLabel',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseLabelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serviceCourseLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseLabelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serviceCourseLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseLabelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serviceCourseLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseLabelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serviceCourseLabel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseLabelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serviceCourseLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseLabelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serviceCourseLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseLabelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serviceCourseLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseLabelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serviceCourseLabel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serviceCourseLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      serviceCourseLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serviceCourseLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      unitPriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unitPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      unitPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unitPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      unitPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unitPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterFilterCondition>
      unitPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unitPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension PosOrderItemQueryObject
    on QueryBuilder<PosOrderItem, PosOrderItem, QFilterCondition> {}

extension PosOrderItemQueryLinks
    on QueryBuilder<PosOrderItem, PosOrderItem, QFilterCondition> {}

extension PosOrderItemQuerySortBy
    on QueryBuilder<PosOrderItem, PosOrderItem, QSortBy> {
  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByGlovoBasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'glovoBasePrice', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByGlovoBasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'glovoBasePrice', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByGroupLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupLabel', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByGroupLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupLabel', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByGroupNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupNumber', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByGroupNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupNumber', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByItemNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemNote', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByItemNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemNote', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByOrderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByPaidAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByPaidAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByPartialPaymentHistory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partialPaymentHistory', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByPartialPaymentHistoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partialPaymentHistory', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByPaymentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByPaymentStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByPriceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceType', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByPriceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceType', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByServiceCourseKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceCourseKey', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByServiceCourseKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceCourseKey', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByServiceCourseLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceCourseLabel', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      sortByServiceCourseLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceCourseLabel', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByUnitPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitPrice', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> sortByUnitPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitPrice', Sort.desc);
    });
  }
}

extension PosOrderItemQuerySortThenBy
    on QueryBuilder<PosOrderItem, PosOrderItem, QSortThenBy> {
  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByGlovoBasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'glovoBasePrice', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByGlovoBasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'glovoBasePrice', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByGroupLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupLabel', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByGroupLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupLabel', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByGroupNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupNumber', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByGroupNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupNumber', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByItemNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemNote', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByItemNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemNote', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByOrderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByPaidAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByPaidAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidAmount', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByPartialPaymentHistory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partialPaymentHistory', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByPartialPaymentHistoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partialPaymentHistory', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByPaymentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByPaymentStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByPriceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceType', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByPriceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceType', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByServiceCourseKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceCourseKey', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByServiceCourseKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceCourseKey', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByServiceCourseLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceCourseLabel', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy>
      thenByServiceCourseLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serviceCourseLabel', Sort.desc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByUnitPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitPrice', Sort.asc);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QAfterSortBy> thenByUnitPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unitPrice', Sort.desc);
    });
  }
}

extension PosOrderItemQueryWhereDistinct
    on QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> {
  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct>
      distinctByGlovoBasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'glovoBasePrice');
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> distinctByGroupLabel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupLabel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> distinctByGroupNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupNumber');
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> distinctByItemNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemNote', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> distinctByOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderId');
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> distinctByPaidAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paidAmount');
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct>
      distinctByPartialPaymentHistory({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partialPaymentHistory',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> distinctByPaymentStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentStatus',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> distinctByPriceType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priceType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> distinctByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId');
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> distinctByProductName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct>
      distinctByServiceCourseKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serviceCourseKey',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct>
      distinctByServiceCourseLabel({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serviceCourseLabel',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrderItem, PosOrderItem, QDistinct> distinctByUnitPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unitPrice');
    });
  }
}

extension PosOrderItemQueryProperty
    on QueryBuilder<PosOrderItem, PosOrderItem, QQueryProperty> {
  QueryBuilder<PosOrderItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PosOrderItem, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PosOrderItem, double?, QQueryOperations>
      glovoBasePriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'glovoBasePrice');
    });
  }

  QueryBuilder<PosOrderItem, String?, QQueryOperations> groupLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupLabel');
    });
  }

  QueryBuilder<PosOrderItem, int?, QQueryOperations> groupNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupNumber');
    });
  }

  QueryBuilder<PosOrderItem, String?, QQueryOperations> itemNoteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemNote');
    });
  }

  QueryBuilder<PosOrderItem, int, QQueryOperations> orderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderId');
    });
  }

  QueryBuilder<PosOrderItem, double, QQueryOperations> paidAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paidAmount');
    });
  }

  QueryBuilder<PosOrderItem, String?, QQueryOperations>
      partialPaymentHistoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partialPaymentHistory');
    });
  }

  QueryBuilder<PosOrderItem, String, QQueryOperations> paymentStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentStatus');
    });
  }

  QueryBuilder<PosOrderItem, String?, QQueryOperations> priceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priceType');
    });
  }

  QueryBuilder<PosOrderItem, int, QQueryOperations> productIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productId');
    });
  }

  QueryBuilder<PosOrderItem, String, QQueryOperations> productNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productName');
    });
  }

  QueryBuilder<PosOrderItem, int, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<PosOrderItem, String?, QQueryOperations>
      serviceCourseKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serviceCourseKey');
    });
  }

  QueryBuilder<PosOrderItem, String?, QQueryOperations>
      serviceCourseLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serviceCourseLabel');
    });
  }

  QueryBuilder<PosOrderItem, double, QQueryOperations> unitPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unitPrice');
    });
  }
}
