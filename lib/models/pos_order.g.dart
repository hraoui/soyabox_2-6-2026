// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_order.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPosOrderCollection on Isar {
  IsarCollection<PosOrder> get posOrders => this.collection();
}

const PosOrderSchema = CollectionSchema(
  name: r'PosOrder',
  id: 3248918737662570853,
  properties: {
    r'cancelReason': PropertySchema(
      id: 0,
      name: r'cancelReason',
      type: IsarType.string,
    ),
    r'channel': PropertySchema(
      id: 1,
      name: r'channel',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'customerName': PropertySchema(
      id: 3,
      name: r'customerName',
      type: IsarType.string,
    ),
    r'customerPhone': PropertySchema(
      id: 4,
      name: r'customerPhone',
      type: IsarType.string,
    ),
    r'deliveryAddress': PropertySchema(
      id: 5,
      name: r'deliveryAddress',
      type: IsarType.string,
    ),
    r'deliveryLivreurId': PropertySchema(
      id: 6,
      name: r'deliveryLivreurId',
      type: IsarType.long,
    ),
    r'deliveryLivreurName': PropertySchema(
      id: 7,
      name: r'deliveryLivreurName',
      type: IsarType.string,
    ),
    r'deliveryLivreurPhone': PropertySchema(
      id: 8,
      name: r'deliveryLivreurPhone',
      type: IsarType.string,
    ),
    r'discountAmount': PropertySchema(
      id: 9,
      name: r'discountAmount',
      type: IsarType.double,
    ),
    r'fulfillmentType': PropertySchema(
      id: 10,
      name: r'fulfillmentType',
      type: IsarType.string,
    ),
    r'hasDiscount': PropertySchema(
      id: 11,
      name: r'hasDiscount',
      type: IsarType.bool,
    ),
    r'isDailySynced': PropertySchema(
      id: 12,
      name: r'isDailySynced',
      type: IsarType.bool,
    ),
    r'isFromApi': PropertySchema(
      id: 13,
      name: r'isFromApi',
      type: IsarType.bool,
    ),
    r'isGlovoDelivery': PropertySchema(
      id: 14,
      name: r'isGlovoDelivery',
      type: IsarType.bool,
    ),
    r'note': PropertySchema(
      id: 15,
      name: r'note',
      type: IsarType.string,
    ),
    r'originalTotal': PropertySchema(
      id: 16,
      name: r'originalTotal',
      type: IsarType.double,
    ),
    r'paidByStaffId': PropertySchema(
      id: 17,
      name: r'paidByStaffId',
      type: IsarType.long,
    ),
    r'paymentMethod': PropertySchema(
      id: 18,
      name: r'paymentMethod',
      type: IsarType.string,
    ),
    r'paymentSplit': PropertySchema(
      id: 19,
      name: r'paymentSplit',
      type: IsarType.string,
    ),
    r'paymentStatus': PropertySchema(
      id: 20,
      name: r'paymentStatus',
      type: IsarType.string,
    ),
    r'restaurantId': PropertySchema(
      id: 21,
      name: r'restaurantId',
      type: IsarType.long,
    ),
    r'rewardId': PropertySchema(
      id: 22,
      name: r'rewardId',
      type: IsarType.long,
    ),
    r'sourceLocalId': PropertySchema(
      id: 23,
      name: r'sourceLocalId',
      type: IsarType.long,
    ),
    r'staffId': PropertySchema(
      id: 24,
      name: r'staffId',
      type: IsarType.long,
    ),
    r'status': PropertySchema(
      id: 25,
      name: r'status',
      type: IsarType.string,
    ),
    r'tableNumber': PropertySchema(
      id: 26,
      name: r'tableNumber',
      type: IsarType.string,
    ),
    r'totalPrice': PropertySchema(
      id: 27,
      name: r'totalPrice',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 28,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 29,
      name: r'userId',
      type: IsarType.long,
    )
  },
  estimateSize: _posOrderEstimateSize,
  serialize: _posOrderSerialize,
  deserialize: _posOrderDeserialize,
  deserializeProp: _posOrderDeserializeProp,
  idName: r'id',
  indexes: {
    r'sourceLocalId': IndexSchema(
      id: -6620091777817845507,
      name: r'sourceLocalId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'sourceLocalId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'channel': IndexSchema(
      id: 8853698245235537269,
      name: r'channel',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'channel',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'isFromApi': IndexSchema(
      id: 7018770145620438688,
      name: r'isFromApi',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isFromApi',
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
    ),
    r'customerPhone': IndexSchema(
      id: -8632026876438867685,
      name: r'customerPhone',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'customerPhone',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'isDailySynced': IndexSchema(
      id: 6594025582231075925,
      name: r'isDailySynced',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isDailySynced',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _posOrderGetId,
  getLinks: _posOrderGetLinks,
  attach: _posOrderAttach,
  version: '3.1.0+1',
);

int _posOrderEstimateSize(
  PosOrder object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.cancelReason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.channel.length * 3;
  {
    final value = object.customerName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.customerPhone;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.deliveryAddress;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.deliveryLivreurName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.deliveryLivreurPhone;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.fulfillmentType.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.paymentMethod;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.paymentSplit;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.paymentStatus.length * 3;
  bytesCount += 3 + object.status.length * 3;
  {
    final value = object.tableNumber;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _posOrderSerialize(
  PosOrder object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cancelReason);
  writer.writeString(offsets[1], object.channel);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.customerName);
  writer.writeString(offsets[4], object.customerPhone);
  writer.writeString(offsets[5], object.deliveryAddress);
  writer.writeLong(offsets[6], object.deliveryLivreurId);
  writer.writeString(offsets[7], object.deliveryLivreurName);
  writer.writeString(offsets[8], object.deliveryLivreurPhone);
  writer.writeDouble(offsets[9], object.discountAmount);
  writer.writeString(offsets[10], object.fulfillmentType);
  writer.writeBool(offsets[11], object.hasDiscount);
  writer.writeBool(offsets[12], object.isDailySynced);
  writer.writeBool(offsets[13], object.isFromApi);
  writer.writeBool(offsets[14], object.isGlovoDelivery);
  writer.writeString(offsets[15], object.note);
  writer.writeDouble(offsets[16], object.originalTotal);
  writer.writeLong(offsets[17], object.paidByStaffId);
  writer.writeString(offsets[18], object.paymentMethod);
  writer.writeString(offsets[19], object.paymentSplit);
  writer.writeString(offsets[20], object.paymentStatus);
  writer.writeLong(offsets[21], object.restaurantId);
  writer.writeLong(offsets[22], object.rewardId);
  writer.writeLong(offsets[23], object.sourceLocalId);
  writer.writeLong(offsets[24], object.staffId);
  writer.writeString(offsets[25], object.status);
  writer.writeString(offsets[26], object.tableNumber);
  writer.writeDouble(offsets[27], object.totalPrice);
  writer.writeDateTime(offsets[28], object.updatedAt);
  writer.writeLong(offsets[29], object.userId);
}

PosOrder _posOrderDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PosOrder(
    cancelReason: reader.readStringOrNull(offsets[0]),
    channel: reader.readStringOrNull(offsets[1]) ?? 'pos',
    createdAt: reader.readDateTime(offsets[2]),
    customerName: reader.readStringOrNull(offsets[3]),
    customerPhone: reader.readStringOrNull(offsets[4]),
    deliveryAddress: reader.readStringOrNull(offsets[5]),
    deliveryLivreurId: reader.readLongOrNull(offsets[6]),
    deliveryLivreurName: reader.readStringOrNull(offsets[7]),
    deliveryLivreurPhone: reader.readStringOrNull(offsets[8]),
    discountAmount: reader.readDoubleOrNull(offsets[9]) ?? 0.0,
    fulfillmentType: reader.readString(offsets[10]),
    hasDiscount: reader.readBoolOrNull(offsets[11]) ?? false,
    id: id,
    isDailySynced: reader.readBoolOrNull(offsets[12]) ?? false,
    isFromApi: reader.readBoolOrNull(offsets[13]) ?? false,
    isGlovoDelivery: reader.readBoolOrNull(offsets[14]) ?? false,
    note: reader.readStringOrNull(offsets[15]),
    originalTotal: reader.readDoubleOrNull(offsets[16]) ?? 0.0,
    paymentMethod: reader.readStringOrNull(offsets[18]),
    paymentSplit: reader.readStringOrNull(offsets[19]),
    paymentStatus: reader.readStringOrNull(offsets[20]) ?? 'pending',
    restaurantId: reader.readLongOrNull(offsets[21]),
    rewardId: reader.readLongOrNull(offsets[22]),
    sourceLocalId: reader.readLongOrNull(offsets[23]),
    staffId: reader.readLong(offsets[24]),
    status: reader.readStringOrNull(offsets[25]) ?? 'pending',
    tableNumber: reader.readStringOrNull(offsets[26]),
    totalPrice: reader.readDoubleOrNull(offsets[27]) ?? 0.0,
    updatedAt: reader.readDateTime(offsets[28]),
    userId: reader.readLongOrNull(offsets[29]),
  );
  object.paidByStaffId = reader.readLongOrNull(offsets[17]);
  return object;
}

P _posOrderDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset) ?? 'pos') as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 12:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 13:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 14:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 17:
      return (reader.readLongOrNull(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset) ?? 'pending') as P;
    case 21:
      return (reader.readLongOrNull(offset)) as P;
    case 22:
      return (reader.readLongOrNull(offset)) as P;
    case 23:
      return (reader.readLongOrNull(offset)) as P;
    case 24:
      return (reader.readLong(offset)) as P;
    case 25:
      return (reader.readStringOrNull(offset) ?? 'pending') as P;
    case 26:
      return (reader.readStringOrNull(offset)) as P;
    case 27:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 28:
      return (reader.readDateTime(offset)) as P;
    case 29:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _posOrderGetId(PosOrder object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _posOrderGetLinks(PosOrder object) {
  return [];
}

void _posOrderAttach(IsarCollection<dynamic> col, Id id, PosOrder object) {
  object.id = id;
}

extension PosOrderQueryWhereSort on QueryBuilder<PosOrder, PosOrder, QWhere> {
  QueryBuilder<PosOrder, PosOrder, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhere> anySourceLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'sourceLocalId'),
      );
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhere> anyIsFromApi() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isFromApi'),
      );
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhere> anyIsDailySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isDailySynced'),
      );
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhere> anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }
}

extension PosOrderQueryWhere on QueryBuilder<PosOrder, PosOrder, QWhereClause> {
  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> idBetween(
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

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> sourceLocalIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sourceLocalId',
        value: [null],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> sourceLocalIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sourceLocalId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> sourceLocalIdEqualTo(
      int? sourceLocalId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'sourceLocalId',
        value: [sourceLocalId],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> sourceLocalIdNotEqualTo(
      int? sourceLocalId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceLocalId',
              lower: [],
              upper: [sourceLocalId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceLocalId',
              lower: [sourceLocalId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceLocalId',
              lower: [sourceLocalId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'sourceLocalId',
              lower: [],
              upper: [sourceLocalId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> sourceLocalIdGreaterThan(
    int? sourceLocalId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sourceLocalId',
        lower: [sourceLocalId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> sourceLocalIdLessThan(
    int? sourceLocalId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sourceLocalId',
        lower: [],
        upper: [sourceLocalId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> sourceLocalIdBetween(
    int? lowerSourceLocalId,
    int? upperSourceLocalId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'sourceLocalId',
        lower: [lowerSourceLocalId],
        includeLower: includeLower,
        upper: [upperSourceLocalId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> channelEqualTo(
      String channel) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'channel',
        value: [channel],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> channelNotEqualTo(
      String channel) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'channel',
              lower: [],
              upper: [channel],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'channel',
              lower: [channel],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'channel',
              lower: [channel],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'channel',
              lower: [],
              upper: [channel],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> isFromApiEqualTo(
      bool isFromApi) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isFromApi',
        value: [isFromApi],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> isFromApiNotEqualTo(
      bool isFromApi) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isFromApi',
              lower: [],
              upper: [isFromApi],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isFromApi',
              lower: [isFromApi],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isFromApi',
              lower: [isFromApi],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isFromApi',
              lower: [],
              upper: [isFromApi],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> statusEqualTo(
      String status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'status',
        value: [status],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> statusNotEqualTo(
      String status) {
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

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> paymentStatusEqualTo(
      String paymentStatus) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'paymentStatus',
        value: [paymentStatus],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> paymentStatusNotEqualTo(
      String paymentStatus) {
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

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> customerPhoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'customerPhone',
        value: [null],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> customerPhoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'customerPhone',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> customerPhoneEqualTo(
      String? customerPhone) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'customerPhone',
        value: [customerPhone],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> customerPhoneNotEqualTo(
      String? customerPhone) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customerPhone',
              lower: [],
              upper: [customerPhone],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customerPhone',
              lower: [customerPhone],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customerPhone',
              lower: [customerPhone],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customerPhone',
              lower: [],
              upper: [customerPhone],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> isDailySyncedEqualTo(
      bool isDailySynced) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isDailySynced',
        value: [isDailySynced],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> isDailySyncedNotEqualTo(
      bool isDailySynced) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDailySynced',
              lower: [],
              upper: [isDailySynced],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDailySynced',
              lower: [isDailySynced],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDailySynced',
              lower: [isDailySynced],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDailySynced',
              lower: [],
              upper: [isDailySynced],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> createdAtEqualTo(
      DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'createdAt',
        value: [createdAt],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> createdAtNotEqualTo(
      DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [createdAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'createdAt',
              lower: [],
              upper: [createdAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [createdAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [],
        upper: [createdAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'createdAt',
        lower: [lowerCreatedAt],
        includeLower: includeLower,
        upper: [upperCreatedAt],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> updatedAtEqualTo(
      DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAt',
        value: [updatedAt],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> updatedAtNotEqualTo(
      DateTime updatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> updatedAtGreaterThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [updatedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> updatedAtLessThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [],
        upper: [updatedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterWhereClause> updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [lowerUpdatedAt],
        includeLower: includeLower,
        upper: [upperUpdatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PosOrderQueryFilter
    on QueryBuilder<PosOrder, PosOrder, QFilterCondition> {
  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> cancelReasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cancelReason',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      cancelReasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cancelReason',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> cancelReasonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cancelReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      cancelReasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cancelReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> cancelReasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cancelReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> cancelReasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cancelReason',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      cancelReasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cancelReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> cancelReasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cancelReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> cancelReasonContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cancelReason',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> cancelReasonMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cancelReason',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      cancelReasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cancelReason',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      cancelReasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cancelReason',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> channelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'channel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> channelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'channel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> channelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'channel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> channelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'channel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> channelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'channel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> channelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'channel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> channelContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'channel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> channelMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'channel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> channelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'channel',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> channelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'channel',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customerName',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      customerNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customerName',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      customerNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customerName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      customerNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customerName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customerName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      customerNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerName',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      customerNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customerName',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      customerPhoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customerPhone',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      customerPhoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customerPhone',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerPhoneEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      customerPhoneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customerPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerPhoneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customerPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerPhoneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customerPhone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      customerPhoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customerPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerPhoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customerPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerPhoneContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customerPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> customerPhoneMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customerPhone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      customerPhoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customerPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      customerPhoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customerPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryAddressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deliveryAddress',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryAddressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deliveryAddress',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryAddressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deliveryAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryAddressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deliveryAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryAddressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deliveryAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryAddressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deliveryAddress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryAddressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deliveryAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryAddressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deliveryAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryAddressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deliveryAddress',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryAddressMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deliveryAddress',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deliveryAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deliveryAddress',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deliveryLivreurId',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deliveryLivreurId',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deliveryLivreurId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deliveryLivreurId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deliveryLivreurId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deliveryLivreurId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deliveryLivreurName',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deliveryLivreurName',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deliveryLivreurName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deliveryLivreurName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deliveryLivreurName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deliveryLivreurName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deliveryLivreurName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deliveryLivreurName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deliveryLivreurName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deliveryLivreurName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deliveryLivreurName',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deliveryLivreurName',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurPhoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deliveryLivreurPhone',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurPhoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deliveryLivreurPhone',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurPhoneEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deliveryLivreurPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurPhoneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deliveryLivreurPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurPhoneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deliveryLivreurPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurPhoneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deliveryLivreurPhone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurPhoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deliveryLivreurPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurPhoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deliveryLivreurPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurPhoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deliveryLivreurPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurPhoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deliveryLivreurPhone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurPhoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deliveryLivreurPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      deliveryLivreurPhoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deliveryLivreurPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> discountAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'discountAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      discountAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'discountAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      discountAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'discountAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> discountAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'discountAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      fulfillmentTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fulfillmentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      fulfillmentTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fulfillmentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      fulfillmentTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fulfillmentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      fulfillmentTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fulfillmentType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      fulfillmentTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fulfillmentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      fulfillmentTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fulfillmentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      fulfillmentTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fulfillmentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      fulfillmentTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fulfillmentType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      fulfillmentTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fulfillmentType',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      fulfillmentTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fulfillmentType',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> hasDiscountEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasDiscount',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> isDailySyncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDailySynced',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> isFromApiEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFromApi',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      isGlovoDeliveryEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isGlovoDelivery',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> noteEqualTo(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> noteGreaterThan(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> noteLessThan(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> noteBetween(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> noteStartsWith(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> noteEndsWith(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> noteContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> noteMatches(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> originalTotalEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      originalTotalGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> originalTotalLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalTotal',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> originalTotalBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalTotal',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paidByStaffIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paidByStaffId',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paidByStaffIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paidByStaffId',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paidByStaffIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paidByStaffId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paidByStaffIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paidByStaffId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paidByStaffIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paidByStaffId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paidByStaffIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paidByStaffId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentMethodIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentMethod',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentMethodIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentMethod',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentMethodEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentMethodGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentMethodLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentMethodBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentMethod',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentMethodStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paymentMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentMethodEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paymentMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentMethodContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentMethod',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentMethodMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentMethod',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentMethodIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentMethod',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentMethodIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentMethod',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentSplitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paymentSplit',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentSplitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paymentSplit',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentSplitEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentSplit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentSplitGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paymentSplit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentSplitLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paymentSplit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentSplitBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paymentSplit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentSplitStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'paymentSplit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentSplitEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'paymentSplit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentSplitContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentSplit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentSplitMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentSplit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentSplitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentSplit',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentSplitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentSplit',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentStatusEqualTo(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentStatusLessThan(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentStatusBetween(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentStatusEndsWith(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentStatusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'paymentStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> paymentStatusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'paymentStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paymentStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      paymentStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'paymentStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> restaurantIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'restaurantId',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      restaurantIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'restaurantId',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> restaurantIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'restaurantId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> restaurantIdLessThan(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> restaurantIdBetween(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> rewardIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'rewardId',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> rewardIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'rewardId',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> rewardIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rewardId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> rewardIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rewardId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> rewardIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rewardId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> rewardIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rewardId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      sourceLocalIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sourceLocalId',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      sourceLocalIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sourceLocalId',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> sourceLocalIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sourceLocalId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      sourceLocalIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sourceLocalId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> sourceLocalIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sourceLocalId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> sourceLocalIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sourceLocalId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> staffIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'staffId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> staffIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'staffId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> staffIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'staffId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> staffIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'staffId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> statusEqualTo(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> statusGreaterThan(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> statusLessThan(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> statusBetween(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> statusStartsWith(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> statusEndsWith(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> statusContains(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> statusMatches(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> tableNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tableNumber',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      tableNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tableNumber',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> tableNumberEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tableNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      tableNumberGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tableNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> tableNumberLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tableNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> tableNumberBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tableNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> tableNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tableNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> tableNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tableNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> tableNumberContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tableNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> tableNumberMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tableNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> tableNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tableNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition>
      tableNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tableNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> totalPriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> totalPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> totalPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> totalPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> updatedAtBetween(
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

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userId',
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> userIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> userIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> userIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
      ));
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterFilterCondition> userIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension PosOrderQueryObject
    on QueryBuilder<PosOrder, PosOrder, QFilterCondition> {}

extension PosOrderQueryLinks
    on QueryBuilder<PosOrder, PosOrder, QFilterCondition> {}

extension PosOrderQuerySortBy on QueryBuilder<PosOrder, PosOrder, QSortBy> {
  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByCancelReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelReason', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByCancelReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelReason', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByChannel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'channel', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByChannelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'channel', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByCustomerPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerPhone', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByCustomerPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerPhone', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByDeliveryAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryAddress', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByDeliveryAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryAddress', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByDeliveryLivreurId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryLivreurId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByDeliveryLivreurIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryLivreurId', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByDeliveryLivreurName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryLivreurName', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy>
      sortByDeliveryLivreurNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryLivreurName', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByDeliveryLivreurPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryLivreurPhone', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy>
      sortByDeliveryLivreurPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryLivreurPhone', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByFulfillmentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fulfillmentType', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByFulfillmentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fulfillmentType', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByHasDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasDiscount', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByHasDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasDiscount', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByIsDailySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDailySynced', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByIsDailySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDailySynced', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByIsFromApi() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFromApi', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByIsFromApiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFromApi', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByIsGlovoDelivery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGlovoDelivery', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByIsGlovoDeliveryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGlovoDelivery', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByOriginalTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalTotal', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByOriginalTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalTotal', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByPaidByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidByStaffId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByPaidByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidByStaffId', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByPaymentSplit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentSplit', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByPaymentSplitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentSplit', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByPaymentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByPaymentStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByRestaurantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restaurantId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByRestaurantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restaurantId', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByRewardId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByRewardIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardId', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortBySourceLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLocalId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortBySourceLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLocalId', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByTableNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableNumber', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByTableNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableNumber', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByTotalPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPrice', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByTotalPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPrice', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension PosOrderQuerySortThenBy
    on QueryBuilder<PosOrder, PosOrder, QSortThenBy> {
  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByCancelReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelReason', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByCancelReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cancelReason', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByChannel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'channel', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByChannelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'channel', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByCustomerName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByCustomerNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerName', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByCustomerPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerPhone', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByCustomerPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customerPhone', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByDeliveryAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryAddress', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByDeliveryAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryAddress', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByDeliveryLivreurId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryLivreurId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByDeliveryLivreurIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryLivreurId', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByDeliveryLivreurName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryLivreurName', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy>
      thenByDeliveryLivreurNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryLivreurName', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByDeliveryLivreurPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryLivreurPhone', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy>
      thenByDeliveryLivreurPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deliveryLivreurPhone', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByDiscountAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'discountAmount', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByFulfillmentType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fulfillmentType', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByFulfillmentTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fulfillmentType', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByHasDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasDiscount', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByHasDiscountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasDiscount', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByIsDailySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDailySynced', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByIsDailySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDailySynced', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByIsFromApi() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFromApi', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByIsFromApiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFromApi', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByIsGlovoDelivery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGlovoDelivery', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByIsGlovoDeliveryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isGlovoDelivery', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByOriginalTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalTotal', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByOriginalTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalTotal', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByPaidByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidByStaffId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByPaidByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paidByStaffId', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByPaymentMethod() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByPaymentMethodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentMethod', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByPaymentSplit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentSplit', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByPaymentSplitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentSplit', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByPaymentStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByPaymentStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paymentStatus', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByRestaurantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restaurantId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByRestaurantIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restaurantId', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByRewardId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByRewardIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rewardId', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenBySourceLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLocalId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenBySourceLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceLocalId', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByStaffIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'staffId', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByTableNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableNumber', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByTableNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tableNumber', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByTotalPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPrice', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByTotalPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPrice', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension PosOrderQueryWhereDistinct
    on QueryBuilder<PosOrder, PosOrder, QDistinct> {
  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByCancelReason(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cancelReason', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByChannel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'channel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByCustomerName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByCustomerPhone(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customerPhone',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByDeliveryAddress(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deliveryAddress',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByDeliveryLivreurId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deliveryLivreurId');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByDeliveryLivreurName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deliveryLivreurName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByDeliveryLivreurPhone(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deliveryLivreurPhone',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByDiscountAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'discountAmount');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByFulfillmentType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fulfillmentType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByHasDiscount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasDiscount');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByIsDailySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDailySynced');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByIsFromApi() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFromApi');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByIsGlovoDelivery() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isGlovoDelivery');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByOriginalTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalTotal');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByPaidByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paidByStaffId');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByPaymentMethod(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentMethod',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByPaymentSplit(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentSplit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByPaymentStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paymentStatus',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByRestaurantId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'restaurantId');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByRewardId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rewardId');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctBySourceLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceLocalId');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByStaffId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'staffId');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByTableNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tableNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByTotalPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalPrice');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<PosOrder, PosOrder, QDistinct> distinctByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId');
    });
  }
}

extension PosOrderQueryProperty
    on QueryBuilder<PosOrder, PosOrder, QQueryProperty> {
  QueryBuilder<PosOrder, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PosOrder, String?, QQueryOperations> cancelReasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cancelReason');
    });
  }

  QueryBuilder<PosOrder, String, QQueryOperations> channelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'channel');
    });
  }

  QueryBuilder<PosOrder, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PosOrder, String?, QQueryOperations> customerNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerName');
    });
  }

  QueryBuilder<PosOrder, String?, QQueryOperations> customerPhoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customerPhone');
    });
  }

  QueryBuilder<PosOrder, String?, QQueryOperations> deliveryAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deliveryAddress');
    });
  }

  QueryBuilder<PosOrder, int?, QQueryOperations> deliveryLivreurIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deliveryLivreurId');
    });
  }

  QueryBuilder<PosOrder, String?, QQueryOperations>
      deliveryLivreurNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deliveryLivreurName');
    });
  }

  QueryBuilder<PosOrder, String?, QQueryOperations>
      deliveryLivreurPhoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deliveryLivreurPhone');
    });
  }

  QueryBuilder<PosOrder, double, QQueryOperations> discountAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'discountAmount');
    });
  }

  QueryBuilder<PosOrder, String, QQueryOperations> fulfillmentTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fulfillmentType');
    });
  }

  QueryBuilder<PosOrder, bool, QQueryOperations> hasDiscountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasDiscount');
    });
  }

  QueryBuilder<PosOrder, bool, QQueryOperations> isDailySyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDailySynced');
    });
  }

  QueryBuilder<PosOrder, bool, QQueryOperations> isFromApiProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFromApi');
    });
  }

  QueryBuilder<PosOrder, bool, QQueryOperations> isGlovoDeliveryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isGlovoDelivery');
    });
  }

  QueryBuilder<PosOrder, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<PosOrder, double, QQueryOperations> originalTotalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalTotal');
    });
  }

  QueryBuilder<PosOrder, int?, QQueryOperations> paidByStaffIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paidByStaffId');
    });
  }

  QueryBuilder<PosOrder, String?, QQueryOperations> paymentMethodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentMethod');
    });
  }

  QueryBuilder<PosOrder, String?, QQueryOperations> paymentSplitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentSplit');
    });
  }

  QueryBuilder<PosOrder, String, QQueryOperations> paymentStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paymentStatus');
    });
  }

  QueryBuilder<PosOrder, int?, QQueryOperations> restaurantIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'restaurantId');
    });
  }

  QueryBuilder<PosOrder, int?, QQueryOperations> rewardIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rewardId');
    });
  }

  QueryBuilder<PosOrder, int?, QQueryOperations> sourceLocalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceLocalId');
    });
  }

  QueryBuilder<PosOrder, int, QQueryOperations> staffIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'staffId');
    });
  }

  QueryBuilder<PosOrder, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<PosOrder, String?, QQueryOperations> tableNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tableNumber');
    });
  }

  QueryBuilder<PosOrder, double, QQueryOperations> totalPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalPrice');
    });
  }

  QueryBuilder<PosOrder, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<PosOrder, int?, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
