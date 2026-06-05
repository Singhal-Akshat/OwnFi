// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_loan_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCreditCardCollection on Isar {
  IsarCollection<CreditCard> get creditCards => this.collection();
}

const CreditCardSchema = CollectionSchema(
  name: r'CreditCard',
  id: 687928797046475984,
  properties: {
    r'activeEmis': PropertySchema(
      id: 0,
      name: r'activeEmis',
      type: IsarType.objectList,
      target: r'CreditCardEmi',
    ),
    r'balance': PropertySchema(
      id: 1,
      name: r'balance',
      type: IsarType.double,
    ),
    r'brand': PropertySchema(
      id: 2,
      name: r'brand',
      type: IsarType.string,
    ),
    r'cardName': PropertySchema(
      id: 3,
      name: r'cardName',
      type: IsarType.string,
    ),
    r'creditLimit': PropertySchema(
      id: 4,
      name: r'creditLimit',
      type: IsarType.double,
    ),
    r'currentSpendings': PropertySchema(
      id: 5,
      name: r'currentSpendings',
      type: IsarType.double,
    ),
    r'cvv': PropertySchema(
      id: 6,
      name: r'cvv',
      type: IsarType.string,
    ),
    r'dueDay': PropertySchema(
      id: 7,
      name: r'dueDay',
      type: IsarType.long,
    ),
    r'expiryDate': PropertySchema(
      id: 8,
      name: r'expiryDate',
      type: IsarType.string,
    ),
    r'fullCardNumber': PropertySchema(
      id: 9,
      name: r'fullCardNumber',
      type: IsarType.string,
    ),
    r'imageUrl': PropertySchema(
      id: 10,
      name: r'imageUrl',
      type: IsarType.string,
    ),
    r'last4': PropertySchema(
      id: 11,
      name: r'last4',
      type: IsarType.string,
    ),
    r'statementAmount': PropertySchema(
      id: 12,
      name: r'statementAmount',
      type: IsarType.double,
    ),
    r'statementDay': PropertySchema(
      id: 13,
      name: r'statementDay',
      type: IsarType.long,
    )
  },
  estimateSize: _creditCardEstimateSize,
  serialize: _creditCardSerialize,
  deserialize: _creditCardDeserialize,
  deserializeProp: _creditCardDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {r'CreditCardEmi': CreditCardEmiSchema},
  getId: _creditCardGetId,
  getLinks: _creditCardGetLinks,
  attach: _creditCardAttach,
  version: '3.1.0+1',
);

int _creditCardEstimateSize(
  CreditCard object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.activeEmis.length * 3;
  {
    final offsets = allOffsets[CreditCardEmi]!;
    for (var i = 0; i < object.activeEmis.length; i++) {
      final value = object.activeEmis[i];
      bytesCount +=
          CreditCardEmiSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.brand.length * 3;
  bytesCount += 3 + object.cardName.length * 3;
  bytesCount += 3 + object.cvv.length * 3;
  bytesCount += 3 + object.expiryDate.length * 3;
  bytesCount += 3 + object.fullCardNumber.length * 3;
  bytesCount += 3 + object.imageUrl.length * 3;
  bytesCount += 3 + object.last4.length * 3;
  return bytesCount;
}

void _creditCardSerialize(
  CreditCard object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<CreditCardEmi>(
    offsets[0],
    allOffsets,
    CreditCardEmiSchema.serialize,
    object.activeEmis,
  );
  writer.writeDouble(offsets[1], object.balance);
  writer.writeString(offsets[2], object.brand);
  writer.writeString(offsets[3], object.cardName);
  writer.writeDouble(offsets[4], object.creditLimit);
  writer.writeDouble(offsets[5], object.currentSpendings);
  writer.writeString(offsets[6], object.cvv);
  writer.writeLong(offsets[7], object.dueDay);
  writer.writeString(offsets[8], object.expiryDate);
  writer.writeString(offsets[9], object.fullCardNumber);
  writer.writeString(offsets[10], object.imageUrl);
  writer.writeString(offsets[11], object.last4);
  writer.writeDouble(offsets[12], object.statementAmount);
  writer.writeLong(offsets[13], object.statementDay);
}

CreditCard _creditCardDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CreditCard();
  object.activeEmis = reader.readObjectList<CreditCardEmi>(
        offsets[0],
        CreditCardEmiSchema.deserialize,
        allOffsets,
        CreditCardEmi(),
      ) ??
      [];
  object.balance = reader.readDouble(offsets[1]);
  object.brand = reader.readString(offsets[2]);
  object.cardName = reader.readString(offsets[3]);
  object.creditLimit = reader.readDouble(offsets[4]);
  object.currentSpendings = reader.readDouble(offsets[5]);
  object.cvv = reader.readString(offsets[6]);
  object.dueDay = reader.readLong(offsets[7]);
  object.expiryDate = reader.readString(offsets[8]);
  object.fullCardNumber = reader.readString(offsets[9]);
  object.id = id;
  object.imageUrl = reader.readString(offsets[10]);
  object.last4 = reader.readString(offsets[11]);
  object.statementAmount = reader.readDouble(offsets[12]);
  object.statementDay = reader.readLong(offsets[13]);
  return object;
}

P _creditCardDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<CreditCardEmi>(
            offset,
            CreditCardEmiSchema.deserialize,
            allOffsets,
            CreditCardEmi(),
          ) ??
          []) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _creditCardGetId(CreditCard object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _creditCardGetLinks(CreditCard object) {
  return [];
}

void _creditCardAttach(IsarCollection<dynamic> col, Id id, CreditCard object) {
  object.id = id;
}

extension CreditCardQueryWhereSort
    on QueryBuilder<CreditCard, CreditCard, QWhere> {
  QueryBuilder<CreditCard, CreditCard, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CreditCardQueryWhere
    on QueryBuilder<CreditCard, CreditCard, QWhereClause> {
  QueryBuilder<CreditCard, CreditCard, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<CreditCard, CreditCard, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterWhereClause> idBetween(
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

extension CreditCardQueryFilter
    on QueryBuilder<CreditCard, CreditCard, QFilterCondition> {
  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      activeEmisLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeEmis',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      activeEmisIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeEmis',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      activeEmisIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeEmis',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      activeEmisLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeEmis',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      activeEmisLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeEmis',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      activeEmisLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'activeEmis',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> balanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      balanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> balanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> balanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'balance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> brandEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> brandGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> brandLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> brandBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'brand',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> brandStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> brandEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> brandContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'brand',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> brandMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'brand',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> brandIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'brand',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      brandIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'brand',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cardNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cardName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      cardNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cardName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cardNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cardName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cardNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cardName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      cardNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cardName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cardNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cardName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cardNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cardName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cardNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cardName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      cardNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cardName',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      cardNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cardName',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      creditLimitEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'creditLimit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      creditLimitGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'creditLimit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      creditLimitLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'creditLimit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      creditLimitBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'creditLimit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      currentSpendingsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentSpendings',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      currentSpendingsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentSpendings',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      currentSpendingsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentSpendings',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      currentSpendingsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentSpendings',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cvvEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cvv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cvvGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cvv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cvvLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cvv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cvvBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cvv',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cvvStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cvv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cvvEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cvv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cvvContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cvv',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cvvMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cvv',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cvvIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cvv',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> cvvIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cvv',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> dueDayEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dueDay',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> dueDayGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dueDay',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> dueDayLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dueDay',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> dueDayBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dueDay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> expiryDateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expiryDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      expiryDateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expiryDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      expiryDateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expiryDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> expiryDateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expiryDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      expiryDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'expiryDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      expiryDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'expiryDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      expiryDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'expiryDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> expiryDateMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'expiryDate',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      expiryDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expiryDate',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      expiryDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'expiryDate',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      fullCardNumberEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fullCardNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      fullCardNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fullCardNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      fullCardNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fullCardNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      fullCardNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fullCardNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      fullCardNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fullCardNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      fullCardNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fullCardNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      fullCardNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fullCardNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      fullCardNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fullCardNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      fullCardNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fullCardNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      fullCardNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fullCardNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> imageUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      imageUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> imageUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> imageUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imageUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      imageUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> imageUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> imageUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> imageUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imageUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      imageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      imageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> last4EqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'last4',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> last4GreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'last4',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> last4LessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'last4',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> last4Between(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'last4',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> last4StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'last4',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> last4EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'last4',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> last4Contains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'last4',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> last4Matches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'last4',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> last4IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'last4',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      last4IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'last4',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      statementAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statementAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      statementAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statementAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      statementAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statementAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      statementAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statementAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      statementDayEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'statementDay',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      statementDayGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'statementDay',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      statementDayLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'statementDay',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition>
      statementDayBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'statementDay',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CreditCardQueryObject
    on QueryBuilder<CreditCard, CreditCard, QFilterCondition> {
  QueryBuilder<CreditCard, CreditCard, QAfterFilterCondition> activeEmisElement(
      FilterQuery<CreditCardEmi> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'activeEmis');
    });
  }
}

extension CreditCardQueryLinks
    on QueryBuilder<CreditCard, CreditCard, QFilterCondition> {}

extension CreditCardQuerySortBy
    on QueryBuilder<CreditCard, CreditCard, QSortBy> {
  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByBrand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brand', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByBrandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brand', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByCardName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardName', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByCardNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardName', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByCreditLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditLimit', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByCreditLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditLimit', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByCurrentSpendings() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentSpendings', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy>
      sortByCurrentSpendingsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentSpendings', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByCvv() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cvv', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByCvvDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cvv', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByDueDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDay', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByDueDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDay', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByExpiryDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByFullCardNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullCardNumber', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy>
      sortByFullCardNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullCardNumber', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByLast4() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'last4', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByLast4Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'last4', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByStatementAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statementAmount', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy>
      sortByStatementAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statementAmount', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByStatementDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statementDay', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> sortByStatementDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statementDay', Sort.desc);
    });
  }
}

extension CreditCardQuerySortThenBy
    on QueryBuilder<CreditCard, CreditCard, QSortThenBy> {
  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByBrand() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brand', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByBrandDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'brand', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByCardName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardName', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByCardNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cardName', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByCreditLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditLimit', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByCreditLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'creditLimit', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByCurrentSpendings() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentSpendings', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy>
      thenByCurrentSpendingsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentSpendings', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByCvv() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cvv', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByCvvDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cvv', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByDueDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDay', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByDueDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDay', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByExpiryDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByFullCardNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullCardNumber', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy>
      thenByFullCardNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullCardNumber', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByLast4() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'last4', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByLast4Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'last4', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByStatementAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statementAmount', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy>
      thenByStatementAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statementAmount', Sort.desc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByStatementDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statementDay', Sort.asc);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QAfterSortBy> thenByStatementDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'statementDay', Sort.desc);
    });
  }
}

extension CreditCardQueryWhereDistinct
    on QueryBuilder<CreditCard, CreditCard, QDistinct> {
  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balance');
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByBrand(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'brand', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByCardName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cardName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByCreditLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'creditLimit');
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByCurrentSpendings() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentSpendings');
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByCvv(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cvv', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByDueDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dueDay');
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByExpiryDate(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiryDate', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByFullCardNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fullCardNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByImageUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByLast4(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'last4', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByStatementAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statementAmount');
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByStatementDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'statementDay');
    });
  }
}

extension CreditCardQueryProperty
    on QueryBuilder<CreditCard, CreditCard, QQueryProperty> {
  QueryBuilder<CreditCard, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CreditCard, List<CreditCardEmi>, QQueryOperations>
      activeEmisProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activeEmis');
    });
  }

  QueryBuilder<CreditCard, double, QQueryOperations> balanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balance');
    });
  }

  QueryBuilder<CreditCard, String, QQueryOperations> brandProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'brand');
    });
  }

  QueryBuilder<CreditCard, String, QQueryOperations> cardNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cardName');
    });
  }

  QueryBuilder<CreditCard, double, QQueryOperations> creditLimitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'creditLimit');
    });
  }

  QueryBuilder<CreditCard, double, QQueryOperations>
      currentSpendingsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentSpendings');
    });
  }

  QueryBuilder<CreditCard, String, QQueryOperations> cvvProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cvv');
    });
  }

  QueryBuilder<CreditCard, int, QQueryOperations> dueDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dueDay');
    });
  }

  QueryBuilder<CreditCard, String, QQueryOperations> expiryDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiryDate');
    });
  }

  QueryBuilder<CreditCard, String, QQueryOperations> fullCardNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fullCardNumber');
    });
  }

  QueryBuilder<CreditCard, String, QQueryOperations> imageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageUrl');
    });
  }

  QueryBuilder<CreditCard, String, QQueryOperations> last4Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'last4');
    });
  }

  QueryBuilder<CreditCard, double, QQueryOperations> statementAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statementAmount');
    });
  }

  QueryBuilder<CreditCard, int, QQueryOperations> statementDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'statementDay');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLoanCollection on Isar {
  IsarCollection<Loan> get loans => this.collection();
}

const LoanSchema = CollectionSchema(
  name: r'Loan',
  id: 3165146227223573679,
  properties: {
    r'amount': PropertySchema(
      id: 0,
      name: r'amount',
      type: IsarType.double,
    ),
    r'compoundInterval': PropertySchema(
      id: 1,
      name: r'compoundInterval',
      type: IsarType.string,
    ),
    r'contactName': PropertySchema(
      id: 2,
      name: r'contactName',
      type: IsarType.string,
    ),
    r'emiAmount': PropertySchema(
      id: 3,
      name: r'emiAmount',
      type: IsarType.double,
    ),
    r'interestRate': PropertySchema(
      id: 4,
      name: r'interestRate',
      type: IsarType.double,
    ),
    r'isCompleted': PropertySchema(
      id: 5,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'isLent': PropertySchema(
      id: 6,
      name: r'isLent',
      type: IsarType.bool,
    ),
    r'linkedTransactionId': PropertySchema(
      id: 7,
      name: r'linkedTransactionId',
      type: IsarType.long,
    ),
    r'paybackDate': PropertySchema(
      id: 8,
      name: r'paybackDate',
      type: IsarType.dateTime,
    ),
    r'remainingBalance': PropertySchema(
      id: 9,
      name: r'remainingBalance',
      type: IsarType.double,
    ),
    r'startDate': PropertySchema(
      id: 10,
      name: r'startDate',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _loanEstimateSize,
  serialize: _loanSerialize,
  deserialize: _loanDeserialize,
  deserializeProp: _loanDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _loanGetId,
  getLinks: _loanGetLinks,
  attach: _loanAttach,
  version: '3.1.0+1',
);

int _loanEstimateSize(
  Loan object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.compoundInterval.length * 3;
  bytesCount += 3 + object.contactName.length * 3;
  return bytesCount;
}

void _loanSerialize(
  Loan object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.amount);
  writer.writeString(offsets[1], object.compoundInterval);
  writer.writeString(offsets[2], object.contactName);
  writer.writeDouble(offsets[3], object.emiAmount);
  writer.writeDouble(offsets[4], object.interestRate);
  writer.writeBool(offsets[5], object.isCompleted);
  writer.writeBool(offsets[6], object.isLent);
  writer.writeLong(offsets[7], object.linkedTransactionId);
  writer.writeDateTime(offsets[8], object.paybackDate);
  writer.writeDouble(offsets[9], object.remainingBalance);
  writer.writeDateTime(offsets[10], object.startDate);
}

Loan _loanDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Loan();
  object.amount = reader.readDouble(offsets[0]);
  object.compoundInterval = reader.readString(offsets[1]);
  object.contactName = reader.readString(offsets[2]);
  object.emiAmount = reader.readDouble(offsets[3]);
  object.id = id;
  object.interestRate = reader.readDouble(offsets[4]);
  object.isCompleted = reader.readBool(offsets[5]);
  object.isLent = reader.readBool(offsets[6]);
  object.linkedTransactionId = reader.readLongOrNull(offsets[7]);
  object.paybackDate = reader.readDateTimeOrNull(offsets[8]);
  object.remainingBalance = reader.readDouble(offsets[9]);
  object.startDate = reader.readDateTime(offsets[10]);
  return object;
}

P _loanDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _loanGetId(Loan object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _loanGetLinks(Loan object) {
  return [];
}

void _loanAttach(IsarCollection<dynamic> col, Id id, Loan object) {
  object.id = id;
}

extension LoanQueryWhereSort on QueryBuilder<Loan, Loan, QWhere> {
  QueryBuilder<Loan, Loan, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LoanQueryWhere on QueryBuilder<Loan, Loan, QWhereClause> {
  QueryBuilder<Loan, Loan, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Loan, Loan, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Loan, Loan, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Loan, Loan, QAfterWhereClause> idBetween(
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

extension LoanQueryFilter on QueryBuilder<Loan, Loan, QFilterCondition> {
  QueryBuilder<Loan, Loan, QAfterFilterCondition> amountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> amountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> amountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'amount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> amountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'amount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> compoundIntervalEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'compoundInterval',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> compoundIntervalGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'compoundInterval',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> compoundIntervalLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'compoundInterval',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> compoundIntervalBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'compoundInterval',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> compoundIntervalStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'compoundInterval',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> compoundIntervalEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'compoundInterval',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> compoundIntervalContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'compoundInterval',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> compoundIntervalMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'compoundInterval',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> compoundIntervalIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'compoundInterval',
        value: '',
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> compoundIntervalIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'compoundInterval',
        value: '',
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> contactNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> contactNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contactName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> contactNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contactName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> contactNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contactName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> contactNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contactName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> contactNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contactName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> contactNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contactName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> contactNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contactName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> contactNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contactName',
        value: '',
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> contactNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contactName',
        value: '',
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> emiAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emiAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> emiAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'emiAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> emiAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'emiAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> emiAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'emiAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Loan, Loan, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Loan, Loan, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Loan, Loan, QAfterFilterCondition> interestRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'interestRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> interestRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'interestRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> interestRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'interestRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> interestRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'interestRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> isCompletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> isLentEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLent',
        value: value,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> linkedTransactionIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'linkedTransactionId',
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition>
      linkedTransactionIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'linkedTransactionId',
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> linkedTransactionIdEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linkedTransactionId',
        value: value,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition>
      linkedTransactionIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'linkedTransactionId',
        value: value,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> linkedTransactionIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'linkedTransactionId',
        value: value,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> linkedTransactionIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'linkedTransactionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> paybackDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'paybackDate',
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> paybackDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'paybackDate',
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> paybackDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'paybackDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> paybackDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'paybackDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> paybackDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'paybackDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> paybackDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'paybackDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> remainingBalanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainingBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> remainingBalanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remainingBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> remainingBalanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remainingBalance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> remainingBalanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remainingBalance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> startDateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> startDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> startDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Loan, Loan, QAfterFilterCondition> startDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LoanQueryObject on QueryBuilder<Loan, Loan, QFilterCondition> {}

extension LoanQueryLinks on QueryBuilder<Loan, Loan, QFilterCondition> {}

extension LoanQuerySortBy on QueryBuilder<Loan, Loan, QSortBy> {
  QueryBuilder<Loan, Loan, QAfterSortBy> sortByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByCompoundInterval() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compoundInterval', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByCompoundIntervalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compoundInterval', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByContactName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactName', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByContactNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactName', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByEmiAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emiAmount', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByEmiAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emiAmount', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByInterestRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interestRate', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByInterestRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interestRate', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByIsLent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLent', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByIsLentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLent', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByLinkedTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedTransactionId', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByLinkedTransactionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedTransactionId', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByPaybackDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paybackDate', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByPaybackDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paybackDate', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByRemainingBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingBalance', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByRemainingBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingBalance', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }
}

extension LoanQuerySortThenBy on QueryBuilder<Loan, Loan, QSortThenBy> {
  QueryBuilder<Loan, Loan, QAfterSortBy> thenByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'amount', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByCompoundInterval() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compoundInterval', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByCompoundIntervalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'compoundInterval', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByContactName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactName', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByContactNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contactName', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByEmiAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emiAmount', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByEmiAmountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'emiAmount', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByInterestRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interestRate', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByInterestRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'interestRate', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByIsLent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLent', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByIsLentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLent', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByLinkedTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedTransactionId', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByLinkedTransactionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'linkedTransactionId', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByPaybackDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paybackDate', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByPaybackDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paybackDate', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByRemainingBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingBalance', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByRemainingBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remainingBalance', Sort.desc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<Loan, Loan, QAfterSortBy> thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }
}

extension LoanQueryWhereDistinct on QueryBuilder<Loan, Loan, QDistinct> {
  QueryBuilder<Loan, Loan, QDistinct> distinctByAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'amount');
    });
  }

  QueryBuilder<Loan, Loan, QDistinct> distinctByCompoundInterval(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'compoundInterval',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Loan, Loan, QDistinct> distinctByContactName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contactName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Loan, Loan, QDistinct> distinctByEmiAmount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'emiAmount');
    });
  }

  QueryBuilder<Loan, Loan, QDistinct> distinctByInterestRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'interestRate');
    });
  }

  QueryBuilder<Loan, Loan, QDistinct> distinctByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCompleted');
    });
  }

  QueryBuilder<Loan, Loan, QDistinct> distinctByIsLent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLent');
    });
  }

  QueryBuilder<Loan, Loan, QDistinct> distinctByLinkedTransactionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'linkedTransactionId');
    });
  }

  QueryBuilder<Loan, Loan, QDistinct> distinctByPaybackDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paybackDate');
    });
  }

  QueryBuilder<Loan, Loan, QDistinct> distinctByRemainingBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remainingBalance');
    });
  }

  QueryBuilder<Loan, Loan, QDistinct> distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }
}

extension LoanQueryProperty on QueryBuilder<Loan, Loan, QQueryProperty> {
  QueryBuilder<Loan, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Loan, double, QQueryOperations> amountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'amount');
    });
  }

  QueryBuilder<Loan, String, QQueryOperations> compoundIntervalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'compoundInterval');
    });
  }

  QueryBuilder<Loan, String, QQueryOperations> contactNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contactName');
    });
  }

  QueryBuilder<Loan, double, QQueryOperations> emiAmountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'emiAmount');
    });
  }

  QueryBuilder<Loan, double, QQueryOperations> interestRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'interestRate');
    });
  }

  QueryBuilder<Loan, bool, QQueryOperations> isCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCompleted');
    });
  }

  QueryBuilder<Loan, bool, QQueryOperations> isLentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLent');
    });
  }

  QueryBuilder<Loan, int?, QQueryOperations> linkedTransactionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'linkedTransactionId');
    });
  }

  QueryBuilder<Loan, DateTime?, QQueryOperations> paybackDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paybackDate');
    });
  }

  QueryBuilder<Loan, double, QQueryOperations> remainingBalanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remainingBalance');
    });
  }

  QueryBuilder<Loan, DateTime, QQueryOperations> startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBankAccountCollection on Isar {
  IsarCollection<BankAccount> get bankAccounts => this.collection();
}

const BankAccountSchema = CollectionSchema(
  name: r'BankAccount',
  id: 6972968476381051766,
  properties: {
    r'accountHolderName': PropertySchema(
      id: 0,
      name: r'accountHolderName',
      type: IsarType.string,
    ),
    r'balance': PropertySchema(
      id: 1,
      name: r'balance',
      type: IsarType.double,
    ),
    r'bankName': PropertySchema(
      id: 2,
      name: r'bankName',
      type: IsarType.string,
    ),
    r'colorHex': PropertySchema(
      id: 3,
      name: r'colorHex',
      type: IsarType.string,
    ),
    r'fullAccountNumber': PropertySchema(
      id: 4,
      name: r'fullAccountNumber',
      type: IsarType.string,
    ),
    r'ifscCode': PropertySchema(
      id: 5,
      name: r'ifscCode',
      type: IsarType.string,
    ),
    r'last4': PropertySchema(
      id: 6,
      name: r'last4',
      type: IsarType.string,
    ),
    r'logoAsset': PropertySchema(
      id: 7,
      name: r'logoAsset',
      type: IsarType.string,
    )
  },
  estimateSize: _bankAccountEstimateSize,
  serialize: _bankAccountSerialize,
  deserialize: _bankAccountDeserialize,
  deserializeProp: _bankAccountDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _bankAccountGetId,
  getLinks: _bankAccountGetLinks,
  attach: _bankAccountAttach,
  version: '3.1.0+1',
);

int _bankAccountEstimateSize(
  BankAccount object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.accountHolderName.length * 3;
  bytesCount += 3 + object.bankName.length * 3;
  bytesCount += 3 + object.colorHex.length * 3;
  bytesCount += 3 + object.fullAccountNumber.length * 3;
  bytesCount += 3 + object.ifscCode.length * 3;
  bytesCount += 3 + object.last4.length * 3;
  bytesCount += 3 + object.logoAsset.length * 3;
  return bytesCount;
}

void _bankAccountSerialize(
  BankAccount object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accountHolderName);
  writer.writeDouble(offsets[1], object.balance);
  writer.writeString(offsets[2], object.bankName);
  writer.writeString(offsets[3], object.colorHex);
  writer.writeString(offsets[4], object.fullAccountNumber);
  writer.writeString(offsets[5], object.ifscCode);
  writer.writeString(offsets[6], object.last4);
  writer.writeString(offsets[7], object.logoAsset);
}

BankAccount _bankAccountDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BankAccount();
  object.accountHolderName = reader.readString(offsets[0]);
  object.balance = reader.readDouble(offsets[1]);
  object.bankName = reader.readString(offsets[2]);
  object.colorHex = reader.readString(offsets[3]);
  object.fullAccountNumber = reader.readString(offsets[4]);
  object.id = id;
  object.ifscCode = reader.readString(offsets[5]);
  object.last4 = reader.readString(offsets[6]);
  object.logoAsset = reader.readString(offsets[7]);
  return object;
}

P _bankAccountDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _bankAccountGetId(BankAccount object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _bankAccountGetLinks(BankAccount object) {
  return [];
}

void _bankAccountAttach(
    IsarCollection<dynamic> col, Id id, BankAccount object) {
  object.id = id;
}

extension BankAccountQueryWhereSort
    on QueryBuilder<BankAccount, BankAccount, QWhere> {
  QueryBuilder<BankAccount, BankAccount, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BankAccountQueryWhere
    on QueryBuilder<BankAccount, BankAccount, QWhereClause> {
  QueryBuilder<BankAccount, BankAccount, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<BankAccount, BankAccount, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterWhereClause> idBetween(
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

extension BankAccountQueryFilter
    on QueryBuilder<BankAccount, BankAccount, QFilterCondition> {
  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      accountHolderNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountHolderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      accountHolderNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accountHolderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      accountHolderNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accountHolderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      accountHolderNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accountHolderName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      accountHolderNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accountHolderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      accountHolderNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accountHolderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      accountHolderNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accountHolderName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      accountHolderNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accountHolderName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      accountHolderNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accountHolderName',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      accountHolderNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accountHolderName',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> balanceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      balanceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> balanceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'balance',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> balanceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'balance',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> bankNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bankName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      bankNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bankName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      bankNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bankName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> bankNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bankName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      bankNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bankName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      bankNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bankName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      bankNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bankName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> bankNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bankName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      bankNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bankName',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      bankNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bankName',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> colorHexEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      colorHexGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      colorHexLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> colorHexBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorHex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      colorHexStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      colorHexEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      colorHexContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'colorHex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> colorHexMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'colorHex',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      colorHexIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorHex',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      colorHexIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'colorHex',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      fullAccountNumberEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fullAccountNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      fullAccountNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fullAccountNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      fullAccountNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fullAccountNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      fullAccountNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fullAccountNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      fullAccountNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fullAccountNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      fullAccountNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fullAccountNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      fullAccountNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fullAccountNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      fullAccountNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fullAccountNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      fullAccountNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fullAccountNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      fullAccountNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fullAccountNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> idBetween(
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

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> ifscCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ifscCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      ifscCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ifscCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      ifscCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ifscCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> ifscCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ifscCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      ifscCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ifscCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      ifscCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ifscCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      ifscCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ifscCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> ifscCodeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ifscCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      ifscCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ifscCode',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      ifscCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ifscCode',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> last4EqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'last4',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      last4GreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'last4',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> last4LessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'last4',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> last4Between(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'last4',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> last4StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'last4',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> last4EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'last4',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> last4Contains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'last4',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> last4Matches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'last4',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition> last4IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'last4',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      last4IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'last4',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      logoAssetEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logoAsset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      logoAssetGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'logoAsset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      logoAssetLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'logoAsset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      logoAssetBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'logoAsset',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      logoAssetStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'logoAsset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      logoAssetEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'logoAsset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      logoAssetContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'logoAsset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      logoAssetMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'logoAsset',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      logoAssetIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'logoAsset',
        value: '',
      ));
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterFilterCondition>
      logoAssetIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'logoAsset',
        value: '',
      ));
    });
  }
}

extension BankAccountQueryObject
    on QueryBuilder<BankAccount, BankAccount, QFilterCondition> {}

extension BankAccountQueryLinks
    on QueryBuilder<BankAccount, BankAccount, QFilterCondition> {}

extension BankAccountQuerySortBy
    on QueryBuilder<BankAccount, BankAccount, QSortBy> {
  QueryBuilder<BankAccount, BankAccount, QAfterSortBy>
      sortByAccountHolderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountHolderName', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy>
      sortByAccountHolderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountHolderName', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> sortByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> sortByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> sortByBankName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bankName', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> sortByBankNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bankName', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> sortByColorHex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> sortByColorHexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy>
      sortByFullAccountNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullAccountNumber', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy>
      sortByFullAccountNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullAccountNumber', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> sortByIfscCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ifscCode', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> sortByIfscCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ifscCode', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> sortByLast4() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'last4', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> sortByLast4Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'last4', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> sortByLogoAsset() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logoAsset', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> sortByLogoAssetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logoAsset', Sort.desc);
    });
  }
}

extension BankAccountQuerySortThenBy
    on QueryBuilder<BankAccount, BankAccount, QSortThenBy> {
  QueryBuilder<BankAccount, BankAccount, QAfterSortBy>
      thenByAccountHolderName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountHolderName', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy>
      thenByAccountHolderNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountHolderName', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByBalanceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'balance', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByBankName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bankName', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByBankNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bankName', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByColorHex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByColorHexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorHex', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy>
      thenByFullAccountNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullAccountNumber', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy>
      thenByFullAccountNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fullAccountNumber', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByIfscCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ifscCode', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByIfscCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ifscCode', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByLast4() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'last4', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByLast4Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'last4', Sort.desc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByLogoAsset() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logoAsset', Sort.asc);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QAfterSortBy> thenByLogoAssetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'logoAsset', Sort.desc);
    });
  }
}

extension BankAccountQueryWhereDistinct
    on QueryBuilder<BankAccount, BankAccount, QDistinct> {
  QueryBuilder<BankAccount, BankAccount, QDistinct> distinctByAccountHolderName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountHolderName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QDistinct> distinctByBalance() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'balance');
    });
  }

  QueryBuilder<BankAccount, BankAccount, QDistinct> distinctByBankName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bankName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QDistinct> distinctByColorHex(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorHex', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QDistinct> distinctByFullAccountNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fullAccountNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QDistinct> distinctByIfscCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ifscCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QDistinct> distinctByLast4(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'last4', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BankAccount, BankAccount, QDistinct> distinctByLogoAsset(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'logoAsset', caseSensitive: caseSensitive);
    });
  }
}

extension BankAccountQueryProperty
    on QueryBuilder<BankAccount, BankAccount, QQueryProperty> {
  QueryBuilder<BankAccount, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BankAccount, String, QQueryOperations>
      accountHolderNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountHolderName');
    });
  }

  QueryBuilder<BankAccount, double, QQueryOperations> balanceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'balance');
    });
  }

  QueryBuilder<BankAccount, String, QQueryOperations> bankNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bankName');
    });
  }

  QueryBuilder<BankAccount, String, QQueryOperations> colorHexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorHex');
    });
  }

  QueryBuilder<BankAccount, String, QQueryOperations>
      fullAccountNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fullAccountNumber');
    });
  }

  QueryBuilder<BankAccount, String, QQueryOperations> ifscCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ifscCode');
    });
  }

  QueryBuilder<BankAccount, String, QQueryOperations> last4Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'last4');
    });
  }

  QueryBuilder<BankAccount, String, QQueryOperations> logoAssetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'logoAsset');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const CreditCardEmiSchema = Schema(
  name: r'CreditCardEmi',
  id: 1150379802927510382,
  properties: {
    r'description': PropertySchema(
      id: 0,
      name: r'description',
      type: IsarType.string,
    ),
    r'monthlyInstallment': PropertySchema(
      id: 1,
      name: r'monthlyInstallment',
      type: IsarType.double,
    ),
    r'remainingMonths': PropertySchema(
      id: 2,
      name: r'remainingMonths',
      type: IsarType.long,
    ),
    r'startDate': PropertySchema(
      id: 3,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'totalAmount': PropertySchema(
      id: 4,
      name: r'totalAmount',
      type: IsarType.double,
    ),
    r'totalMonths': PropertySchema(
      id: 5,
      name: r'totalMonths',
      type: IsarType.long,
    )
  },
  estimateSize: _creditCardEmiEstimateSize,
  serialize: _creditCardEmiSerialize,
  deserialize: _creditCardEmiDeserialize,
  deserializeProp: _creditCardEmiDeserializeProp,
);

int _creditCardEmiEstimateSize(
  CreditCardEmi object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.description.length * 3;
  return bytesCount;
}

void _creditCardEmiSerialize(
  CreditCardEmi object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.description);
  writer.writeDouble(offsets[1], object.monthlyInstallment);
  writer.writeLong(offsets[2], object.remainingMonths);
  writer.writeDateTime(offsets[3], object.startDate);
  writer.writeDouble(offsets[4], object.totalAmount);
  writer.writeLong(offsets[5], object.totalMonths);
}

CreditCardEmi _creditCardEmiDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CreditCardEmi();
  object.description = reader.readString(offsets[0]);
  object.monthlyInstallment = reader.readDouble(offsets[1]);
  object.remainingMonths = reader.readLong(offsets[2]);
  object.startDate = reader.readDateTime(offsets[3]);
  object.totalAmount = reader.readDouble(offsets[4]);
  object.totalMonths = reader.readLong(offsets[5]);
  return object;
}

P _creditCardEmiDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension CreditCardEmiQueryFilter
    on QueryBuilder<CreditCardEmi, CreditCardEmi, QFilterCondition> {
  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      monthlyInstallmentEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'monthlyInstallment',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      monthlyInstallmentGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'monthlyInstallment',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      monthlyInstallmentLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'monthlyInstallment',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      monthlyInstallmentBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'monthlyInstallment',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      remainingMonthsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remainingMonths',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      remainingMonthsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remainingMonths',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      remainingMonthsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remainingMonths',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      remainingMonthsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remainingMonths',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      startDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      startDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      startDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      startDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      totalAmountEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      totalAmountGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      totalAmountLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalAmount',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      totalAmountBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalAmount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      totalMonthsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalMonths',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      totalMonthsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalMonths',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      totalMonthsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalMonths',
        value: value,
      ));
    });
  }

  QueryBuilder<CreditCardEmi, CreditCardEmi, QAfterFilterCondition>
      totalMonthsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalMonths',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CreditCardEmiQueryObject
    on QueryBuilder<CreditCardEmi, CreditCardEmi, QFilterCondition> {}
