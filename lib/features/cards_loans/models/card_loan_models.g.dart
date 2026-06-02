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
    r'cardName': PropertySchema(
      id: 2,
      name: r'cardName',
      type: IsarType.string,
    ),
    r'creditLimit': PropertySchema(
      id: 3,
      name: r'creditLimit',
      type: IsarType.double,
    ),
    r'dueDay': PropertySchema(
      id: 4,
      name: r'dueDay',
      type: IsarType.long,
    ),
    r'last4': PropertySchema(
      id: 5,
      name: r'last4',
      type: IsarType.string,
    ),
    r'statementDay': PropertySchema(
      id: 6,
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
  bytesCount += 3 + object.cardName.length * 3;
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
  writer.writeString(offsets[2], object.cardName);
  writer.writeDouble(offsets[3], object.creditLimit);
  writer.writeLong(offsets[4], object.dueDay);
  writer.writeString(offsets[5], object.last4);
  writer.writeLong(offsets[6], object.statementDay);
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
  object.cardName = reader.readString(offsets[2]);
  object.creditLimit = reader.readDouble(offsets[3]);
  object.dueDay = reader.readLong(offsets[4]);
  object.id = id;
  object.last4 = reader.readString(offsets[5]);
  object.statementDay = reader.readLong(offsets[6]);
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
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
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

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByDueDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dueDay');
    });
  }

  QueryBuilder<CreditCard, CreditCard, QDistinct> distinctByLast4(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'last4', caseSensitive: caseSensitive);
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

  QueryBuilder<CreditCard, int, QQueryOperations> dueDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dueDay');
    });
  }

  QueryBuilder<CreditCard, String, QQueryOperations> last4Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'last4');
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
    r'isLent': PropertySchema(
      id: 5,
      name: r'isLent',
      type: IsarType.bool,
    ),
    r'linkedTransactionId': PropertySchema(
      id: 6,
      name: r'linkedTransactionId',
      type: IsarType.long,
    ),
    r'remainingBalance': PropertySchema(
      id: 7,
      name: r'remainingBalance',
      type: IsarType.double,
    ),
    r'startDate': PropertySchema(
      id: 8,
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
  writer.writeBool(offsets[5], object.isLent);
  writer.writeLong(offsets[6], object.linkedTransactionId);
  writer.writeDouble(offsets[7], object.remainingBalance);
  writer.writeDateTime(offsets[8], object.startDate);
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
  object.isLent = reader.readBool(offsets[5]);
  object.linkedTransactionId = reader.readLongOrNull(offsets[6]);
  object.remainingBalance = reader.readDouble(offsets[7]);
  object.startDate = reader.readDateTime(offsets[8]);
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
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
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
