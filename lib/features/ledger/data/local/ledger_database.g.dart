// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMicrosMeta = const VerificationMeta(
    'occurredAtMicros',
  );
  @override
  late final GeneratedColumn<int> occurredAtMicros = GeneratedColumn<int>(
    'occurred_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterpartyMeta = const VerificationMeta(
    'counterparty',
  );
  @override
  late final GeneratedColumn<String> counterparty = GeneratedColumn<String>(
    'counterparty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardLast4Meta = const VerificationMeta(
    'cardLast4',
  );
  @override
  late final GeneratedColumn<String> cardLast4 = GeneratedColumn<String>(
    'card_last4',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailedMeta = const VerificationMeta(
    'detailed',
  );
  @override
  late final GeneratedColumn<bool> detailed = GeneratedColumn<bool>(
    'detailed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("detailed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _openedAtMicrosMeta = const VerificationMeta(
    'openedAtMicros',
  );
  @override
  late final GeneratedColumn<int> openedAtMicros = GeneratedColumn<int>(
    'opened_at_micros',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    description,
    amountCents,
    direction,
    status,
    occurredAtMicros,
    paymentMethod,
    category,
    counterparty,
    searchText,
    cardLast4,
    message,
    detailed,
    openedAtMicros,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('occurred_at_micros')) {
      context.handle(
        _occurredAtMicrosMeta,
        occurredAtMicros.isAcceptableOrUnknown(
          data['occurred_at_micros']!,
          _occurredAtMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMicrosMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('counterparty')) {
      context.handle(
        _counterpartyMeta,
        counterparty.isAcceptableOrUnknown(
          data['counterparty']!,
          _counterpartyMeta,
        ),
      );
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    } else if (isInserting) {
      context.missing(_searchTextMeta);
    }
    if (data.containsKey('card_last4')) {
      context.handle(
        _cardLast4Meta,
        cardLast4.isAcceptableOrUnknown(data['card_last4']!, _cardLast4Meta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('detailed')) {
      context.handle(
        _detailedMeta,
        detailed.isAcceptableOrUnknown(data['detailed']!, _detailedMeta),
      );
    }
    if (data.containsKey('opened_at_micros')) {
      context.handle(
        _openedAtMicrosMeta,
        openedAtMicros.isAcceptableOrUnknown(
          data['opened_at_micros']!,
          _openedAtMicrosMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      occurredAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at_micros'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      counterparty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty'],
      ),
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      cardLast4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_last4'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      detailed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}detailed'],
      )!,
      openedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opened_at_micros'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final String id;
  final String description;
  final int amountCents;

  /// `credit` or `debit`, same vocabulary as the API.
  final String direction;
  final String status;
  final int occurredAtMicros;
  final String paymentMethod;
  final String category;
  final String? counterparty;

  /// Description and counterparty in lower case without accents, so the
  /// search follows the same rules as `SearchText` with a plain LIKE.
  final String searchText;

  /// Filled by the detail endpoint only.
  final String? cardLast4;
  final String? message;
  final bool detailed;

  /// When the detail screen last loaded it, to keep the latest opened.
  final int? openedAtMicros;
  const TransactionRow({
    required this.id,
    required this.description,
    required this.amountCents,
    required this.direction,
    required this.status,
    required this.occurredAtMicros,
    required this.paymentMethod,
    required this.category,
    this.counterparty,
    required this.searchText,
    this.cardLast4,
    this.message,
    required this.detailed,
    this.openedAtMicros,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['description'] = Variable<String>(description);
    map['amount_cents'] = Variable<int>(amountCents);
    map['direction'] = Variable<String>(direction);
    map['status'] = Variable<String>(status);
    map['occurred_at_micros'] = Variable<int>(occurredAtMicros);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || counterparty != null) {
      map['counterparty'] = Variable<String>(counterparty);
    }
    map['search_text'] = Variable<String>(searchText);
    if (!nullToAbsent || cardLast4 != null) {
      map['card_last4'] = Variable<String>(cardLast4);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['detailed'] = Variable<bool>(detailed);
    if (!nullToAbsent || openedAtMicros != null) {
      map['opened_at_micros'] = Variable<int>(openedAtMicros);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      description: Value(description),
      amountCents: Value(amountCents),
      direction: Value(direction),
      status: Value(status),
      occurredAtMicros: Value(occurredAtMicros),
      paymentMethod: Value(paymentMethod),
      category: Value(category),
      counterparty: counterparty == null && nullToAbsent
          ? const Value.absent()
          : Value(counterparty),
      searchText: Value(searchText),
      cardLast4: cardLast4 == null && nullToAbsent
          ? const Value.absent()
          : Value(cardLast4),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      detailed: Value(detailed),
      openedAtMicros: openedAtMicros == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAtMicros),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<String>(json['id']),
      description: serializer.fromJson<String>(json['description']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      direction: serializer.fromJson<String>(json['direction']),
      status: serializer.fromJson<String>(json['status']),
      occurredAtMicros: serializer.fromJson<int>(json['occurredAtMicros']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      category: serializer.fromJson<String>(json['category']),
      counterparty: serializer.fromJson<String?>(json['counterparty']),
      searchText: serializer.fromJson<String>(json['searchText']),
      cardLast4: serializer.fromJson<String?>(json['cardLast4']),
      message: serializer.fromJson<String?>(json['message']),
      detailed: serializer.fromJson<bool>(json['detailed']),
      openedAtMicros: serializer.fromJson<int?>(json['openedAtMicros']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'description': serializer.toJson<String>(description),
      'amountCents': serializer.toJson<int>(amountCents),
      'direction': serializer.toJson<String>(direction),
      'status': serializer.toJson<String>(status),
      'occurredAtMicros': serializer.toJson<int>(occurredAtMicros),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'category': serializer.toJson<String>(category),
      'counterparty': serializer.toJson<String?>(counterparty),
      'searchText': serializer.toJson<String>(searchText),
      'cardLast4': serializer.toJson<String?>(cardLast4),
      'message': serializer.toJson<String?>(message),
      'detailed': serializer.toJson<bool>(detailed),
      'openedAtMicros': serializer.toJson<int?>(openedAtMicros),
    };
  }

  TransactionRow copyWith({
    String? id,
    String? description,
    int? amountCents,
    String? direction,
    String? status,
    int? occurredAtMicros,
    String? paymentMethod,
    String? category,
    Value<String?> counterparty = const Value.absent(),
    String? searchText,
    Value<String?> cardLast4 = const Value.absent(),
    Value<String?> message = const Value.absent(),
    bool? detailed,
    Value<int?> openedAtMicros = const Value.absent(),
  }) => TransactionRow(
    id: id ?? this.id,
    description: description ?? this.description,
    amountCents: amountCents ?? this.amountCents,
    direction: direction ?? this.direction,
    status: status ?? this.status,
    occurredAtMicros: occurredAtMicros ?? this.occurredAtMicros,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    category: category ?? this.category,
    counterparty: counterparty.present ? counterparty.value : this.counterparty,
    searchText: searchText ?? this.searchText,
    cardLast4: cardLast4.present ? cardLast4.value : this.cardLast4,
    message: message.present ? message.value : this.message,
    detailed: detailed ?? this.detailed,
    openedAtMicros: openedAtMicros.present
        ? openedAtMicros.value
        : this.openedAtMicros,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      description: data.description.present
          ? data.description.value
          : this.description,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      direction: data.direction.present ? data.direction.value : this.direction,
      status: data.status.present ? data.status.value : this.status,
      occurredAtMicros: data.occurredAtMicros.present
          ? data.occurredAtMicros.value
          : this.occurredAtMicros,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      category: data.category.present ? data.category.value : this.category,
      counterparty: data.counterparty.present
          ? data.counterparty.value
          : this.counterparty,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
      cardLast4: data.cardLast4.present ? data.cardLast4.value : this.cardLast4,
      message: data.message.present ? data.message.value : this.message,
      detailed: data.detailed.present ? data.detailed.value : this.detailed,
      openedAtMicros: data.openedAtMicros.present
          ? data.openedAtMicros.value
          : this.openedAtMicros,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('amountCents: $amountCents, ')
          ..write('direction: $direction, ')
          ..write('status: $status, ')
          ..write('occurredAtMicros: $occurredAtMicros, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('category: $category, ')
          ..write('counterparty: $counterparty, ')
          ..write('searchText: $searchText, ')
          ..write('cardLast4: $cardLast4, ')
          ..write('message: $message, ')
          ..write('detailed: $detailed, ')
          ..write('openedAtMicros: $openedAtMicros')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    description,
    amountCents,
    direction,
    status,
    occurredAtMicros,
    paymentMethod,
    category,
    counterparty,
    searchText,
    cardLast4,
    message,
    detailed,
    openedAtMicros,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.description == this.description &&
          other.amountCents == this.amountCents &&
          other.direction == this.direction &&
          other.status == this.status &&
          other.occurredAtMicros == this.occurredAtMicros &&
          other.paymentMethod == this.paymentMethod &&
          other.category == this.category &&
          other.counterparty == this.counterparty &&
          other.searchText == this.searchText &&
          other.cardLast4 == this.cardLast4 &&
          other.message == this.message &&
          other.detailed == this.detailed &&
          other.openedAtMicros == this.openedAtMicros);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<String> id;
  final Value<String> description;
  final Value<int> amountCents;
  final Value<String> direction;
  final Value<String> status;
  final Value<int> occurredAtMicros;
  final Value<String> paymentMethod;
  final Value<String> category;
  final Value<String?> counterparty;
  final Value<String> searchText;
  final Value<String?> cardLast4;
  final Value<String?> message;
  final Value<bool> detailed;
  final Value<int?> openedAtMicros;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.direction = const Value.absent(),
    this.status = const Value.absent(),
    this.occurredAtMicros = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.category = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.searchText = const Value.absent(),
    this.cardLast4 = const Value.absent(),
    this.message = const Value.absent(),
    this.detailed = const Value.absent(),
    this.openedAtMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String description,
    required int amountCents,
    required String direction,
    required String status,
    required int occurredAtMicros,
    required String paymentMethod,
    required String category,
    this.counterparty = const Value.absent(),
    required String searchText,
    this.cardLast4 = const Value.absent(),
    this.message = const Value.absent(),
    this.detailed = const Value.absent(),
    this.openedAtMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       description = Value(description),
       amountCents = Value(amountCents),
       direction = Value(direction),
       status = Value(status),
       occurredAtMicros = Value(occurredAtMicros),
       paymentMethod = Value(paymentMethod),
       category = Value(category),
       searchText = Value(searchText);
  static Insertable<TransactionRow> custom({
    Expression<String>? id,
    Expression<String>? description,
    Expression<int>? amountCents,
    Expression<String>? direction,
    Expression<String>? status,
    Expression<int>? occurredAtMicros,
    Expression<String>? paymentMethod,
    Expression<String>? category,
    Expression<String>? counterparty,
    Expression<String>? searchText,
    Expression<String>? cardLast4,
    Expression<String>? message,
    Expression<bool>? detailed,
    Expression<int>? openedAtMicros,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'description': description,
      if (amountCents != null) 'amount_cents': amountCents,
      if (direction != null) 'direction': direction,
      if (status != null) 'status': status,
      if (occurredAtMicros != null) 'occurred_at_micros': occurredAtMicros,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (category != null) 'category': category,
      if (counterparty != null) 'counterparty': counterparty,
      if (searchText != null) 'search_text': searchText,
      if (cardLast4 != null) 'card_last4': cardLast4,
      if (message != null) 'message': message,
      if (detailed != null) 'detailed': detailed,
      if (openedAtMicros != null) 'opened_at_micros': openedAtMicros,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? description,
    Value<int>? amountCents,
    Value<String>? direction,
    Value<String>? status,
    Value<int>? occurredAtMicros,
    Value<String>? paymentMethod,
    Value<String>? category,
    Value<String?>? counterparty,
    Value<String>? searchText,
    Value<String?>? cardLast4,
    Value<String?>? message,
    Value<bool>? detailed,
    Value<int?>? openedAtMicros,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
      amountCents: amountCents ?? this.amountCents,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      occurredAtMicros: occurredAtMicros ?? this.occurredAtMicros,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      category: category ?? this.category,
      counterparty: counterparty ?? this.counterparty,
      searchText: searchText ?? this.searchText,
      cardLast4: cardLast4 ?? this.cardLast4,
      message: message ?? this.message,
      detailed: detailed ?? this.detailed,
      openedAtMicros: openedAtMicros ?? this.openedAtMicros,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (occurredAtMicros.present) {
      map['occurred_at_micros'] = Variable<int>(occurredAtMicros.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (counterparty.present) {
      map['counterparty'] = Variable<String>(counterparty.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (cardLast4.present) {
      map['card_last4'] = Variable<String>(cardLast4.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (detailed.present) {
      map['detailed'] = Variable<bool>(detailed.value);
    }
    if (openedAtMicros.present) {
      map['opened_at_micros'] = Variable<int>(openedAtMicros.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('amountCents: $amountCents, ')
          ..write('direction: $direction, ')
          ..write('status: $status, ')
          ..write('occurredAtMicros: $occurredAtMicros, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('category: $category, ')
          ..write('counterparty: $counterparty, ')
          ..write('searchText: $searchText, ')
          ..write('cardLast4: $cardLast4, ')
          ..write('message: $message, ')
          ..write('detailed: $detailed, ')
          ..write('openedAtMicros: $openedAtMicros, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DashboardStateTable extends DashboardState
    with TableInfo<$DashboardStateTable, DashboardStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DashboardStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _balanceCentsMeta = const VerificationMeta(
    'balanceCents',
  );
  @override
  late final GeneratedColumn<int> balanceCents = GeneratedColumn<int>(
    'balance_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodFirstMeta = const VerificationMeta(
    'periodFirst',
  );
  @override
  late final GeneratedColumn<String> periodFirst = GeneratedColumn<String>(
    'period_first',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodLastMeta = const VerificationMeta(
    'periodLast',
  );
  @override
  late final GeneratedColumn<String> periodLast = GeneratedColumn<String>(
    'period_last',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingIdsMeta = const VerificationMeta(
    'pendingIds',
  );
  @override
  late final GeneratedColumn<String> pendingIds = GeneratedColumn<String>(
    'pending_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMicrosMeta = const VerificationMeta(
    'syncedAtMicros',
  );
  @override
  late final GeneratedColumn<int> syncedAtMicros = GeneratedColumn<int>(
    'synced_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skippedRecordsMeta = const VerificationMeta(
    'skippedRecords',
  );
  @override
  late final GeneratedColumn<int> skippedRecords = GeneratedColumn<int>(
    'skipped_records',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    balanceCents,
    periodFirst,
    periodLast,
    pendingIds,
    syncedAtMicros,
    skippedRecords,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dashboard_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<DashboardStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('balance_cents')) {
      context.handle(
        _balanceCentsMeta,
        balanceCents.isAcceptableOrUnknown(
          data['balance_cents']!,
          _balanceCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_balanceCentsMeta);
    }
    if (data.containsKey('period_first')) {
      context.handle(
        _periodFirstMeta,
        periodFirst.isAcceptableOrUnknown(
          data['period_first']!,
          _periodFirstMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodFirstMeta);
    }
    if (data.containsKey('period_last')) {
      context.handle(
        _periodLastMeta,
        periodLast.isAcceptableOrUnknown(data['period_last']!, _periodLastMeta),
      );
    } else if (isInserting) {
      context.missing(_periodLastMeta);
    }
    if (data.containsKey('pending_ids')) {
      context.handle(
        _pendingIdsMeta,
        pendingIds.isAcceptableOrUnknown(data['pending_ids']!, _pendingIdsMeta),
      );
    } else if (isInserting) {
      context.missing(_pendingIdsMeta);
    }
    if (data.containsKey('synced_at_micros')) {
      context.handle(
        _syncedAtMicrosMeta,
        syncedAtMicros.isAcceptableOrUnknown(
          data['synced_at_micros']!,
          _syncedAtMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMicrosMeta);
    }
    if (data.containsKey('skipped_records')) {
      context.handle(
        _skippedRecordsMeta,
        skippedRecords.isAcceptableOrUnknown(
          data['skipped_records']!,
          _skippedRecordsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DashboardStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DashboardStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      balanceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_cents'],
      )!,
      periodFirst: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_first'],
      )!,
      periodLast: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_last'],
      )!,
      pendingIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_ids'],
      )!,
      syncedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at_micros'],
      )!,
      skippedRecords: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skipped_records'],
      )!,
    );
  }

  @override
  $DashboardStateTable createAlias(String alias) {
    return $DashboardStateTable(attachedDatabase, alias);
  }
}

class DashboardStateRow extends DataClass
    implements Insertable<DashboardStateRow> {
  final int id;
  final int balanceCents;

  /// The period whose transactions were all saved (`yyyy-mm-dd`).
  final String periodFirst;
  final String periodLast;

  /// Ids of the pending debits, as a JSON list. Kept apart from the rows'
  /// status: a debit that settled meanwhile simply leaves this list.
  final String pendingIds;
  final int syncedAtMicros;
  final int skippedRecords;
  const DashboardStateRow({
    required this.id,
    required this.balanceCents,
    required this.periodFirst,
    required this.periodLast,
    required this.pendingIds,
    required this.syncedAtMicros,
    required this.skippedRecords,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['balance_cents'] = Variable<int>(balanceCents);
    map['period_first'] = Variable<String>(periodFirst);
    map['period_last'] = Variable<String>(periodLast);
    map['pending_ids'] = Variable<String>(pendingIds);
    map['synced_at_micros'] = Variable<int>(syncedAtMicros);
    map['skipped_records'] = Variable<int>(skippedRecords);
    return map;
  }

  DashboardStateCompanion toCompanion(bool nullToAbsent) {
    return DashboardStateCompanion(
      id: Value(id),
      balanceCents: Value(balanceCents),
      periodFirst: Value(periodFirst),
      periodLast: Value(periodLast),
      pendingIds: Value(pendingIds),
      syncedAtMicros: Value(syncedAtMicros),
      skippedRecords: Value(skippedRecords),
    );
  }

  factory DashboardStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DashboardStateRow(
      id: serializer.fromJson<int>(json['id']),
      balanceCents: serializer.fromJson<int>(json['balanceCents']),
      periodFirst: serializer.fromJson<String>(json['periodFirst']),
      periodLast: serializer.fromJson<String>(json['periodLast']),
      pendingIds: serializer.fromJson<String>(json['pendingIds']),
      syncedAtMicros: serializer.fromJson<int>(json['syncedAtMicros']),
      skippedRecords: serializer.fromJson<int>(json['skippedRecords']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'balanceCents': serializer.toJson<int>(balanceCents),
      'periodFirst': serializer.toJson<String>(periodFirst),
      'periodLast': serializer.toJson<String>(periodLast),
      'pendingIds': serializer.toJson<String>(pendingIds),
      'syncedAtMicros': serializer.toJson<int>(syncedAtMicros),
      'skippedRecords': serializer.toJson<int>(skippedRecords),
    };
  }

  DashboardStateRow copyWith({
    int? id,
    int? balanceCents,
    String? periodFirst,
    String? periodLast,
    String? pendingIds,
    int? syncedAtMicros,
    int? skippedRecords,
  }) => DashboardStateRow(
    id: id ?? this.id,
    balanceCents: balanceCents ?? this.balanceCents,
    periodFirst: periodFirst ?? this.periodFirst,
    periodLast: periodLast ?? this.periodLast,
    pendingIds: pendingIds ?? this.pendingIds,
    syncedAtMicros: syncedAtMicros ?? this.syncedAtMicros,
    skippedRecords: skippedRecords ?? this.skippedRecords,
  );
  DashboardStateRow copyWithCompanion(DashboardStateCompanion data) {
    return DashboardStateRow(
      id: data.id.present ? data.id.value : this.id,
      balanceCents: data.balanceCents.present
          ? data.balanceCents.value
          : this.balanceCents,
      periodFirst: data.periodFirst.present
          ? data.periodFirst.value
          : this.periodFirst,
      periodLast: data.periodLast.present
          ? data.periodLast.value
          : this.periodLast,
      pendingIds: data.pendingIds.present
          ? data.pendingIds.value
          : this.pendingIds,
      syncedAtMicros: data.syncedAtMicros.present
          ? data.syncedAtMicros.value
          : this.syncedAtMicros,
      skippedRecords: data.skippedRecords.present
          ? data.skippedRecords.value
          : this.skippedRecords,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DashboardStateRow(')
          ..write('id: $id, ')
          ..write('balanceCents: $balanceCents, ')
          ..write('periodFirst: $periodFirst, ')
          ..write('periodLast: $periodLast, ')
          ..write('pendingIds: $pendingIds, ')
          ..write('syncedAtMicros: $syncedAtMicros, ')
          ..write('skippedRecords: $skippedRecords')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    balanceCents,
    periodFirst,
    periodLast,
    pendingIds,
    syncedAtMicros,
    skippedRecords,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DashboardStateRow &&
          other.id == this.id &&
          other.balanceCents == this.balanceCents &&
          other.periodFirst == this.periodFirst &&
          other.periodLast == this.periodLast &&
          other.pendingIds == this.pendingIds &&
          other.syncedAtMicros == this.syncedAtMicros &&
          other.skippedRecords == this.skippedRecords);
}

class DashboardStateCompanion extends UpdateCompanion<DashboardStateRow> {
  final Value<int> id;
  final Value<int> balanceCents;
  final Value<String> periodFirst;
  final Value<String> periodLast;
  final Value<String> pendingIds;
  final Value<int> syncedAtMicros;
  final Value<int> skippedRecords;
  const DashboardStateCompanion({
    this.id = const Value.absent(),
    this.balanceCents = const Value.absent(),
    this.periodFirst = const Value.absent(),
    this.periodLast = const Value.absent(),
    this.pendingIds = const Value.absent(),
    this.syncedAtMicros = const Value.absent(),
    this.skippedRecords = const Value.absent(),
  });
  DashboardStateCompanion.insert({
    this.id = const Value.absent(),
    required int balanceCents,
    required String periodFirst,
    required String periodLast,
    required String pendingIds,
    required int syncedAtMicros,
    this.skippedRecords = const Value.absent(),
  }) : balanceCents = Value(balanceCents),
       periodFirst = Value(periodFirst),
       periodLast = Value(periodLast),
       pendingIds = Value(pendingIds),
       syncedAtMicros = Value(syncedAtMicros);
  static Insertable<DashboardStateRow> custom({
    Expression<int>? id,
    Expression<int>? balanceCents,
    Expression<String>? periodFirst,
    Expression<String>? periodLast,
    Expression<String>? pendingIds,
    Expression<int>? syncedAtMicros,
    Expression<int>? skippedRecords,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (balanceCents != null) 'balance_cents': balanceCents,
      if (periodFirst != null) 'period_first': periodFirst,
      if (periodLast != null) 'period_last': periodLast,
      if (pendingIds != null) 'pending_ids': pendingIds,
      if (syncedAtMicros != null) 'synced_at_micros': syncedAtMicros,
      if (skippedRecords != null) 'skipped_records': skippedRecords,
    });
  }

  DashboardStateCompanion copyWith({
    Value<int>? id,
    Value<int>? balanceCents,
    Value<String>? periodFirst,
    Value<String>? periodLast,
    Value<String>? pendingIds,
    Value<int>? syncedAtMicros,
    Value<int>? skippedRecords,
  }) {
    return DashboardStateCompanion(
      id: id ?? this.id,
      balanceCents: balanceCents ?? this.balanceCents,
      periodFirst: periodFirst ?? this.periodFirst,
      periodLast: periodLast ?? this.periodLast,
      pendingIds: pendingIds ?? this.pendingIds,
      syncedAtMicros: syncedAtMicros ?? this.syncedAtMicros,
      skippedRecords: skippedRecords ?? this.skippedRecords,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (balanceCents.present) {
      map['balance_cents'] = Variable<int>(balanceCents.value);
    }
    if (periodFirst.present) {
      map['period_first'] = Variable<String>(periodFirst.value);
    }
    if (periodLast.present) {
      map['period_last'] = Variable<String>(periodLast.value);
    }
    if (pendingIds.present) {
      map['pending_ids'] = Variable<String>(pendingIds.value);
    }
    if (syncedAtMicros.present) {
      map['synced_at_micros'] = Variable<int>(syncedAtMicros.value);
    }
    if (skippedRecords.present) {
      map['skipped_records'] = Variable<int>(skippedRecords.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DashboardStateCompanion(')
          ..write('id: $id, ')
          ..write('balanceCents: $balanceCents, ')
          ..write('periodFirst: $periodFirst, ')
          ..write('periodLast: $periodLast, ')
          ..write('pendingIds: $pendingIds, ')
          ..write('syncedAtMicros: $syncedAtMicros, ')
          ..write('skippedRecords: $skippedRecords')
          ..write(')'))
        .toString();
  }
}

class $StatementStateTable extends StatementState
    with TableInfo<$StatementStateTable, StatementStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StatementStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMicrosMeta = const VerificationMeta(
    'syncedAtMicros',
  );
  @override
  late final GeneratedColumn<int> syncedAtMicros = GeneratedColumn<int>(
    'synced_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skippedRecordsMeta = const VerificationMeta(
    'skippedRecords',
  );
  @override
  late final GeneratedColumn<int> skippedRecords = GeneratedColumn<int>(
    'skipped_records',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, syncedAtMicros, skippedRecords];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'statement_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<StatementStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('synced_at_micros')) {
      context.handle(
        _syncedAtMicrosMeta,
        syncedAtMicros.isAcceptableOrUnknown(
          data['synced_at_micros']!,
          _syncedAtMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMicrosMeta);
    }
    if (data.containsKey('skipped_records')) {
      context.handle(
        _skippedRecordsMeta,
        skippedRecords.isAcceptableOrUnknown(
          data['skipped_records']!,
          _skippedRecordsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StatementStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StatementStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      syncedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at_micros'],
      )!,
      skippedRecords: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skipped_records'],
      )!,
    );
  }

  @override
  $StatementStateTable createAlias(String alias) {
    return $StatementStateTable(attachedDatabase, alias);
  }
}

class StatementStateRow extends DataClass
    implements Insertable<StatementStateRow> {
  final int id;
  final int syncedAtMicros;
  final int skippedRecords;
  const StatementStateRow({
    required this.id,
    required this.syncedAtMicros,
    required this.skippedRecords,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['synced_at_micros'] = Variable<int>(syncedAtMicros);
    map['skipped_records'] = Variable<int>(skippedRecords);
    return map;
  }

  StatementStateCompanion toCompanion(bool nullToAbsent) {
    return StatementStateCompanion(
      id: Value(id),
      syncedAtMicros: Value(syncedAtMicros),
      skippedRecords: Value(skippedRecords),
    );
  }

  factory StatementStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StatementStateRow(
      id: serializer.fromJson<int>(json['id']),
      syncedAtMicros: serializer.fromJson<int>(json['syncedAtMicros']),
      skippedRecords: serializer.fromJson<int>(json['skippedRecords']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncedAtMicros': serializer.toJson<int>(syncedAtMicros),
      'skippedRecords': serializer.toJson<int>(skippedRecords),
    };
  }

  StatementStateRow copyWith({
    int? id,
    int? syncedAtMicros,
    int? skippedRecords,
  }) => StatementStateRow(
    id: id ?? this.id,
    syncedAtMicros: syncedAtMicros ?? this.syncedAtMicros,
    skippedRecords: skippedRecords ?? this.skippedRecords,
  );
  StatementStateRow copyWithCompanion(StatementStateCompanion data) {
    return StatementStateRow(
      id: data.id.present ? data.id.value : this.id,
      syncedAtMicros: data.syncedAtMicros.present
          ? data.syncedAtMicros.value
          : this.syncedAtMicros,
      skippedRecords: data.skippedRecords.present
          ? data.skippedRecords.value
          : this.skippedRecords,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StatementStateRow(')
          ..write('id: $id, ')
          ..write('syncedAtMicros: $syncedAtMicros, ')
          ..write('skippedRecords: $skippedRecords')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, syncedAtMicros, skippedRecords);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatementStateRow &&
          other.id == this.id &&
          other.syncedAtMicros == this.syncedAtMicros &&
          other.skippedRecords == this.skippedRecords);
}

class StatementStateCompanion extends UpdateCompanion<StatementStateRow> {
  final Value<int> id;
  final Value<int> syncedAtMicros;
  final Value<int> skippedRecords;
  const StatementStateCompanion({
    this.id = const Value.absent(),
    this.syncedAtMicros = const Value.absent(),
    this.skippedRecords = const Value.absent(),
  });
  StatementStateCompanion.insert({
    this.id = const Value.absent(),
    required int syncedAtMicros,
    this.skippedRecords = const Value.absent(),
  }) : syncedAtMicros = Value(syncedAtMicros);
  static Insertable<StatementStateRow> custom({
    Expression<int>? id,
    Expression<int>? syncedAtMicros,
    Expression<int>? skippedRecords,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncedAtMicros != null) 'synced_at_micros': syncedAtMicros,
      if (skippedRecords != null) 'skipped_records': skippedRecords,
    });
  }

  StatementStateCompanion copyWith({
    Value<int>? id,
    Value<int>? syncedAtMicros,
    Value<int>? skippedRecords,
  }) {
    return StatementStateCompanion(
      id: id ?? this.id,
      syncedAtMicros: syncedAtMicros ?? this.syncedAtMicros,
      skippedRecords: skippedRecords ?? this.skippedRecords,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (syncedAtMicros.present) {
      map['synced_at_micros'] = Variable<int>(syncedAtMicros.value);
    }
    if (skippedRecords.present) {
      map['skipped_records'] = Variable<int>(skippedRecords.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StatementStateCompanion(')
          ..write('id: $id, ')
          ..write('syncedAtMicros: $syncedAtMicros, ')
          ..write('skippedRecords: $skippedRecords')
          ..write(')'))
        .toString();
  }
}

abstract class _$LedgerDatabase extends GeneratedDatabase {
  _$LedgerDatabase(QueryExecutor e) : super(e);
  $LedgerDatabaseManager get managers => $LedgerDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $DashboardStateTable dashboardState = $DashboardStateTable(this);
  late final $StatementStateTable statementState = $StatementStateTable(this);
  late final Index idxTransactionsPaging = Index(
    'idx_transactions_paging',
    'CREATE INDEX idx_transactions_paging ON transactions (occurred_at_micros, id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    dashboardState,
    statementState,
    idxTransactionsPaging,
  ];
}

typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String description,
      required int amountCents,
      required String direction,
      required String status,
      required int occurredAtMicros,
      required String paymentMethod,
      required String category,
      Value<String?> counterparty,
      required String searchText,
      Value<String?> cardLast4,
      Value<String?> message,
      Value<bool> detailed,
      Value<int?> openedAtMicros,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> description,
      Value<int> amountCents,
      Value<String> direction,
      Value<String> status,
      Value<int> occurredAtMicros,
      Value<String> paymentMethod,
      Value<String> category,
      Value<String?> counterparty,
      Value<String> searchText,
      Value<String?> cardLast4,
      Value<String?> message,
      Value<bool> detailed,
      Value<int?> openedAtMicros,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$LedgerDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAtMicros => $composableBuilder(
    column: $table.occurredAtMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardLast4 => $composableBuilder(
    column: $table.cardLast4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get detailed => $composableBuilder(
    column: $table.detailed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openedAtMicros => $composableBuilder(
    column: $table.openedAtMicros,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$LedgerDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAtMicros => $composableBuilder(
    column: $table.occurredAtMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardLast4 => $composableBuilder(
    column: $table.cardLast4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get detailed => $composableBuilder(
    column: $table.detailed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openedAtMicros => $composableBuilder(
    column: $table.openedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get occurredAtMicros => $composableBuilder(
    column: $table.occurredAtMicros,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardLast4 =>
      $composableBuilder(column: $table.cardLast4, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<bool> get detailed =>
      $composableBuilder(column: $table.detailed, builder: (column) => column);

  GeneratedColumn<int> get openedAtMicros => $composableBuilder(
    column: $table.openedAtMicros,
    builder: (column) => column,
  );
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            TransactionRow,
            BaseReferences<
              _$LedgerDatabase,
              $TransactionsTable,
              TransactionRow
            >,
          ),
          TransactionRow,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$LedgerDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> occurredAtMicros = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<String?> cardLast4 = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<bool> detailed = const Value.absent(),
                Value<int?> openedAtMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                description: description,
                amountCents: amountCents,
                direction: direction,
                status: status,
                occurredAtMicros: occurredAtMicros,
                paymentMethod: paymentMethod,
                category: category,
                counterparty: counterparty,
                searchText: searchText,
                cardLast4: cardLast4,
                message: message,
                detailed: detailed,
                openedAtMicros: openedAtMicros,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String description,
                required int amountCents,
                required String direction,
                required String status,
                required int occurredAtMicros,
                required String paymentMethod,
                required String category,
                Value<String?> counterparty = const Value.absent(),
                required String searchText,
                Value<String?> cardLast4 = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<bool> detailed = const Value.absent(),
                Value<int?> openedAtMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                description: description,
                amountCents: amountCents,
                direction: direction,
                status: status,
                occurredAtMicros: occurredAtMicros,
                paymentMethod: paymentMethod,
                category: category,
                counterparty: counterparty,
                searchText: searchText,
                cardLast4: cardLast4,
                message: message,
                detailed: detailed,
                openedAtMicros: openedAtMicros,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, TransactionRow>(table),
                  BaseReferences<
                    _$LedgerDatabase,
                    $TransactionsTable,
                    TransactionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        TransactionRow,
        BaseReferences<_$LedgerDatabase, $TransactionsTable, TransactionRow>,
      ),
      TransactionRow,
      PrefetchHooks Function()
    >;
typedef $$DashboardStateTableCreateCompanionBuilder =
    DashboardStateCompanion Function({
      Value<int> id,
      required int balanceCents,
      required String periodFirst,
      required String periodLast,
      required String pendingIds,
      required int syncedAtMicros,
      Value<int> skippedRecords,
    });
typedef $$DashboardStateTableUpdateCompanionBuilder =
    DashboardStateCompanion Function({
      Value<int> id,
      Value<int> balanceCents,
      Value<String> periodFirst,
      Value<String> periodLast,
      Value<String> pendingIds,
      Value<int> syncedAtMicros,
      Value<int> skippedRecords,
    });

class $$DashboardStateTableFilterComposer
    extends Composer<_$LedgerDatabase, $DashboardStateTable> {
  $$DashboardStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceCents => $composableBuilder(
    column: $table.balanceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodFirst => $composableBuilder(
    column: $table.periodFirst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodLast => $composableBuilder(
    column: $table.periodLast,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pendingIds => $composableBuilder(
    column: $table.pendingIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAtMicros => $composableBuilder(
    column: $table.syncedAtMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skippedRecords => $composableBuilder(
    column: $table.skippedRecords,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DashboardStateTableOrderingComposer
    extends Composer<_$LedgerDatabase, $DashboardStateTable> {
  $$DashboardStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceCents => $composableBuilder(
    column: $table.balanceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodFirst => $composableBuilder(
    column: $table.periodFirst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodLast => $composableBuilder(
    column: $table.periodLast,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingIds => $composableBuilder(
    column: $table.pendingIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAtMicros => $composableBuilder(
    column: $table.syncedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skippedRecords => $composableBuilder(
    column: $table.skippedRecords,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DashboardStateTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $DashboardStateTable> {
  $$DashboardStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get balanceCents => $composableBuilder(
    column: $table.balanceCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodFirst => $composableBuilder(
    column: $table.periodFirst,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodLast => $composableBuilder(
    column: $table.periodLast,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pendingIds => $composableBuilder(
    column: $table.pendingIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncedAtMicros => $composableBuilder(
    column: $table.syncedAtMicros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get skippedRecords => $composableBuilder(
    column: $table.skippedRecords,
    builder: (column) => column,
  );
}

class $$DashboardStateTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $DashboardStateTable,
          DashboardStateRow,
          $$DashboardStateTableFilterComposer,
          $$DashboardStateTableOrderingComposer,
          $$DashboardStateTableAnnotationComposer,
          $$DashboardStateTableCreateCompanionBuilder,
          $$DashboardStateTableUpdateCompanionBuilder,
          (
            DashboardStateRow,
            BaseReferences<
              _$LedgerDatabase,
              $DashboardStateTable,
              DashboardStateRow
            >,
          ),
          DashboardStateRow,
          PrefetchHooks Function()
        > {
  $$DashboardStateTableTableManager(
    _$LedgerDatabase db,
    $DashboardStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DashboardStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DashboardStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DashboardStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> balanceCents = const Value.absent(),
                Value<String> periodFirst = const Value.absent(),
                Value<String> periodLast = const Value.absent(),
                Value<String> pendingIds = const Value.absent(),
                Value<int> syncedAtMicros = const Value.absent(),
                Value<int> skippedRecords = const Value.absent(),
              }) => DashboardStateCompanion(
                id: id,
                balanceCents: balanceCents,
                periodFirst: periodFirst,
                periodLast: periodLast,
                pendingIds: pendingIds,
                syncedAtMicros: syncedAtMicros,
                skippedRecords: skippedRecords,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int balanceCents,
                required String periodFirst,
                required String periodLast,
                required String pendingIds,
                required int syncedAtMicros,
                Value<int> skippedRecords = const Value.absent(),
              }) => DashboardStateCompanion.insert(
                id: id,
                balanceCents: balanceCents,
                periodFirst: periodFirst,
                periodLast: periodLast,
                pendingIds: pendingIds,
                syncedAtMicros: syncedAtMicros,
                skippedRecords: skippedRecords,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DashboardStateTable, DashboardStateRow>(table),
                  BaseReferences<
                    _$LedgerDatabase,
                    $DashboardStateTable,
                    DashboardStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DashboardStateTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $DashboardStateTable,
      DashboardStateRow,
      $$DashboardStateTableFilterComposer,
      $$DashboardStateTableOrderingComposer,
      $$DashboardStateTableAnnotationComposer,
      $$DashboardStateTableCreateCompanionBuilder,
      $$DashboardStateTableUpdateCompanionBuilder,
      (
        DashboardStateRow,
        BaseReferences<
          _$LedgerDatabase,
          $DashboardStateTable,
          DashboardStateRow
        >,
      ),
      DashboardStateRow,
      PrefetchHooks Function()
    >;
typedef $$StatementStateTableCreateCompanionBuilder =
    StatementStateCompanion Function({
      Value<int> id,
      required int syncedAtMicros,
      Value<int> skippedRecords,
    });
typedef $$StatementStateTableUpdateCompanionBuilder =
    StatementStateCompanion Function({
      Value<int> id,
      Value<int> syncedAtMicros,
      Value<int> skippedRecords,
    });

class $$StatementStateTableFilterComposer
    extends Composer<_$LedgerDatabase, $StatementStateTable> {
  $$StatementStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAtMicros => $composableBuilder(
    column: $table.syncedAtMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skippedRecords => $composableBuilder(
    column: $table.skippedRecords,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StatementStateTableOrderingComposer
    extends Composer<_$LedgerDatabase, $StatementStateTable> {
  $$StatementStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAtMicros => $composableBuilder(
    column: $table.syncedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skippedRecords => $composableBuilder(
    column: $table.skippedRecords,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StatementStateTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $StatementStateTable> {
  $$StatementStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get syncedAtMicros => $composableBuilder(
    column: $table.syncedAtMicros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get skippedRecords => $composableBuilder(
    column: $table.skippedRecords,
    builder: (column) => column,
  );
}

class $$StatementStateTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $StatementStateTable,
          StatementStateRow,
          $$StatementStateTableFilterComposer,
          $$StatementStateTableOrderingComposer,
          $$StatementStateTableAnnotationComposer,
          $$StatementStateTableCreateCompanionBuilder,
          $$StatementStateTableUpdateCompanionBuilder,
          (
            StatementStateRow,
            BaseReferences<
              _$LedgerDatabase,
              $StatementStateTable,
              StatementStateRow
            >,
          ),
          StatementStateRow,
          PrefetchHooks Function()
        > {
  $$StatementStateTableTableManager(
    _$LedgerDatabase db,
    $StatementStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StatementStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StatementStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StatementStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> syncedAtMicros = const Value.absent(),
                Value<int> skippedRecords = const Value.absent(),
              }) => StatementStateCompanion(
                id: id,
                syncedAtMicros: syncedAtMicros,
                skippedRecords: skippedRecords,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int syncedAtMicros,
                Value<int> skippedRecords = const Value.absent(),
              }) => StatementStateCompanion.insert(
                id: id,
                syncedAtMicros: syncedAtMicros,
                skippedRecords: skippedRecords,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StatementStateTable, StatementStateRow>(table),
                  BaseReferences<
                    _$LedgerDatabase,
                    $StatementStateTable,
                    StatementStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StatementStateTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $StatementStateTable,
      StatementStateRow,
      $$StatementStateTableFilterComposer,
      $$StatementStateTableOrderingComposer,
      $$StatementStateTableAnnotationComposer,
      $$StatementStateTableCreateCompanionBuilder,
      $$StatementStateTableUpdateCompanionBuilder,
      (
        StatementStateRow,
        BaseReferences<
          _$LedgerDatabase,
          $StatementStateTable,
          StatementStateRow
        >,
      ),
      StatementStateRow,
      PrefetchHooks Function()
    >;

class $LedgerDatabaseManager {
  final _$LedgerDatabase _db;
  $LedgerDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$DashboardStateTableTableManager get dashboardState =>
      $$DashboardStateTableTableManager(_db, _db.dashboardState);
  $$StatementStateTableTableManager get statementState =>
      $$StatementStateTableTableManager(_db, _db.statementState);
}
