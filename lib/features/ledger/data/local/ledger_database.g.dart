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
    cardLast4,
    counterparty,
    message,
    searchText,
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
    if (data.containsKey('card_last4')) {
      context.handle(
        _cardLast4Meta,
        cardLast4.isAcceptableOrUnknown(data['card_last4']!, _cardLast4Meta),
      );
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
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
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
      cardLast4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_last4'],
      ),
      counterparty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
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
  final String? cardLast4;
  final String? counterparty;
  final String? message;

  /// Description and counterparty in lower case without accents, so the
  /// search follows the same rules as `SearchText` with a plain LIKE.
  final String searchText;
  const TransactionRow({
    required this.id,
    required this.description,
    required this.amountCents,
    required this.direction,
    required this.status,
    required this.occurredAtMicros,
    required this.paymentMethod,
    required this.category,
    this.cardLast4,
    this.counterparty,
    this.message,
    required this.searchText,
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
    if (!nullToAbsent || cardLast4 != null) {
      map['card_last4'] = Variable<String>(cardLast4);
    }
    if (!nullToAbsent || counterparty != null) {
      map['counterparty'] = Variable<String>(counterparty);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['search_text'] = Variable<String>(searchText);
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
      cardLast4: cardLast4 == null && nullToAbsent
          ? const Value.absent()
          : Value(cardLast4),
      counterparty: counterparty == null && nullToAbsent
          ? const Value.absent()
          : Value(counterparty),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      searchText: Value(searchText),
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
      cardLast4: serializer.fromJson<String?>(json['cardLast4']),
      counterparty: serializer.fromJson<String?>(json['counterparty']),
      message: serializer.fromJson<String?>(json['message']),
      searchText: serializer.fromJson<String>(json['searchText']),
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
      'cardLast4': serializer.toJson<String?>(cardLast4),
      'counterparty': serializer.toJson<String?>(counterparty),
      'message': serializer.toJson<String?>(message),
      'searchText': serializer.toJson<String>(searchText),
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
    Value<String?> cardLast4 = const Value.absent(),
    Value<String?> counterparty = const Value.absent(),
    Value<String?> message = const Value.absent(),
    String? searchText,
  }) => TransactionRow(
    id: id ?? this.id,
    description: description ?? this.description,
    amountCents: amountCents ?? this.amountCents,
    direction: direction ?? this.direction,
    status: status ?? this.status,
    occurredAtMicros: occurredAtMicros ?? this.occurredAtMicros,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    category: category ?? this.category,
    cardLast4: cardLast4.present ? cardLast4.value : this.cardLast4,
    counterparty: counterparty.present ? counterparty.value : this.counterparty,
    message: message.present ? message.value : this.message,
    searchText: searchText ?? this.searchText,
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
      cardLast4: data.cardLast4.present ? data.cardLast4.value : this.cardLast4,
      counterparty: data.counterparty.present
          ? data.counterparty.value
          : this.counterparty,
      message: data.message.present ? data.message.value : this.message,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
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
          ..write('cardLast4: $cardLast4, ')
          ..write('counterparty: $counterparty, ')
          ..write('message: $message, ')
          ..write('searchText: $searchText')
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
    cardLast4,
    counterparty,
    message,
    searchText,
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
          other.cardLast4 == this.cardLast4 &&
          other.counterparty == this.counterparty &&
          other.message == this.message &&
          other.searchText == this.searchText);
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
  final Value<String?> cardLast4;
  final Value<String?> counterparty;
  final Value<String?> message;
  final Value<String> searchText;
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
    this.cardLast4 = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.message = const Value.absent(),
    this.searchText = const Value.absent(),
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
    this.cardLast4 = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.message = const Value.absent(),
    required String searchText,
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
    Expression<String>? cardLast4,
    Expression<String>? counterparty,
    Expression<String>? message,
    Expression<String>? searchText,
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
      if (cardLast4 != null) 'card_last4': cardLast4,
      if (counterparty != null) 'counterparty': counterparty,
      if (message != null) 'message': message,
      if (searchText != null) 'search_text': searchText,
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
    Value<String?>? cardLast4,
    Value<String?>? counterparty,
    Value<String?>? message,
    Value<String>? searchText,
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
      cardLast4: cardLast4 ?? this.cardLast4,
      counterparty: counterparty ?? this.counterparty,
      message: message ?? this.message,
      searchText: searchText ?? this.searchText,
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
    if (cardLast4.present) {
      map['card_last4'] = Variable<String>(cardLast4.value);
    }
    if (counterparty.present) {
      map['counterparty'] = Variable<String>(counterparty.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
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
          ..write('cardLast4: $cardLast4, ')
          ..write('counterparty: $counterparty, ')
          ..write('message: $message, ')
          ..write('searchText: $searchText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openingBalanceCentsMeta =
      const VerificationMeta('openingBalanceCents');
  @override
  late final GeneratedColumn<int> openingBalanceCents = GeneratedColumn<int>(
    'opening_balance_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    openingBalanceCents,
    syncedAtMicros,
    skippedRecords,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('opening_balance_cents')) {
      context.handle(
        _openingBalanceCentsMeta,
        openingBalanceCents.isAcceptableOrUnknown(
          data['opening_balance_cents']!,
          _openingBalanceCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingBalanceCentsMeta);
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
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      openingBalanceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance_cents'],
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
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final int id;
  final int openingBalanceCents;
  final int syncedAtMicros;

  /// Records the server sent that could not be read.
  final int skippedRecords;
  const SyncStateRow({
    required this.id,
    required this.openingBalanceCents,
    required this.syncedAtMicros,
    required this.skippedRecords,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['opening_balance_cents'] = Variable<int>(openingBalanceCents);
    map['synced_at_micros'] = Variable<int>(syncedAtMicros);
    map['skipped_records'] = Variable<int>(skippedRecords);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      id: Value(id),
      openingBalanceCents: Value(openingBalanceCents),
      syncedAtMicros: Value(syncedAtMicros),
      skippedRecords: Value(skippedRecords),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      id: serializer.fromJson<int>(json['id']),
      openingBalanceCents: serializer.fromJson<int>(
        json['openingBalanceCents'],
      ),
      syncedAtMicros: serializer.fromJson<int>(json['syncedAtMicros']),
      skippedRecords: serializer.fromJson<int>(json['skippedRecords']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'openingBalanceCents': serializer.toJson<int>(openingBalanceCents),
      'syncedAtMicros': serializer.toJson<int>(syncedAtMicros),
      'skippedRecords': serializer.toJson<int>(skippedRecords),
    };
  }

  SyncStateRow copyWith({
    int? id,
    int? openingBalanceCents,
    int? syncedAtMicros,
    int? skippedRecords,
  }) => SyncStateRow(
    id: id ?? this.id,
    openingBalanceCents: openingBalanceCents ?? this.openingBalanceCents,
    syncedAtMicros: syncedAtMicros ?? this.syncedAtMicros,
    skippedRecords: skippedRecords ?? this.skippedRecords,
  );
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      id: data.id.present ? data.id.value : this.id,
      openingBalanceCents: data.openingBalanceCents.present
          ? data.openingBalanceCents.value
          : this.openingBalanceCents,
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
    return (StringBuffer('SyncStateRow(')
          ..write('id: $id, ')
          ..write('openingBalanceCents: $openingBalanceCents, ')
          ..write('syncedAtMicros: $syncedAtMicros, ')
          ..write('skippedRecords: $skippedRecords')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, openingBalanceCents, syncedAtMicros, skippedRecords);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.id == this.id &&
          other.openingBalanceCents == this.openingBalanceCents &&
          other.syncedAtMicros == this.syncedAtMicros &&
          other.skippedRecords == this.skippedRecords);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<int> id;
  final Value<int> openingBalanceCents;
  final Value<int> syncedAtMicros;
  final Value<int> skippedRecords;
  const SyncStateCompanion({
    this.id = const Value.absent(),
    this.openingBalanceCents = const Value.absent(),
    this.syncedAtMicros = const Value.absent(),
    this.skippedRecords = const Value.absent(),
  });
  SyncStateCompanion.insert({
    this.id = const Value.absent(),
    required int openingBalanceCents,
    required int syncedAtMicros,
    this.skippedRecords = const Value.absent(),
  }) : openingBalanceCents = Value(openingBalanceCents),
       syncedAtMicros = Value(syncedAtMicros);
  static Insertable<SyncStateRow> custom({
    Expression<int>? id,
    Expression<int>? openingBalanceCents,
    Expression<int>? syncedAtMicros,
    Expression<int>? skippedRecords,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (openingBalanceCents != null)
        'opening_balance_cents': openingBalanceCents,
      if (syncedAtMicros != null) 'synced_at_micros': syncedAtMicros,
      if (skippedRecords != null) 'skipped_records': skippedRecords,
    });
  }

  SyncStateCompanion copyWith({
    Value<int>? id,
    Value<int>? openingBalanceCents,
    Value<int>? syncedAtMicros,
    Value<int>? skippedRecords,
  }) {
    return SyncStateCompanion(
      id: id ?? this.id,
      openingBalanceCents: openingBalanceCents ?? this.openingBalanceCents,
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
    if (openingBalanceCents.present) {
      map['opening_balance_cents'] = Variable<int>(openingBalanceCents.value);
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
    return (StringBuffer('SyncStateCompanion(')
          ..write('id: $id, ')
          ..write('openingBalanceCents: $openingBalanceCents, ')
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
  late final $SyncStateTable syncState = $SyncStateTable(this);
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
    syncState,
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
      Value<String?> cardLast4,
      Value<String?> counterparty,
      Value<String?> message,
      required String searchText,
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
      Value<String?> cardLast4,
      Value<String?> counterparty,
      Value<String?> message,
      Value<String> searchText,
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

  ColumnFilters<String> get cardLast4 => $composableBuilder(
    column: $table.cardLast4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
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

  ColumnOrderings<String> get cardLast4 => $composableBuilder(
    column: $table.cardLast4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
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

  GeneratedColumn<String> get cardLast4 =>
      $composableBuilder(column: $table.cardLast4, builder: (column) => column);

  GeneratedColumn<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
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
                Value<String?> cardLast4 = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<String> searchText = const Value.absent(),
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
                cardLast4: cardLast4,
                counterparty: counterparty,
                message: message,
                searchText: searchText,
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
                Value<String?> cardLast4 = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                Value<String?> message = const Value.absent(),
                required String searchText,
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
                cardLast4: cardLast4,
                counterparty: counterparty,
                message: message,
                searchText: searchText,
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
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  Value<int> id,
  required int openingBalanceCents,
  required int syncedAtMicros,
  Value<int> skippedRecords,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<int> id,
  Value<int> openingBalanceCents,
  Value<int> syncedAtMicros,
  Value<int> skippedRecords,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$LedgerDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
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

  ColumnFilters<int> get openingBalanceCents => $composableBuilder(
    column: $table.openingBalanceCents,
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

class $$SyncStateTableOrderingComposer
    extends Composer<_$LedgerDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
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

  ColumnOrderings<int> get openingBalanceCents => $composableBuilder(
    column: $table.openingBalanceCents,
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

class $$SyncStateTableAnnotationComposer
    extends Composer<_$LedgerDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get openingBalanceCents => $composableBuilder(
    column: $table.openingBalanceCents,
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

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$LedgerDatabase,
          $SyncStateTable,
          SyncStateRow,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$LedgerDatabase, $SyncStateTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$LedgerDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> openingBalanceCents = const Value.absent(),
                Value<int> syncedAtMicros = const Value.absent(),
                Value<int> skippedRecords = const Value.absent(),
              }) => SyncStateCompanion(
                id: id,
                openingBalanceCents: openingBalanceCents,
                syncedAtMicros: syncedAtMicros,
                skippedRecords: skippedRecords,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int openingBalanceCents,
                required int syncedAtMicros,
                Value<int> skippedRecords = const Value.absent(),
              }) => SyncStateCompanion.insert(
                id: id,
                openingBalanceCents: openingBalanceCents,
                syncedAtMicros: syncedAtMicros,
                skippedRecords: skippedRecords,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateRow>(table),
                  BaseReferences<
                    _$LedgerDatabase,
                    $SyncStateTable,
                    SyncStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerDatabase,
      $SyncStateTable,
      SyncStateRow,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$LedgerDatabase, $SyncStateTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;

class $LedgerDatabaseManager {
  final _$LedgerDatabase _db;
  $LedgerDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
