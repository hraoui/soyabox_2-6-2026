// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_delivery.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOrderDeliveryCollection on Isar {
  IsarCollection<OrderDelivery> get orderDeliverys => this.collection();
}

const OrderDeliverySchema = CollectionSchema(
  name: r'OrderDelivery',
  id: 1212028802611746927,
  properties: {
    r'assignedAt': PropertySchema(
      id: 0,
      name: r'assignedAt',
      type: IsarType.dateTime,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deliveredAt': PropertySchema(
      id: 2,
      name: r'deliveredAt',
      type: IsarType.dateTime,
    ),
    r'livreurId': PropertySchema(
      id: 3,
      name: r'livreurId',
      type: IsarType.long,
    ),
    r'livreurName': PropertySchema(
      id: 4,
      name: r'livreurName',
      type: IsarType.string,
    ),
    r'livreurPhone': PropertySchema(
      id: 5,
      name: r'livreurPhone',
      type: IsarType.string,
    ),
    r'note': PropertySchema(
      id: 6,
      name: r'note',
      type: IsarType.string,
    ),
    r'orderId': PropertySchema(
      id: 7,
      name: r'orderId',
      type: IsarType.long,
    ),
    r'pickedUpAt': PropertySchema(
      id: 8,
      name: r'pickedUpAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 9,
      name: r'status',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 10,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _orderDeliveryEstimateSize,
  serialize: _orderDeliverySerialize,
  deserialize: _orderDeliveryDeserialize,
  deserializeProp: _orderDeliveryDeserializeProp,
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
    r'status': IndexSchema(
      id: -107785170620420283,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _orderDeliveryGetId,
  getLinks: _orderDeliveryGetLinks,
  attach: _orderDeliveryAttach,
  version: '3.1.0+1',
);

int _orderDeliveryEstimateSize(
  OrderDelivery object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.livreurName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.livreurPhone;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _orderDeliverySerialize(
  OrderDelivery object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.assignedAt);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDateTime(offsets[2], object.deliveredAt);
  writer.writeLong(offsets[3], object.livreurId);
  writer.writeString(offsets[4], object.livreurName);
  writer.writeString(offsets[5], object.livreurPhone);
  writer.writeString(offsets[6], object.note);
  writer.writeLong(offsets[7], object.orderId);
  writer.writeDateTime(offsets[8], object.pickedUpAt);
  writer.writeString(offsets[9], object.status);
  writer.writeDateTime(offsets[10], object.updatedAt);
}

OrderDelivery _orderDeliveryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OrderDelivery(
    assignedAt: reader.readDateTimeOrNull(offsets[0]),
    createdAt: reader.readDateTime(offsets[1]),
    deliveredAt: reader.readDateTimeOrNull(offsets[2]),
    id: id,
    livreurId: reader.readLongOrNull(offsets[3]),
    livreurName: reader.readStringOrNull(offsets[4]),
    livreurPhone: reader.readStringOrNull(offsets[5]),
    note: reader.readStringOrNull(offsets[6]),
    orderId: reader.readLong(offsets[7]),
    pickedUpAt: reader.readDateTimeOrNull(offsets[8]),
    status: reader.readStringOrNull(offsets[9]) ?? 'pending',
    updatedAt: reader.readDateTime(offsets[10]),
  );
  return object;
}

P _orderDeliveryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset) ?? 'pending') as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _orderDeliveryGetId(OrderDelivery object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _orderDeliveryGetLinks(OrderDelivery object) {
  return [];
}

void _orderDeliveryAttach(
    IsarCollection<dynamic> col, Id id, OrderDelivery object) {
  object.id = id;
}

extension OrderDeliveryQueryWhereSort
    on QueryBuilder<OrderDelivery, OrderDelivery, QWhere> {
  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhere> anyOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'orderId'),
      );
    });
  }
}

extension OrderDeliveryQueryWhere
    on QueryBuilder<OrderDelivery, OrderDelivery, QWhereClause> {
  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhereClause> idBetween(
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhereClause> orderIdEqualTo(
      int orderId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'orderId',
        value: [orderId],
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhereClause>
      orderIdNotEqualTo(int orderId) {
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhereClause>
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhereClause> orderIdLessThan(
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhereClause> orderIdBetween(
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhereClause> statusEqualTo(
      String status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterWhereClause>
      statusNotEqualTo(String status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [status],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'status',
              lower: [],
              upper: [status],
              includeUpper: false,
            ));
      }
    });
  }
}

extension OrderDeliveryQueryFilter
    on QueryBuilder<OrderDelivery, OrderDelivery, QFilterCondition> {
  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      assignedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'assignedAt',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      assignedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'assignedAt',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      assignedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      assignedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assignedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      assignedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assignedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      assignedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assignedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      deliveredAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deliveredAt',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      deliveredAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deliveredAt',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      deliveredAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deliveredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      deliveredAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deliveredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      deliveredAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deliveredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      deliveredAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deliveredAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition> idBetween(
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'livreurId',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'livreurId',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'livreurId',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'livreurId',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'livreurId',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'livreurId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'livreurName',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'livreurName',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'livreurName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'livreurName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'livreurName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'livreurName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'livreurName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'livreurName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'livreurName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'livreurName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'livreurName',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'livreurName',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurPhoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'livreurPhone',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurPhoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'livreurPhone',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurPhoneEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'livreurPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurPhoneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'livreurPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurPhoneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'livreurPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurPhoneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'livreurPhone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurPhoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'livreurPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurPhoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'livreurPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurPhoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'livreurPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurPhoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'livreurPhone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurPhoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'livreurPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      livreurPhoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'livreurPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition> noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition> noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition> noteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      orderIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderId',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      pickedUpAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pickedUpAt',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      pickedUpAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pickedUpAt',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      pickedUpAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pickedUpAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      pickedUpAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pickedUpAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      pickedUpAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pickedUpAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      pickedUpAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pickedUpAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      statusEqualTo(
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      statusGreaterThan(
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      statusLessThan(
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      statusBetween(
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      statusStartsWith(
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      statusEndsWith(
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

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension OrderDeliveryQueryObject
    on QueryBuilder<OrderDelivery, OrderDelivery, QFilterCondition> {}

extension OrderDeliveryQueryLinks
    on QueryBuilder<OrderDelivery, OrderDelivery, QFilterCondition> {}

extension OrderDeliveryQuerySortBy
    on QueryBuilder<OrderDelivery, OrderDelivery, QSortBy> {
  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByAssignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAt', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      sortByAssignedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAt', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByDeliveredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredAt', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      sortByDeliveredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredAt', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByLivreurId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'livreurId', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      sortByLivreurIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'livreurId', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByLivreurName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'livreurName', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      sortByLivreurNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'livreurName', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      sortByLivreurPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'livreurPhone', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      sortByLivreurPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'livreurPhone', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByOrderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByPickedUpAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pickedUpAt', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      sortByPickedUpAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pickedUpAt', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension OrderDeliveryQuerySortThenBy
    on QueryBuilder<OrderDelivery, OrderDelivery, QSortThenBy> {
  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByAssignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAt', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      thenByAssignedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedAt', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByDeliveredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredAt', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      thenByDeliveredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveredAt', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByLivreurId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'livreurId', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      thenByLivreurIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'livreurId', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByLivreurName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'livreurName', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      thenByLivreurNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'livreurName', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      thenByLivreurPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'livreurPhone', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      thenByLivreurPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'livreurPhone', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByOrderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderId', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByPickedUpAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pickedUpAt', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      thenByPickedUpAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pickedUpAt', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension OrderDeliveryQueryWhereDistinct
    on QueryBuilder<OrderDelivery, OrderDelivery, QDistinct> {
  QueryBuilder<OrderDelivery, OrderDelivery, QDistinct> distinctByAssignedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assignedAt');
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QDistinct>
      distinctByDeliveredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deliveredAt');
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QDistinct> distinctByLivreurId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'livreurId');
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QDistinct> distinctByLivreurName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'livreurName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QDistinct> distinctByLivreurPhone(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'livreurPhone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QDistinct> distinctByOrderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderId');
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QDistinct> distinctByPickedUpAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pickedUpAt');
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OrderDelivery, OrderDelivery, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension OrderDeliveryQueryProperty
    on QueryBuilder<OrderDelivery, OrderDelivery, QQueryProperty> {
  QueryBuilder<OrderDelivery, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OrderDelivery, DateTime?, QQueryOperations>
      assignedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assignedAt');
    });
  }

  QueryBuilder<OrderDelivery, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<OrderDelivery, DateTime?, QQueryOperations>
      deliveredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deliveredAt');
    });
  }

  QueryBuilder<OrderDelivery, int?, QQueryOperations> livreurIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'livreurId');
    });
  }

  QueryBuilder<OrderDelivery, String?, QQueryOperations> livreurNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'livreurName');
    });
  }

  QueryBuilder<OrderDelivery, String?, QQueryOperations>
      livreurPhoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'livreurPhone');
    });
  }

  QueryBuilder<OrderDelivery, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<OrderDelivery, int, QQueryOperations> orderIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderId');
    });
  }

  QueryBuilder<OrderDelivery, DateTime?, QQueryOperations>
      pickedUpAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pickedUpAt');
    });
  }

  QueryBuilder<OrderDelivery, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<OrderDelivery, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
