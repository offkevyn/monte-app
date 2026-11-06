// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_database.dart';

// ignore_for_file: type=lint
class $CoinsTable extends Coins with TableInfo<$CoinsTable, CoinRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _marketCapRankMeta = const VerificationMeta(
    'marketCapRank',
  );
  @override
  late final GeneratedColumn<int> marketCapRank = GeneratedColumn<int>(
    'market_cap_rank',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceUnitsMeta = const VerificationMeta(
    'priceUnits',
  );
  @override
  late final GeneratedColumn<int> priceUnits = GeneratedColumn<int>(
    'price_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _change24hHundredthsMeta =
      const VerificationMeta('change24hHundredths');
  @override
  late final GeneratedColumn<int> change24hHundredths = GeneratedColumn<int>(
    'change24h_hundredths',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceChange24hUnitsMeta =
      const VerificationMeta('priceChange24hUnits');
  @override
  late final GeneratedColumn<int> priceChange24hUnits = GeneratedColumn<int>(
    'price_change24h_units',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _high24hUnitsMeta = const VerificationMeta(
    'high24hUnits',
  );
  @override
  late final GeneratedColumn<int> high24hUnits = GeneratedColumn<int>(
    'high24h_units',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _low24hUnitsMeta = const VerificationMeta(
    'low24hUnits',
  );
  @override
  late final GeneratedColumn<int> low24hUnits = GeneratedColumn<int>(
    'low24h_units',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _marketCapCentsMeta = const VerificationMeta(
    'marketCapCents',
  );
  @override
  late final GeneratedColumn<int> marketCapCents = GeneratedColumn<int>(
    'market_cap_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalVolumeCentsMeta = const VerificationMeta(
    'totalVolumeCents',
  );
  @override
  late final GeneratedColumn<int> totalVolumeCents = GeneratedColumn<int>(
    'total_volume_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMicrosMeta = const VerificationMeta(
    'updatedAtMicros',
  );
  @override
  late final GeneratedColumn<int> updatedAtMicros = GeneratedColumn<int>(
    'updated_at_micros',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedAtMicrosMeta = const VerificationMeta(
    'savedAtMicros',
  );
  @override
  late final GeneratedColumn<int> savedAtMicros = GeneratedColumn<int>(
    'saved_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    symbol,
    name,
    imageUrl,
    marketCapRank,
    priceUnits,
    change24hHundredths,
    priceChange24hUnits,
    high24hUnits,
    low24hUnits,
    marketCapCents,
    totalVolumeCents,
    updatedAtMicros,
    savedAtMicros,
    searchText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coins';
  @override
  VerificationContext validateIntegrity(
    Insertable<CoinRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('market_cap_rank')) {
      context.handle(
        _marketCapRankMeta,
        marketCapRank.isAcceptableOrUnknown(
          data['market_cap_rank']!,
          _marketCapRankMeta,
        ),
      );
    }
    if (data.containsKey('price_units')) {
      context.handle(
        _priceUnitsMeta,
        priceUnits.isAcceptableOrUnknown(data['price_units']!, _priceUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_priceUnitsMeta);
    }
    if (data.containsKey('change24h_hundredths')) {
      context.handle(
        _change24hHundredthsMeta,
        change24hHundredths.isAcceptableOrUnknown(
          data['change24h_hundredths']!,
          _change24hHundredthsMeta,
        ),
      );
    }
    if (data.containsKey('price_change24h_units')) {
      context.handle(
        _priceChange24hUnitsMeta,
        priceChange24hUnits.isAcceptableOrUnknown(
          data['price_change24h_units']!,
          _priceChange24hUnitsMeta,
        ),
      );
    }
    if (data.containsKey('high24h_units')) {
      context.handle(
        _high24hUnitsMeta,
        high24hUnits.isAcceptableOrUnknown(
          data['high24h_units']!,
          _high24hUnitsMeta,
        ),
      );
    }
    if (data.containsKey('low24h_units')) {
      context.handle(
        _low24hUnitsMeta,
        low24hUnits.isAcceptableOrUnknown(
          data['low24h_units']!,
          _low24hUnitsMeta,
        ),
      );
    }
    if (data.containsKey('market_cap_cents')) {
      context.handle(
        _marketCapCentsMeta,
        marketCapCents.isAcceptableOrUnknown(
          data['market_cap_cents']!,
          _marketCapCentsMeta,
        ),
      );
    }
    if (data.containsKey('total_volume_cents')) {
      context.handle(
        _totalVolumeCentsMeta,
        totalVolumeCents.isAcceptableOrUnknown(
          data['total_volume_cents']!,
          _totalVolumeCentsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_micros')) {
      context.handle(
        _updatedAtMicrosMeta,
        updatedAtMicros.isAcceptableOrUnknown(
          data['updated_at_micros']!,
          _updatedAtMicrosMeta,
        ),
      );
    }
    if (data.containsKey('saved_at_micros')) {
      context.handle(
        _savedAtMicrosMeta,
        savedAtMicros.isAcceptableOrUnknown(
          data['saved_at_micros']!,
          _savedAtMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_savedAtMicrosMeta);
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
  CoinRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoinRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      marketCapRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}market_cap_rank'],
      ),
      priceUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_units'],
      )!,
      change24hHundredths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change24h_hundredths'],
      ),
      priceChange24hUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_change24h_units'],
      ),
      high24hUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}high24h_units'],
      ),
      low24hUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}low24h_units'],
      ),
      marketCapCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}market_cap_cents'],
      ),
      totalVolumeCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_volume_cents'],
      ),
      updatedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_micros'],
      ),
      savedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_at_micros'],
      )!,
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
    );
  }

  @override
  $CoinsTable createAlias(String alias) {
    return $CoinsTable(attachedDatabase, alias);
  }
}

class CoinRow extends DataClass implements Insertable<CoinRow> {
  final String id;
  final String symbol;
  final String name;
  final String? imageUrl;
  final int? marketCapRank;
  final int priceUnits;
  final int? change24hHundredths;
  final int? priceChange24hUnits;
  final int? high24hUnits;
  final int? low24hUnits;
  final int? marketCapCents;
  final int? totalVolumeCents;
  final int? updatedAtMicros;

  /// When the app saved these numbers (decides if they are still fresh).
  final int savedAtMicros;

  /// Name and symbol in lower case without accents, for the offline search.
  final String searchText;
  const CoinRow({
    required this.id,
    required this.symbol,
    required this.name,
    this.imageUrl,
    this.marketCapRank,
    required this.priceUnits,
    this.change24hHundredths,
    this.priceChange24hUnits,
    this.high24hUnits,
    this.low24hUnits,
    this.marketCapCents,
    this.totalVolumeCents,
    this.updatedAtMicros,
    required this.savedAtMicros,
    required this.searchText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['symbol'] = Variable<String>(symbol);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || marketCapRank != null) {
      map['market_cap_rank'] = Variable<int>(marketCapRank);
    }
    map['price_units'] = Variable<int>(priceUnits);
    if (!nullToAbsent || change24hHundredths != null) {
      map['change24h_hundredths'] = Variable<int>(change24hHundredths);
    }
    if (!nullToAbsent || priceChange24hUnits != null) {
      map['price_change24h_units'] = Variable<int>(priceChange24hUnits);
    }
    if (!nullToAbsent || high24hUnits != null) {
      map['high24h_units'] = Variable<int>(high24hUnits);
    }
    if (!nullToAbsent || low24hUnits != null) {
      map['low24h_units'] = Variable<int>(low24hUnits);
    }
    if (!nullToAbsent || marketCapCents != null) {
      map['market_cap_cents'] = Variable<int>(marketCapCents);
    }
    if (!nullToAbsent || totalVolumeCents != null) {
      map['total_volume_cents'] = Variable<int>(totalVolumeCents);
    }
    if (!nullToAbsent || updatedAtMicros != null) {
      map['updated_at_micros'] = Variable<int>(updatedAtMicros);
    }
    map['saved_at_micros'] = Variable<int>(savedAtMicros);
    map['search_text'] = Variable<String>(searchText);
    return map;
  }

  CoinsCompanion toCompanion(bool nullToAbsent) {
    return CoinsCompanion(
      id: Value(id),
      symbol: Value(symbol),
      name: Value(name),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      marketCapRank: marketCapRank == null && nullToAbsent
          ? const Value.absent()
          : Value(marketCapRank),
      priceUnits: Value(priceUnits),
      change24hHundredths: change24hHundredths == null && nullToAbsent
          ? const Value.absent()
          : Value(change24hHundredths),
      priceChange24hUnits: priceChange24hUnits == null && nullToAbsent
          ? const Value.absent()
          : Value(priceChange24hUnits),
      high24hUnits: high24hUnits == null && nullToAbsent
          ? const Value.absent()
          : Value(high24hUnits),
      low24hUnits: low24hUnits == null && nullToAbsent
          ? const Value.absent()
          : Value(low24hUnits),
      marketCapCents: marketCapCents == null && nullToAbsent
          ? const Value.absent()
          : Value(marketCapCents),
      totalVolumeCents: totalVolumeCents == null && nullToAbsent
          ? const Value.absent()
          : Value(totalVolumeCents),
      updatedAtMicros: updatedAtMicros == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAtMicros),
      savedAtMicros: Value(savedAtMicros),
      searchText: Value(searchText),
    );
  }

  factory CoinRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoinRow(
      id: serializer.fromJson<String>(json['id']),
      symbol: serializer.fromJson<String>(json['symbol']),
      name: serializer.fromJson<String>(json['name']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      marketCapRank: serializer.fromJson<int?>(json['marketCapRank']),
      priceUnits: serializer.fromJson<int>(json['priceUnits']),
      change24hHundredths: serializer.fromJson<int?>(
        json['change24hHundredths'],
      ),
      priceChange24hUnits: serializer.fromJson<int?>(
        json['priceChange24hUnits'],
      ),
      high24hUnits: serializer.fromJson<int?>(json['high24hUnits']),
      low24hUnits: serializer.fromJson<int?>(json['low24hUnits']),
      marketCapCents: serializer.fromJson<int?>(json['marketCapCents']),
      totalVolumeCents: serializer.fromJson<int?>(json['totalVolumeCents']),
      updatedAtMicros: serializer.fromJson<int?>(json['updatedAtMicros']),
      savedAtMicros: serializer.fromJson<int>(json['savedAtMicros']),
      searchText: serializer.fromJson<String>(json['searchText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'symbol': serializer.toJson<String>(symbol),
      'name': serializer.toJson<String>(name),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'marketCapRank': serializer.toJson<int?>(marketCapRank),
      'priceUnits': serializer.toJson<int>(priceUnits),
      'change24hHundredths': serializer.toJson<int?>(change24hHundredths),
      'priceChange24hUnits': serializer.toJson<int?>(priceChange24hUnits),
      'high24hUnits': serializer.toJson<int?>(high24hUnits),
      'low24hUnits': serializer.toJson<int?>(low24hUnits),
      'marketCapCents': serializer.toJson<int?>(marketCapCents),
      'totalVolumeCents': serializer.toJson<int?>(totalVolumeCents),
      'updatedAtMicros': serializer.toJson<int?>(updatedAtMicros),
      'savedAtMicros': serializer.toJson<int>(savedAtMicros),
      'searchText': serializer.toJson<String>(searchText),
    };
  }

  CoinRow copyWith({
    String? id,
    String? symbol,
    String? name,
    Value<String?> imageUrl = const Value.absent(),
    Value<int?> marketCapRank = const Value.absent(),
    int? priceUnits,
    Value<int?> change24hHundredths = const Value.absent(),
    Value<int?> priceChange24hUnits = const Value.absent(),
    Value<int?> high24hUnits = const Value.absent(),
    Value<int?> low24hUnits = const Value.absent(),
    Value<int?> marketCapCents = const Value.absent(),
    Value<int?> totalVolumeCents = const Value.absent(),
    Value<int?> updatedAtMicros = const Value.absent(),
    int? savedAtMicros,
    String? searchText,
  }) => CoinRow(
    id: id ?? this.id,
    symbol: symbol ?? this.symbol,
    name: name ?? this.name,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    marketCapRank: marketCapRank.present
        ? marketCapRank.value
        : this.marketCapRank,
    priceUnits: priceUnits ?? this.priceUnits,
    change24hHundredths: change24hHundredths.present
        ? change24hHundredths.value
        : this.change24hHundredths,
    priceChange24hUnits: priceChange24hUnits.present
        ? priceChange24hUnits.value
        : this.priceChange24hUnits,
    high24hUnits: high24hUnits.present ? high24hUnits.value : this.high24hUnits,
    low24hUnits: low24hUnits.present ? low24hUnits.value : this.low24hUnits,
    marketCapCents: marketCapCents.present
        ? marketCapCents.value
        : this.marketCapCents,
    totalVolumeCents: totalVolumeCents.present
        ? totalVolumeCents.value
        : this.totalVolumeCents,
    updatedAtMicros: updatedAtMicros.present
        ? updatedAtMicros.value
        : this.updatedAtMicros,
    savedAtMicros: savedAtMicros ?? this.savedAtMicros,
    searchText: searchText ?? this.searchText,
  );
  CoinRow copyWithCompanion(CoinsCompanion data) {
    return CoinRow(
      id: data.id.present ? data.id.value : this.id,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      name: data.name.present ? data.name.value : this.name,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      marketCapRank: data.marketCapRank.present
          ? data.marketCapRank.value
          : this.marketCapRank,
      priceUnits: data.priceUnits.present
          ? data.priceUnits.value
          : this.priceUnits,
      change24hHundredths: data.change24hHundredths.present
          ? data.change24hHundredths.value
          : this.change24hHundredths,
      priceChange24hUnits: data.priceChange24hUnits.present
          ? data.priceChange24hUnits.value
          : this.priceChange24hUnits,
      high24hUnits: data.high24hUnits.present
          ? data.high24hUnits.value
          : this.high24hUnits,
      low24hUnits: data.low24hUnits.present
          ? data.low24hUnits.value
          : this.low24hUnits,
      marketCapCents: data.marketCapCents.present
          ? data.marketCapCents.value
          : this.marketCapCents,
      totalVolumeCents: data.totalVolumeCents.present
          ? data.totalVolumeCents.value
          : this.totalVolumeCents,
      updatedAtMicros: data.updatedAtMicros.present
          ? data.updatedAtMicros.value
          : this.updatedAtMicros,
      savedAtMicros: data.savedAtMicros.present
          ? data.savedAtMicros.value
          : this.savedAtMicros,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoinRow(')
          ..write('id: $id, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('marketCapRank: $marketCapRank, ')
          ..write('priceUnits: $priceUnits, ')
          ..write('change24hHundredths: $change24hHundredths, ')
          ..write('priceChange24hUnits: $priceChange24hUnits, ')
          ..write('high24hUnits: $high24hUnits, ')
          ..write('low24hUnits: $low24hUnits, ')
          ..write('marketCapCents: $marketCapCents, ')
          ..write('totalVolumeCents: $totalVolumeCents, ')
          ..write('updatedAtMicros: $updatedAtMicros, ')
          ..write('savedAtMicros: $savedAtMicros, ')
          ..write('searchText: $searchText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    symbol,
    name,
    imageUrl,
    marketCapRank,
    priceUnits,
    change24hHundredths,
    priceChange24hUnits,
    high24hUnits,
    low24hUnits,
    marketCapCents,
    totalVolumeCents,
    updatedAtMicros,
    savedAtMicros,
    searchText,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoinRow &&
          other.id == this.id &&
          other.symbol == this.symbol &&
          other.name == this.name &&
          other.imageUrl == this.imageUrl &&
          other.marketCapRank == this.marketCapRank &&
          other.priceUnits == this.priceUnits &&
          other.change24hHundredths == this.change24hHundredths &&
          other.priceChange24hUnits == this.priceChange24hUnits &&
          other.high24hUnits == this.high24hUnits &&
          other.low24hUnits == this.low24hUnits &&
          other.marketCapCents == this.marketCapCents &&
          other.totalVolumeCents == this.totalVolumeCents &&
          other.updatedAtMicros == this.updatedAtMicros &&
          other.savedAtMicros == this.savedAtMicros &&
          other.searchText == this.searchText);
}

class CoinsCompanion extends UpdateCompanion<CoinRow> {
  final Value<String> id;
  final Value<String> symbol;
  final Value<String> name;
  final Value<String?> imageUrl;
  final Value<int?> marketCapRank;
  final Value<int> priceUnits;
  final Value<int?> change24hHundredths;
  final Value<int?> priceChange24hUnits;
  final Value<int?> high24hUnits;
  final Value<int?> low24hUnits;
  final Value<int?> marketCapCents;
  final Value<int?> totalVolumeCents;
  final Value<int?> updatedAtMicros;
  final Value<int> savedAtMicros;
  final Value<String> searchText;
  final Value<int> rowid;
  const CoinsCompanion({
    this.id = const Value.absent(),
    this.symbol = const Value.absent(),
    this.name = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.marketCapRank = const Value.absent(),
    this.priceUnits = const Value.absent(),
    this.change24hHundredths = const Value.absent(),
    this.priceChange24hUnits = const Value.absent(),
    this.high24hUnits = const Value.absent(),
    this.low24hUnits = const Value.absent(),
    this.marketCapCents = const Value.absent(),
    this.totalVolumeCents = const Value.absent(),
    this.updatedAtMicros = const Value.absent(),
    this.savedAtMicros = const Value.absent(),
    this.searchText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoinsCompanion.insert({
    required String id,
    required String symbol,
    required String name,
    this.imageUrl = const Value.absent(),
    this.marketCapRank = const Value.absent(),
    required int priceUnits,
    this.change24hHundredths = const Value.absent(),
    this.priceChange24hUnits = const Value.absent(),
    this.high24hUnits = const Value.absent(),
    this.low24hUnits = const Value.absent(),
    this.marketCapCents = const Value.absent(),
    this.totalVolumeCents = const Value.absent(),
    this.updatedAtMicros = const Value.absent(),
    required int savedAtMicros,
    required String searchText,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       symbol = Value(symbol),
       name = Value(name),
       priceUnits = Value(priceUnits),
       savedAtMicros = Value(savedAtMicros),
       searchText = Value(searchText);
  static Insertable<CoinRow> custom({
    Expression<String>? id,
    Expression<String>? symbol,
    Expression<String>? name,
    Expression<String>? imageUrl,
    Expression<int>? marketCapRank,
    Expression<int>? priceUnits,
    Expression<int>? change24hHundredths,
    Expression<int>? priceChange24hUnits,
    Expression<int>? high24hUnits,
    Expression<int>? low24hUnits,
    Expression<int>? marketCapCents,
    Expression<int>? totalVolumeCents,
    Expression<int>? updatedAtMicros,
    Expression<int>? savedAtMicros,
    Expression<String>? searchText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (symbol != null) 'symbol': symbol,
      if (name != null) 'name': name,
      if (imageUrl != null) 'image_url': imageUrl,
      if (marketCapRank != null) 'market_cap_rank': marketCapRank,
      if (priceUnits != null) 'price_units': priceUnits,
      if (change24hHundredths != null)
        'change24h_hundredths': change24hHundredths,
      if (priceChange24hUnits != null)
        'price_change24h_units': priceChange24hUnits,
      if (high24hUnits != null) 'high24h_units': high24hUnits,
      if (low24hUnits != null) 'low24h_units': low24hUnits,
      if (marketCapCents != null) 'market_cap_cents': marketCapCents,
      if (totalVolumeCents != null) 'total_volume_cents': totalVolumeCents,
      if (updatedAtMicros != null) 'updated_at_micros': updatedAtMicros,
      if (savedAtMicros != null) 'saved_at_micros': savedAtMicros,
      if (searchText != null) 'search_text': searchText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoinsCompanion copyWith({
    Value<String>? id,
    Value<String>? symbol,
    Value<String>? name,
    Value<String?>? imageUrl,
    Value<int?>? marketCapRank,
    Value<int>? priceUnits,
    Value<int?>? change24hHundredths,
    Value<int?>? priceChange24hUnits,
    Value<int?>? high24hUnits,
    Value<int?>? low24hUnits,
    Value<int?>? marketCapCents,
    Value<int?>? totalVolumeCents,
    Value<int?>? updatedAtMicros,
    Value<int>? savedAtMicros,
    Value<String>? searchText,
    Value<int>? rowid,
  }) {
    return CoinsCompanion(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      marketCapRank: marketCapRank ?? this.marketCapRank,
      priceUnits: priceUnits ?? this.priceUnits,
      change24hHundredths: change24hHundredths ?? this.change24hHundredths,
      priceChange24hUnits: priceChange24hUnits ?? this.priceChange24hUnits,
      high24hUnits: high24hUnits ?? this.high24hUnits,
      low24hUnits: low24hUnits ?? this.low24hUnits,
      marketCapCents: marketCapCents ?? this.marketCapCents,
      totalVolumeCents: totalVolumeCents ?? this.totalVolumeCents,
      updatedAtMicros: updatedAtMicros ?? this.updatedAtMicros,
      savedAtMicros: savedAtMicros ?? this.savedAtMicros,
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
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (marketCapRank.present) {
      map['market_cap_rank'] = Variable<int>(marketCapRank.value);
    }
    if (priceUnits.present) {
      map['price_units'] = Variable<int>(priceUnits.value);
    }
    if (change24hHundredths.present) {
      map['change24h_hundredths'] = Variable<int>(change24hHundredths.value);
    }
    if (priceChange24hUnits.present) {
      map['price_change24h_units'] = Variable<int>(priceChange24hUnits.value);
    }
    if (high24hUnits.present) {
      map['high24h_units'] = Variable<int>(high24hUnits.value);
    }
    if (low24hUnits.present) {
      map['low24h_units'] = Variable<int>(low24hUnits.value);
    }
    if (marketCapCents.present) {
      map['market_cap_cents'] = Variable<int>(marketCapCents.value);
    }
    if (totalVolumeCents.present) {
      map['total_volume_cents'] = Variable<int>(totalVolumeCents.value);
    }
    if (updatedAtMicros.present) {
      map['updated_at_micros'] = Variable<int>(updatedAtMicros.value);
    }
    if (savedAtMicros.present) {
      map['saved_at_micros'] = Variable<int>(savedAtMicros.value);
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
    return (StringBuffer('CoinsCompanion(')
          ..write('id: $id, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('marketCapRank: $marketCapRank, ')
          ..write('priceUnits: $priceUnits, ')
          ..write('change24hHundredths: $change24hHundredths, ')
          ..write('priceChange24hUnits: $priceChange24hUnits, ')
          ..write('high24hUnits: $high24hUnits, ')
          ..write('low24hUnits: $low24hUnits, ')
          ..write('marketCapCents: $marketCapCents, ')
          ..write('totalVolumeCents: $totalVolumeCents, ')
          ..write('updatedAtMicros: $updatedAtMicros, ')
          ..write('savedAtMicros: $savedAtMicros, ')
          ..write('searchText: $searchText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListEntriesTable extends ListEntries
    with TableInfo<$ListEntriesTable, ListEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _listNameMeta = const VerificationMeta(
    'listName',
  );
  @override
  late final GeneratedColumn<String> listName = GeneratedColumn<String>(
    'list_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coinIdMeta = const VerificationMeta('coinId');
  @override
  late final GeneratedColumn<String> coinId = GeneratedColumn<String>(
    'coin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [listName, page, position, coinId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'list_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('list_name')) {
      context.handle(
        _listNameMeta,
        listName.isAcceptableOrUnknown(data['list_name']!, _listNameMeta),
      );
    } else if (isInserting) {
      context.missing(_listNameMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('coin_id')) {
      context.handle(
        _coinIdMeta,
        coinId.isAcceptableOrUnknown(data['coin_id']!, _coinIdMeta),
      );
    } else if (isInserting) {
      context.missing(_coinIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {listName, page, position};
  @override
  ListEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListEntryRow(
      listName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_name'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      coinId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coin_id'],
      )!,
    );
  }

  @override
  $ListEntriesTable createAlias(String alias) {
    return $ListEntriesTable(attachedDatabase, alias);
  }
}

class ListEntryRow extends DataClass implements Insertable<ListEntryRow> {
  /// `mostTraded` or `trending`.
  final String listName;
  final int page;
  final int position;
  final String coinId;
  const ListEntryRow({
    required this.listName,
    required this.page,
    required this.position,
    required this.coinId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['list_name'] = Variable<String>(listName);
    map['page'] = Variable<int>(page);
    map['position'] = Variable<int>(position);
    map['coin_id'] = Variable<String>(coinId);
    return map;
  }

  ListEntriesCompanion toCompanion(bool nullToAbsent) {
    return ListEntriesCompanion(
      listName: Value(listName),
      page: Value(page),
      position: Value(position),
      coinId: Value(coinId),
    );
  }

  factory ListEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListEntryRow(
      listName: serializer.fromJson<String>(json['listName']),
      page: serializer.fromJson<int>(json['page']),
      position: serializer.fromJson<int>(json['position']),
      coinId: serializer.fromJson<String>(json['coinId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'listName': serializer.toJson<String>(listName),
      'page': serializer.toJson<int>(page),
      'position': serializer.toJson<int>(position),
      'coinId': serializer.toJson<String>(coinId),
    };
  }

  ListEntryRow copyWith({
    String? listName,
    int? page,
    int? position,
    String? coinId,
  }) => ListEntryRow(
    listName: listName ?? this.listName,
    page: page ?? this.page,
    position: position ?? this.position,
    coinId: coinId ?? this.coinId,
  );
  ListEntryRow copyWithCompanion(ListEntriesCompanion data) {
    return ListEntryRow(
      listName: data.listName.present ? data.listName.value : this.listName,
      page: data.page.present ? data.page.value : this.page,
      position: data.position.present ? data.position.value : this.position,
      coinId: data.coinId.present ? data.coinId.value : this.coinId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListEntryRow(')
          ..write('listName: $listName, ')
          ..write('page: $page, ')
          ..write('position: $position, ')
          ..write('coinId: $coinId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(listName, page, position, coinId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListEntryRow &&
          other.listName == this.listName &&
          other.page == this.page &&
          other.position == this.position &&
          other.coinId == this.coinId);
}

class ListEntriesCompanion extends UpdateCompanion<ListEntryRow> {
  final Value<String> listName;
  final Value<int> page;
  final Value<int> position;
  final Value<String> coinId;
  final Value<int> rowid;
  const ListEntriesCompanion({
    this.listName = const Value.absent(),
    this.page = const Value.absent(),
    this.position = const Value.absent(),
    this.coinId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListEntriesCompanion.insert({
    required String listName,
    required int page,
    required int position,
    required String coinId,
    this.rowid = const Value.absent(),
  }) : listName = Value(listName),
       page = Value(page),
       position = Value(position),
       coinId = Value(coinId);
  static Insertable<ListEntryRow> custom({
    Expression<String>? listName,
    Expression<int>? page,
    Expression<int>? position,
    Expression<String>? coinId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (listName != null) 'list_name': listName,
      if (page != null) 'page': page,
      if (position != null) 'position': position,
      if (coinId != null) 'coin_id': coinId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListEntriesCompanion copyWith({
    Value<String>? listName,
    Value<int>? page,
    Value<int>? position,
    Value<String>? coinId,
    Value<int>? rowid,
  }) {
    return ListEntriesCompanion(
      listName: listName ?? this.listName,
      page: page ?? this.page,
      position: position ?? this.position,
      coinId: coinId ?? this.coinId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (listName.present) {
      map['list_name'] = Variable<String>(listName.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (coinId.present) {
      map['coin_id'] = Variable<String>(coinId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListEntriesCompanion(')
          ..write('listName: $listName, ')
          ..write('page: $page, ')
          ..write('position: $position, ')
          ..write('coinId: $coinId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListPagesTable extends ListPages
    with TableInfo<$ListPagesTable, ListPageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListPagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _listNameMeta = const VerificationMeta(
    'listName',
  );
  @override
  late final GeneratedColumn<String> listName = GeneratedColumn<String>(
    'list_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
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
  static const VerificationMeta _hasMoreMeta = const VerificationMeta(
    'hasMore',
  );
  @override
  late final GeneratedColumn<bool> hasMore = GeneratedColumn<bool>(
    'has_more',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_more" IN (0, 1))',
    ),
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
    listName,
    page,
    syncedAtMicros,
    hasMore,
    skippedRecords,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'list_pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListPageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('list_name')) {
      context.handle(
        _listNameMeta,
        listName.isAcceptableOrUnknown(data['list_name']!, _listNameMeta),
      );
    } else if (isInserting) {
      context.missing(_listNameMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
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
    if (data.containsKey('has_more')) {
      context.handle(
        _hasMoreMeta,
        hasMore.isAcceptableOrUnknown(data['has_more']!, _hasMoreMeta),
      );
    } else if (isInserting) {
      context.missing(_hasMoreMeta);
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
  Set<GeneratedColumn> get $primaryKey => {listName, page};
  @override
  ListPageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListPageRow(
      listName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_name'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      syncedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at_micros'],
      )!,
      hasMore: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_more'],
      )!,
      skippedRecords: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skipped_records'],
      )!,
    );
  }

  @override
  $ListPagesTable createAlias(String alias) {
    return $ListPagesTable(attachedDatabase, alias);
  }
}

class ListPageRow extends DataClass implements Insertable<ListPageRow> {
  final String listName;
  final int page;
  final int syncedAtMicros;
  final bool hasMore;
  final int skippedRecords;
  const ListPageRow({
    required this.listName,
    required this.page,
    required this.syncedAtMicros,
    required this.hasMore,
    required this.skippedRecords,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['list_name'] = Variable<String>(listName);
    map['page'] = Variable<int>(page);
    map['synced_at_micros'] = Variable<int>(syncedAtMicros);
    map['has_more'] = Variable<bool>(hasMore);
    map['skipped_records'] = Variable<int>(skippedRecords);
    return map;
  }

  ListPagesCompanion toCompanion(bool nullToAbsent) {
    return ListPagesCompanion(
      listName: Value(listName),
      page: Value(page),
      syncedAtMicros: Value(syncedAtMicros),
      hasMore: Value(hasMore),
      skippedRecords: Value(skippedRecords),
    );
  }

  factory ListPageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListPageRow(
      listName: serializer.fromJson<String>(json['listName']),
      page: serializer.fromJson<int>(json['page']),
      syncedAtMicros: serializer.fromJson<int>(json['syncedAtMicros']),
      hasMore: serializer.fromJson<bool>(json['hasMore']),
      skippedRecords: serializer.fromJson<int>(json['skippedRecords']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'listName': serializer.toJson<String>(listName),
      'page': serializer.toJson<int>(page),
      'syncedAtMicros': serializer.toJson<int>(syncedAtMicros),
      'hasMore': serializer.toJson<bool>(hasMore),
      'skippedRecords': serializer.toJson<int>(skippedRecords),
    };
  }

  ListPageRow copyWith({
    String? listName,
    int? page,
    int? syncedAtMicros,
    bool? hasMore,
    int? skippedRecords,
  }) => ListPageRow(
    listName: listName ?? this.listName,
    page: page ?? this.page,
    syncedAtMicros: syncedAtMicros ?? this.syncedAtMicros,
    hasMore: hasMore ?? this.hasMore,
    skippedRecords: skippedRecords ?? this.skippedRecords,
  );
  ListPageRow copyWithCompanion(ListPagesCompanion data) {
    return ListPageRow(
      listName: data.listName.present ? data.listName.value : this.listName,
      page: data.page.present ? data.page.value : this.page,
      syncedAtMicros: data.syncedAtMicros.present
          ? data.syncedAtMicros.value
          : this.syncedAtMicros,
      hasMore: data.hasMore.present ? data.hasMore.value : this.hasMore,
      skippedRecords: data.skippedRecords.present
          ? data.skippedRecords.value
          : this.skippedRecords,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListPageRow(')
          ..write('listName: $listName, ')
          ..write('page: $page, ')
          ..write('syncedAtMicros: $syncedAtMicros, ')
          ..write('hasMore: $hasMore, ')
          ..write('skippedRecords: $skippedRecords')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(listName, page, syncedAtMicros, hasMore, skippedRecords);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListPageRow &&
          other.listName == this.listName &&
          other.page == this.page &&
          other.syncedAtMicros == this.syncedAtMicros &&
          other.hasMore == this.hasMore &&
          other.skippedRecords == this.skippedRecords);
}

class ListPagesCompanion extends UpdateCompanion<ListPageRow> {
  final Value<String> listName;
  final Value<int> page;
  final Value<int> syncedAtMicros;
  final Value<bool> hasMore;
  final Value<int> skippedRecords;
  final Value<int> rowid;
  const ListPagesCompanion({
    this.listName = const Value.absent(),
    this.page = const Value.absent(),
    this.syncedAtMicros = const Value.absent(),
    this.hasMore = const Value.absent(),
    this.skippedRecords = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListPagesCompanion.insert({
    required String listName,
    required int page,
    required int syncedAtMicros,
    required bool hasMore,
    this.skippedRecords = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : listName = Value(listName),
       page = Value(page),
       syncedAtMicros = Value(syncedAtMicros),
       hasMore = Value(hasMore);
  static Insertable<ListPageRow> custom({
    Expression<String>? listName,
    Expression<int>? page,
    Expression<int>? syncedAtMicros,
    Expression<bool>? hasMore,
    Expression<int>? skippedRecords,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (listName != null) 'list_name': listName,
      if (page != null) 'page': page,
      if (syncedAtMicros != null) 'synced_at_micros': syncedAtMicros,
      if (hasMore != null) 'has_more': hasMore,
      if (skippedRecords != null) 'skipped_records': skippedRecords,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListPagesCompanion copyWith({
    Value<String>? listName,
    Value<int>? page,
    Value<int>? syncedAtMicros,
    Value<bool>? hasMore,
    Value<int>? skippedRecords,
    Value<int>? rowid,
  }) {
    return ListPagesCompanion(
      listName: listName ?? this.listName,
      page: page ?? this.page,
      syncedAtMicros: syncedAtMicros ?? this.syncedAtMicros,
      hasMore: hasMore ?? this.hasMore,
      skippedRecords: skippedRecords ?? this.skippedRecords,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (listName.present) {
      map['list_name'] = Variable<String>(listName.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (syncedAtMicros.present) {
      map['synced_at_micros'] = Variable<int>(syncedAtMicros.value);
    }
    if (hasMore.present) {
      map['has_more'] = Variable<bool>(hasMore.value);
    }
    if (skippedRecords.present) {
      map['skipped_records'] = Variable<int>(skippedRecords.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListPagesCompanion(')
          ..write('listName: $listName, ')
          ..write('page: $page, ')
          ..write('syncedAtMicros: $syncedAtMicros, ')
          ..write('hasMore: $hasMore, ')
          ..write('skippedRecords: $skippedRecords, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, FavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _coinIdMeta = const VerificationMeta('coinId');
  @override
  late final GeneratedColumn<String> coinId = GeneratedColumn<String>(
    'coin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMicrosMeta = const VerificationMeta(
    'addedAtMicros',
  );
  @override
  late final GeneratedColumn<int> addedAtMicros = GeneratedColumn<int>(
    'added_at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [coinId, addedAtMicros];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('coin_id')) {
      context.handle(
        _coinIdMeta,
        coinId.isAcceptableOrUnknown(data['coin_id']!, _coinIdMeta),
      );
    } else if (isInserting) {
      context.missing(_coinIdMeta);
    }
    if (data.containsKey('added_at_micros')) {
      context.handle(
        _addedAtMicrosMeta,
        addedAtMicros.isAcceptableOrUnknown(
          data['added_at_micros']!,
          _addedAtMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_addedAtMicrosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {coinId};
  @override
  FavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteRow(
      coinId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coin_id'],
      )!,
      addedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at_micros'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class FavoriteRow extends DataClass implements Insertable<FavoriteRow> {
  final String coinId;
  final int addedAtMicros;
  const FavoriteRow({required this.coinId, required this.addedAtMicros});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['coin_id'] = Variable<String>(coinId);
    map['added_at_micros'] = Variable<int>(addedAtMicros);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      coinId: Value(coinId),
      addedAtMicros: Value(addedAtMicros),
    );
  }

  factory FavoriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteRow(
      coinId: serializer.fromJson<String>(json['coinId']),
      addedAtMicros: serializer.fromJson<int>(json['addedAtMicros']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'coinId': serializer.toJson<String>(coinId),
      'addedAtMicros': serializer.toJson<int>(addedAtMicros),
    };
  }

  FavoriteRow copyWith({String? coinId, int? addedAtMicros}) => FavoriteRow(
    coinId: coinId ?? this.coinId,
    addedAtMicros: addedAtMicros ?? this.addedAtMicros,
  );
  FavoriteRow copyWithCompanion(FavoritesCompanion data) {
    return FavoriteRow(
      coinId: data.coinId.present ? data.coinId.value : this.coinId,
      addedAtMicros: data.addedAtMicros.present
          ? data.addedAtMicros.value
          : this.addedAtMicros,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteRow(')
          ..write('coinId: $coinId, ')
          ..write('addedAtMicros: $addedAtMicros')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(coinId, addedAtMicros);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteRow &&
          other.coinId == this.coinId &&
          other.addedAtMicros == this.addedAtMicros);
}

class FavoritesCompanion extends UpdateCompanion<FavoriteRow> {
  final Value<String> coinId;
  final Value<int> addedAtMicros;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.coinId = const Value.absent(),
    this.addedAtMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required String coinId,
    required int addedAtMicros,
    this.rowid = const Value.absent(),
  }) : coinId = Value(coinId),
       addedAtMicros = Value(addedAtMicros);
  static Insertable<FavoriteRow> custom({
    Expression<String>? coinId,
    Expression<int>? addedAtMicros,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (coinId != null) 'coin_id': coinId,
      if (addedAtMicros != null) 'added_at_micros': addedAtMicros,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({
    Value<String>? coinId,
    Value<int>? addedAtMicros,
    Value<int>? rowid,
  }) {
    return FavoritesCompanion(
      coinId: coinId ?? this.coinId,
      addedAtMicros: addedAtMicros ?? this.addedAtMicros,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (coinId.present) {
      map['coin_id'] = Variable<String>(coinId.value);
    }
    if (addedAtMicros.present) {
      map['added_at_micros'] = Variable<int>(addedAtMicros.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('coinId: $coinId, ')
          ..write('addedAtMicros: $addedAtMicros, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChartPointsTable extends ChartPoints
    with TableInfo<$ChartPointsTable, ChartPointRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChartPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _coinIdMeta = const VerificationMeta('coinId');
  @override
  late final GeneratedColumn<String> coinId = GeneratedColumn<String>(
    'coin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rangeMeta = const VerificationMeta('range');
  @override
  late final GeneratedColumn<String> range = GeneratedColumn<String>(
    'range',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMicrosMeta = const VerificationMeta(
    'atMicros',
  );
  @override
  late final GeneratedColumn<int> atMicros = GeneratedColumn<int>(
    'at_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceUnitsMeta = const VerificationMeta(
    'priceUnits',
  );
  @override
  late final GeneratedColumn<int> priceUnits = GeneratedColumn<int>(
    'price_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [coinId, range, atMicros, priceUnits];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chart_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChartPointRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('coin_id')) {
      context.handle(
        _coinIdMeta,
        coinId.isAcceptableOrUnknown(data['coin_id']!, _coinIdMeta),
      );
    } else if (isInserting) {
      context.missing(_coinIdMeta);
    }
    if (data.containsKey('range')) {
      context.handle(
        _rangeMeta,
        range.isAcceptableOrUnknown(data['range']!, _rangeMeta),
      );
    } else if (isInserting) {
      context.missing(_rangeMeta);
    }
    if (data.containsKey('at_micros')) {
      context.handle(
        _atMicrosMeta,
        atMicros.isAcceptableOrUnknown(data['at_micros']!, _atMicrosMeta),
      );
    } else if (isInserting) {
      context.missing(_atMicrosMeta);
    }
    if (data.containsKey('price_units')) {
      context.handle(
        _priceUnitsMeta,
        priceUnits.isAcceptableOrUnknown(data['price_units']!, _priceUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_priceUnitsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {coinId, range, atMicros};
  @override
  ChartPointRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChartPointRow(
      coinId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coin_id'],
      )!,
      range: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}range'],
      )!,
      atMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at_micros'],
      )!,
      priceUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_units'],
      )!,
    );
  }

  @override
  $ChartPointsTable createAlias(String alias) {
    return $ChartPointsTable(attachedDatabase, alias);
  }
}

class ChartPointRow extends DataClass implements Insertable<ChartPointRow> {
  final String coinId;

  /// `day`, `week`, `month` or `year`.
  final String range;
  final int atMicros;
  final int priceUnits;
  const ChartPointRow({
    required this.coinId,
    required this.range,
    required this.atMicros,
    required this.priceUnits,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['coin_id'] = Variable<String>(coinId);
    map['range'] = Variable<String>(range);
    map['at_micros'] = Variable<int>(atMicros);
    map['price_units'] = Variable<int>(priceUnits);
    return map;
  }

  ChartPointsCompanion toCompanion(bool nullToAbsent) {
    return ChartPointsCompanion(
      coinId: Value(coinId),
      range: Value(range),
      atMicros: Value(atMicros),
      priceUnits: Value(priceUnits),
    );
  }

  factory ChartPointRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChartPointRow(
      coinId: serializer.fromJson<String>(json['coinId']),
      range: serializer.fromJson<String>(json['range']),
      atMicros: serializer.fromJson<int>(json['atMicros']),
      priceUnits: serializer.fromJson<int>(json['priceUnits']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'coinId': serializer.toJson<String>(coinId),
      'range': serializer.toJson<String>(range),
      'atMicros': serializer.toJson<int>(atMicros),
      'priceUnits': serializer.toJson<int>(priceUnits),
    };
  }

  ChartPointRow copyWith({
    String? coinId,
    String? range,
    int? atMicros,
    int? priceUnits,
  }) => ChartPointRow(
    coinId: coinId ?? this.coinId,
    range: range ?? this.range,
    atMicros: atMicros ?? this.atMicros,
    priceUnits: priceUnits ?? this.priceUnits,
  );
  ChartPointRow copyWithCompanion(ChartPointsCompanion data) {
    return ChartPointRow(
      coinId: data.coinId.present ? data.coinId.value : this.coinId,
      range: data.range.present ? data.range.value : this.range,
      atMicros: data.atMicros.present ? data.atMicros.value : this.atMicros,
      priceUnits: data.priceUnits.present
          ? data.priceUnits.value
          : this.priceUnits,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChartPointRow(')
          ..write('coinId: $coinId, ')
          ..write('range: $range, ')
          ..write('atMicros: $atMicros, ')
          ..write('priceUnits: $priceUnits')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(coinId, range, atMicros, priceUnits);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChartPointRow &&
          other.coinId == this.coinId &&
          other.range == this.range &&
          other.atMicros == this.atMicros &&
          other.priceUnits == this.priceUnits);
}

class ChartPointsCompanion extends UpdateCompanion<ChartPointRow> {
  final Value<String> coinId;
  final Value<String> range;
  final Value<int> atMicros;
  final Value<int> priceUnits;
  final Value<int> rowid;
  const ChartPointsCompanion({
    this.coinId = const Value.absent(),
    this.range = const Value.absent(),
    this.atMicros = const Value.absent(),
    this.priceUnits = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChartPointsCompanion.insert({
    required String coinId,
    required String range,
    required int atMicros,
    required int priceUnits,
    this.rowid = const Value.absent(),
  }) : coinId = Value(coinId),
       range = Value(range),
       atMicros = Value(atMicros),
       priceUnits = Value(priceUnits);
  static Insertable<ChartPointRow> custom({
    Expression<String>? coinId,
    Expression<String>? range,
    Expression<int>? atMicros,
    Expression<int>? priceUnits,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (coinId != null) 'coin_id': coinId,
      if (range != null) 'range': range,
      if (atMicros != null) 'at_micros': atMicros,
      if (priceUnits != null) 'price_units': priceUnits,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChartPointsCompanion copyWith({
    Value<String>? coinId,
    Value<String>? range,
    Value<int>? atMicros,
    Value<int>? priceUnits,
    Value<int>? rowid,
  }) {
    return ChartPointsCompanion(
      coinId: coinId ?? this.coinId,
      range: range ?? this.range,
      atMicros: atMicros ?? this.atMicros,
      priceUnits: priceUnits ?? this.priceUnits,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (coinId.present) {
      map['coin_id'] = Variable<String>(coinId.value);
    }
    if (range.present) {
      map['range'] = Variable<String>(range.value);
    }
    if (atMicros.present) {
      map['at_micros'] = Variable<int>(atMicros.value);
    }
    if (priceUnits.present) {
      map['price_units'] = Variable<int>(priceUnits.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChartPointsCompanion(')
          ..write('coinId: $coinId, ')
          ..write('range: $range, ')
          ..write('atMicros: $atMicros, ')
          ..write('priceUnits: $priceUnits, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChartStatesTable extends ChartStates
    with TableInfo<$ChartStatesTable, ChartStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChartStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _coinIdMeta = const VerificationMeta('coinId');
  @override
  late final GeneratedColumn<String> coinId = GeneratedColumn<String>(
    'coin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rangeMeta = const VerificationMeta('range');
  @override
  late final GeneratedColumn<String> range = GeneratedColumn<String>(
    'range',
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
  @override
  List<GeneratedColumn> get $columns => [coinId, range, syncedAtMicros];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chart_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChartStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('coin_id')) {
      context.handle(
        _coinIdMeta,
        coinId.isAcceptableOrUnknown(data['coin_id']!, _coinIdMeta),
      );
    } else if (isInserting) {
      context.missing(_coinIdMeta);
    }
    if (data.containsKey('range')) {
      context.handle(
        _rangeMeta,
        range.isAcceptableOrUnknown(data['range']!, _rangeMeta),
      );
    } else if (isInserting) {
      context.missing(_rangeMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {coinId, range};
  @override
  ChartStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChartStateRow(
      coinId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coin_id'],
      )!,
      range: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}range'],
      )!,
      syncedAtMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at_micros'],
      )!,
    );
  }

  @override
  $ChartStatesTable createAlias(String alias) {
    return $ChartStatesTable(attachedDatabase, alias);
  }
}

class ChartStateRow extends DataClass implements Insertable<ChartStateRow> {
  final String coinId;
  final String range;
  final int syncedAtMicros;
  const ChartStateRow({
    required this.coinId,
    required this.range,
    required this.syncedAtMicros,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['coin_id'] = Variable<String>(coinId);
    map['range'] = Variable<String>(range);
    map['synced_at_micros'] = Variable<int>(syncedAtMicros);
    return map;
  }

  ChartStatesCompanion toCompanion(bool nullToAbsent) {
    return ChartStatesCompanion(
      coinId: Value(coinId),
      range: Value(range),
      syncedAtMicros: Value(syncedAtMicros),
    );
  }

  factory ChartStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChartStateRow(
      coinId: serializer.fromJson<String>(json['coinId']),
      range: serializer.fromJson<String>(json['range']),
      syncedAtMicros: serializer.fromJson<int>(json['syncedAtMicros']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'coinId': serializer.toJson<String>(coinId),
      'range': serializer.toJson<String>(range),
      'syncedAtMicros': serializer.toJson<int>(syncedAtMicros),
    };
  }

  ChartStateRow copyWith({
    String? coinId,
    String? range,
    int? syncedAtMicros,
  }) => ChartStateRow(
    coinId: coinId ?? this.coinId,
    range: range ?? this.range,
    syncedAtMicros: syncedAtMicros ?? this.syncedAtMicros,
  );
  ChartStateRow copyWithCompanion(ChartStatesCompanion data) {
    return ChartStateRow(
      coinId: data.coinId.present ? data.coinId.value : this.coinId,
      range: data.range.present ? data.range.value : this.range,
      syncedAtMicros: data.syncedAtMicros.present
          ? data.syncedAtMicros.value
          : this.syncedAtMicros,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChartStateRow(')
          ..write('coinId: $coinId, ')
          ..write('range: $range, ')
          ..write('syncedAtMicros: $syncedAtMicros')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(coinId, range, syncedAtMicros);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChartStateRow &&
          other.coinId == this.coinId &&
          other.range == this.range &&
          other.syncedAtMicros == this.syncedAtMicros);
}

class ChartStatesCompanion extends UpdateCompanion<ChartStateRow> {
  final Value<String> coinId;
  final Value<String> range;
  final Value<int> syncedAtMicros;
  final Value<int> rowid;
  const ChartStatesCompanion({
    this.coinId = const Value.absent(),
    this.range = const Value.absent(),
    this.syncedAtMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChartStatesCompanion.insert({
    required String coinId,
    required String range,
    required int syncedAtMicros,
    this.rowid = const Value.absent(),
  }) : coinId = Value(coinId),
       range = Value(range),
       syncedAtMicros = Value(syncedAtMicros);
  static Insertable<ChartStateRow> custom({
    Expression<String>? coinId,
    Expression<String>? range,
    Expression<int>? syncedAtMicros,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (coinId != null) 'coin_id': coinId,
      if (range != null) 'range': range,
      if (syncedAtMicros != null) 'synced_at_micros': syncedAtMicros,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChartStatesCompanion copyWith({
    Value<String>? coinId,
    Value<String>? range,
    Value<int>? syncedAtMicros,
    Value<int>? rowid,
  }) {
    return ChartStatesCompanion(
      coinId: coinId ?? this.coinId,
      range: range ?? this.range,
      syncedAtMicros: syncedAtMicros ?? this.syncedAtMicros,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (coinId.present) {
      map['coin_id'] = Variable<String>(coinId.value);
    }
    if (range.present) {
      map['range'] = Variable<String>(range.value);
    }
    if (syncedAtMicros.present) {
      map['synced_at_micros'] = Variable<int>(syncedAtMicros.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChartStatesCompanion(')
          ..write('coinId: $coinId, ')
          ..write('range: $range, ')
          ..write('syncedAtMicros: $syncedAtMicros, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MarketDatabase extends GeneratedDatabase {
  _$MarketDatabase(QueryExecutor e) : super(e);
  $MarketDatabaseManager get managers => $MarketDatabaseManager(this);
  late final $CoinsTable coins = $CoinsTable(this);
  late final $ListEntriesTable listEntries = $ListEntriesTable(this);
  late final $ListPagesTable listPages = $ListPagesTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $ChartPointsTable chartPoints = $ChartPointsTable(this);
  late final $ChartStatesTable chartStates = $ChartStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    coins,
    listEntries,
    listPages,
    favorites,
    chartPoints,
    chartStates,
  ];
}

typedef $$CoinsTableCreateCompanionBuilder = CoinsCompanion Function({
  required String id,
  required String symbol,
  required String name,
  Value<String?> imageUrl,
  Value<int?> marketCapRank,
  required int priceUnits,
  Value<int?> change24hHundredths,
  Value<int?> priceChange24hUnits,
  Value<int?> high24hUnits,
  Value<int?> low24hUnits,
  Value<int?> marketCapCents,
  Value<int?> totalVolumeCents,
  Value<int?> updatedAtMicros,
  required int savedAtMicros,
  required String searchText,
  Value<int> rowid,
});
typedef $$CoinsTableUpdateCompanionBuilder = CoinsCompanion Function({
  Value<String> id,
  Value<String> symbol,
  Value<String> name,
  Value<String?> imageUrl,
  Value<int?> marketCapRank,
  Value<int> priceUnits,
  Value<int?> change24hHundredths,
  Value<int?> priceChange24hUnits,
  Value<int?> high24hUnits,
  Value<int?> low24hUnits,
  Value<int?> marketCapCents,
  Value<int?> totalVolumeCents,
  Value<int?> updatedAtMicros,
  Value<int> savedAtMicros,
  Value<String> searchText,
  Value<int> rowid,
});

class $$CoinsTableFilterComposer
    extends Composer<_$MarketDatabase, $CoinsTable> {
  $$CoinsTableFilterComposer({
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

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get marketCapRank => $composableBuilder(
    column: $table.marketCapRank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceUnits => $composableBuilder(
    column: $table.priceUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get change24hHundredths => $composableBuilder(
    column: $table.change24hHundredths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceChange24hUnits => $composableBuilder(
    column: $table.priceChange24hUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get high24hUnits => $composableBuilder(
    column: $table.high24hUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get low24hUnits => $composableBuilder(
    column: $table.low24hUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get marketCapCents => $composableBuilder(
    column: $table.marketCapCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalVolumeCents => $composableBuilder(
    column: $table.totalVolumeCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMicros => $composableBuilder(
    column: $table.updatedAtMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedAtMicros => $composableBuilder(
    column: $table.savedAtMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CoinsTableOrderingComposer
    extends Composer<_$MarketDatabase, $CoinsTable> {
  $$CoinsTableOrderingComposer({
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

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get marketCapRank => $composableBuilder(
    column: $table.marketCapRank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceUnits => $composableBuilder(
    column: $table.priceUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get change24hHundredths => $composableBuilder(
    column: $table.change24hHundredths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceChange24hUnits => $composableBuilder(
    column: $table.priceChange24hUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get high24hUnits => $composableBuilder(
    column: $table.high24hUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get low24hUnits => $composableBuilder(
    column: $table.low24hUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get marketCapCents => $composableBuilder(
    column: $table.marketCapCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalVolumeCents => $composableBuilder(
    column: $table.totalVolumeCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMicros => $composableBuilder(
    column: $table.updatedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedAtMicros => $composableBuilder(
    column: $table.savedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoinsTableAnnotationComposer
    extends Composer<_$MarketDatabase, $CoinsTable> {
  $$CoinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get marketCapRank => $composableBuilder(
    column: $table.marketCapRank,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priceUnits => $composableBuilder(
    column: $table.priceUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get change24hHundredths => $composableBuilder(
    column: $table.change24hHundredths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priceChange24hUnits => $composableBuilder(
    column: $table.priceChange24hUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get high24hUnits => $composableBuilder(
    column: $table.high24hUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get low24hUnits => $composableBuilder(
    column: $table.low24hUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get marketCapCents => $composableBuilder(
    column: $table.marketCapCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalVolumeCents => $composableBuilder(
    column: $table.totalVolumeCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMicros => $composableBuilder(
    column: $table.updatedAtMicros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get savedAtMicros => $composableBuilder(
    column: $table.savedAtMicros,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );
}

class $$CoinsTableTableManager
    extends
        RootTableManager<
          _$MarketDatabase,
          $CoinsTable,
          CoinRow,
          $$CoinsTableFilterComposer,
          $$CoinsTableOrderingComposer,
          $$CoinsTableAnnotationComposer,
          $$CoinsTableCreateCompanionBuilder,
          $$CoinsTableUpdateCompanionBuilder,
          (CoinRow, BaseReferences<_$MarketDatabase, $CoinsTable, CoinRow>),
          CoinRow,
          PrefetchHooks Function()
        > {
  $$CoinsTableTableManager(_$MarketDatabase db, $CoinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int?> marketCapRank = const Value.absent(),
                Value<int> priceUnits = const Value.absent(),
                Value<int?> change24hHundredths = const Value.absent(),
                Value<int?> priceChange24hUnits = const Value.absent(),
                Value<int?> high24hUnits = const Value.absent(),
                Value<int?> low24hUnits = const Value.absent(),
                Value<int?> marketCapCents = const Value.absent(),
                Value<int?> totalVolumeCents = const Value.absent(),
                Value<int?> updatedAtMicros = const Value.absent(),
                Value<int> savedAtMicros = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoinsCompanion(
                id: id,
                symbol: symbol,
                name: name,
                imageUrl: imageUrl,
                marketCapRank: marketCapRank,
                priceUnits: priceUnits,
                change24hHundredths: change24hHundredths,
                priceChange24hUnits: priceChange24hUnits,
                high24hUnits: high24hUnits,
                low24hUnits: low24hUnits,
                marketCapCents: marketCapCents,
                totalVolumeCents: totalVolumeCents,
                updatedAtMicros: updatedAtMicros,
                savedAtMicros: savedAtMicros,
                searchText: searchText,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String symbol,
                required String name,
                Value<String?> imageUrl = const Value.absent(),
                Value<int?> marketCapRank = const Value.absent(),
                required int priceUnits,
                Value<int?> change24hHundredths = const Value.absent(),
                Value<int?> priceChange24hUnits = const Value.absent(),
                Value<int?> high24hUnits = const Value.absent(),
                Value<int?> low24hUnits = const Value.absent(),
                Value<int?> marketCapCents = const Value.absent(),
                Value<int?> totalVolumeCents = const Value.absent(),
                Value<int?> updatedAtMicros = const Value.absent(),
                required int savedAtMicros,
                required String searchText,
                Value<int> rowid = const Value.absent(),
              }) => CoinsCompanion.insert(
                id: id,
                symbol: symbol,
                name: name,
                imageUrl: imageUrl,
                marketCapRank: marketCapRank,
                priceUnits: priceUnits,
                change24hHundredths: change24hHundredths,
                priceChange24hUnits: priceChange24hUnits,
                high24hUnits: high24hUnits,
                low24hUnits: low24hUnits,
                marketCapCents: marketCapCents,
                totalVolumeCents: totalVolumeCents,
                updatedAtMicros: updatedAtMicros,
                savedAtMicros: savedAtMicros,
                searchText: searchText,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CoinsTable, CoinRow>(table),
                  BaseReferences<_$MarketDatabase, $CoinsTable, CoinRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoinsTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDatabase,
      $CoinsTable,
      CoinRow,
      $$CoinsTableFilterComposer,
      $$CoinsTableOrderingComposer,
      $$CoinsTableAnnotationComposer,
      $$CoinsTableCreateCompanionBuilder,
      $$CoinsTableUpdateCompanionBuilder,
      (CoinRow, BaseReferences<_$MarketDatabase, $CoinsTable, CoinRow>),
      CoinRow,
      PrefetchHooks Function()
    >;
typedef $$ListEntriesTableCreateCompanionBuilder =
    ListEntriesCompanion Function({
      required String listName,
      required int page,
      required int position,
      required String coinId,
      Value<int> rowid,
    });
typedef $$ListEntriesTableUpdateCompanionBuilder =
    ListEntriesCompanion Function({
      Value<String> listName,
      Value<int> page,
      Value<int> position,
      Value<String> coinId,
      Value<int> rowid,
    });

class $$ListEntriesTableFilterComposer
    extends Composer<_$MarketDatabase, $ListEntriesTable> {
  $$ListEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get listName => $composableBuilder(
    column: $table.listName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coinId => $composableBuilder(
    column: $table.coinId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ListEntriesTableOrderingComposer
    extends Composer<_$MarketDatabase, $ListEntriesTable> {
  $$ListEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get listName => $composableBuilder(
    column: $table.listName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coinId => $composableBuilder(
    column: $table.coinId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListEntriesTableAnnotationComposer
    extends Composer<_$MarketDatabase, $ListEntriesTable> {
  $$ListEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get listName =>
      $composableBuilder(column: $table.listName, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get coinId =>
      $composableBuilder(column: $table.coinId, builder: (column) => column);
}

class $$ListEntriesTableTableManager
    extends
        RootTableManager<
          _$MarketDatabase,
          $ListEntriesTable,
          ListEntryRow,
          $$ListEntriesTableFilterComposer,
          $$ListEntriesTableOrderingComposer,
          $$ListEntriesTableAnnotationComposer,
          $$ListEntriesTableCreateCompanionBuilder,
          $$ListEntriesTableUpdateCompanionBuilder,
          (
            ListEntryRow,
            BaseReferences<_$MarketDatabase, $ListEntriesTable, ListEntryRow>,
          ),
          ListEntryRow,
          PrefetchHooks Function()
        > {
  $$ListEntriesTableTableManager(_$MarketDatabase db, $ListEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> listName = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> coinId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListEntriesCompanion(
                listName: listName,
                page: page,
                position: position,
                coinId: coinId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String listName,
                required int page,
                required int position,
                required String coinId,
                Value<int> rowid = const Value.absent(),
              }) => ListEntriesCompanion.insert(
                listName: listName,
                page: page,
                position: position,
                coinId: coinId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListEntriesTable, ListEntryRow>(table),
                  BaseReferences<
                    _$MarketDatabase,
                    $ListEntriesTable,
                    ListEntryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDatabase,
      $ListEntriesTable,
      ListEntryRow,
      $$ListEntriesTableFilterComposer,
      $$ListEntriesTableOrderingComposer,
      $$ListEntriesTableAnnotationComposer,
      $$ListEntriesTableCreateCompanionBuilder,
      $$ListEntriesTableUpdateCompanionBuilder,
      (
        ListEntryRow,
        BaseReferences<_$MarketDatabase, $ListEntriesTable, ListEntryRow>,
      ),
      ListEntryRow,
      PrefetchHooks Function()
    >;
typedef $$ListPagesTableCreateCompanionBuilder = ListPagesCompanion Function({
  required String listName,
  required int page,
  required int syncedAtMicros,
  required bool hasMore,
  Value<int> skippedRecords,
  Value<int> rowid,
});
typedef $$ListPagesTableUpdateCompanionBuilder = ListPagesCompanion Function({
  Value<String> listName,
  Value<int> page,
  Value<int> syncedAtMicros,
  Value<bool> hasMore,
  Value<int> skippedRecords,
  Value<int> rowid,
});

class $$ListPagesTableFilterComposer
    extends Composer<_$MarketDatabase, $ListPagesTable> {
  $$ListPagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get listName => $composableBuilder(
    column: $table.listName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAtMicros => $composableBuilder(
    column: $table.syncedAtMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasMore => $composableBuilder(
    column: $table.hasMore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skippedRecords => $composableBuilder(
    column: $table.skippedRecords,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ListPagesTableOrderingComposer
    extends Composer<_$MarketDatabase, $ListPagesTable> {
  $$ListPagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get listName => $composableBuilder(
    column: $table.listName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAtMicros => $composableBuilder(
    column: $table.syncedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasMore => $composableBuilder(
    column: $table.hasMore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skippedRecords => $composableBuilder(
    column: $table.skippedRecords,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListPagesTableAnnotationComposer
    extends Composer<_$MarketDatabase, $ListPagesTable> {
  $$ListPagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get listName =>
      $composableBuilder(column: $table.listName, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get syncedAtMicros => $composableBuilder(
    column: $table.syncedAtMicros,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasMore =>
      $composableBuilder(column: $table.hasMore, builder: (column) => column);

  GeneratedColumn<int> get skippedRecords => $composableBuilder(
    column: $table.skippedRecords,
    builder: (column) => column,
  );
}

class $$ListPagesTableTableManager
    extends
        RootTableManager<
          _$MarketDatabase,
          $ListPagesTable,
          ListPageRow,
          $$ListPagesTableFilterComposer,
          $$ListPagesTableOrderingComposer,
          $$ListPagesTableAnnotationComposer,
          $$ListPagesTableCreateCompanionBuilder,
          $$ListPagesTableUpdateCompanionBuilder,
          (
            ListPageRow,
            BaseReferences<_$MarketDatabase, $ListPagesTable, ListPageRow>,
          ),
          ListPageRow,
          PrefetchHooks Function()
        > {
  $$ListPagesTableTableManager(_$MarketDatabase db, $ListPagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListPagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListPagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListPagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> listName = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> syncedAtMicros = const Value.absent(),
                Value<bool> hasMore = const Value.absent(),
                Value<int> skippedRecords = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListPagesCompanion(
                listName: listName,
                page: page,
                syncedAtMicros: syncedAtMicros,
                hasMore: hasMore,
                skippedRecords: skippedRecords,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String listName,
                required int page,
                required int syncedAtMicros,
                required bool hasMore,
                Value<int> skippedRecords = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListPagesCompanion.insert(
                listName: listName,
                page: page,
                syncedAtMicros: syncedAtMicros,
                hasMore: hasMore,
                skippedRecords: skippedRecords,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListPagesTable, ListPageRow>(table),
                  BaseReferences<
                    _$MarketDatabase,
                    $ListPagesTable,
                    ListPageRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListPagesTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDatabase,
      $ListPagesTable,
      ListPageRow,
      $$ListPagesTableFilterComposer,
      $$ListPagesTableOrderingComposer,
      $$ListPagesTableAnnotationComposer,
      $$ListPagesTableCreateCompanionBuilder,
      $$ListPagesTableUpdateCompanionBuilder,
      (
        ListPageRow,
        BaseReferences<_$MarketDatabase, $ListPagesTable, ListPageRow>,
      ),
      ListPageRow,
      PrefetchHooks Function()
    >;
typedef $$FavoritesTableCreateCompanionBuilder = FavoritesCompanion Function({
  required String coinId,
  required int addedAtMicros,
  Value<int> rowid,
});
typedef $$FavoritesTableUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<String> coinId,
  Value<int> addedAtMicros,
  Value<int> rowid,
});

class $$FavoritesTableFilterComposer
    extends Composer<_$MarketDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get coinId => $composableBuilder(
    column: $table.coinId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAtMicros => $composableBuilder(
    column: $table.addedAtMicros,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$MarketDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get coinId => $composableBuilder(
    column: $table.coinId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAtMicros => $composableBuilder(
    column: $table.addedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$MarketDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get coinId =>
      $composableBuilder(column: $table.coinId, builder: (column) => column);

  GeneratedColumn<int> get addedAtMicros => $composableBuilder(
    column: $table.addedAtMicros,
    builder: (column) => column,
  );
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$MarketDatabase,
          $FavoritesTable,
          FavoriteRow,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (
            FavoriteRow,
            BaseReferences<_$MarketDatabase, $FavoritesTable, FavoriteRow>,
          ),
          FavoriteRow,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$MarketDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> coinId = const Value.absent(),
                Value<int> addedAtMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion(
                coinId: coinId,
                addedAtMicros: addedAtMicros,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String coinId,
                required int addedAtMicros,
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion.insert(
                coinId: coinId,
                addedAtMicros: addedAtMicros,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavoritesTable, FavoriteRow>(table),
                  BaseReferences<
                    _$MarketDatabase,
                    $FavoritesTable,
                    FavoriteRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDatabase,
      $FavoritesTable,
      FavoriteRow,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (
        FavoriteRow,
        BaseReferences<_$MarketDatabase, $FavoritesTable, FavoriteRow>,
      ),
      FavoriteRow,
      PrefetchHooks Function()
    >;
typedef $$ChartPointsTableCreateCompanionBuilder =
    ChartPointsCompanion Function({
      required String coinId,
      required String range,
      required int atMicros,
      required int priceUnits,
      Value<int> rowid,
    });
typedef $$ChartPointsTableUpdateCompanionBuilder =
    ChartPointsCompanion Function({
      Value<String> coinId,
      Value<String> range,
      Value<int> atMicros,
      Value<int> priceUnits,
      Value<int> rowid,
    });

class $$ChartPointsTableFilterComposer
    extends Composer<_$MarketDatabase, $ChartPointsTable> {
  $$ChartPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get coinId => $composableBuilder(
    column: $table.coinId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get range => $composableBuilder(
    column: $table.range,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atMicros => $composableBuilder(
    column: $table.atMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceUnits => $composableBuilder(
    column: $table.priceUnits,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChartPointsTableOrderingComposer
    extends Composer<_$MarketDatabase, $ChartPointsTable> {
  $$ChartPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get coinId => $composableBuilder(
    column: $table.coinId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get range => $composableBuilder(
    column: $table.range,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atMicros => $composableBuilder(
    column: $table.atMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceUnits => $composableBuilder(
    column: $table.priceUnits,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChartPointsTableAnnotationComposer
    extends Composer<_$MarketDatabase, $ChartPointsTable> {
  $$ChartPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get coinId =>
      $composableBuilder(column: $table.coinId, builder: (column) => column);

  GeneratedColumn<String> get range =>
      $composableBuilder(column: $table.range, builder: (column) => column);

  GeneratedColumn<int> get atMicros =>
      $composableBuilder(column: $table.atMicros, builder: (column) => column);

  GeneratedColumn<int> get priceUnits => $composableBuilder(
    column: $table.priceUnits,
    builder: (column) => column,
  );
}

class $$ChartPointsTableTableManager
    extends
        RootTableManager<
          _$MarketDatabase,
          $ChartPointsTable,
          ChartPointRow,
          $$ChartPointsTableFilterComposer,
          $$ChartPointsTableOrderingComposer,
          $$ChartPointsTableAnnotationComposer,
          $$ChartPointsTableCreateCompanionBuilder,
          $$ChartPointsTableUpdateCompanionBuilder,
          (
            ChartPointRow,
            BaseReferences<_$MarketDatabase, $ChartPointsTable, ChartPointRow>,
          ),
          ChartPointRow,
          PrefetchHooks Function()
        > {
  $$ChartPointsTableTableManager(_$MarketDatabase db, $ChartPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChartPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChartPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChartPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> coinId = const Value.absent(),
                Value<String> range = const Value.absent(),
                Value<int> atMicros = const Value.absent(),
                Value<int> priceUnits = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChartPointsCompanion(
                coinId: coinId,
                range: range,
                atMicros: atMicros,
                priceUnits: priceUnits,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String coinId,
                required String range,
                required int atMicros,
                required int priceUnits,
                Value<int> rowid = const Value.absent(),
              }) => ChartPointsCompanion.insert(
                coinId: coinId,
                range: range,
                atMicros: atMicros,
                priceUnits: priceUnits,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChartPointsTable, ChartPointRow>(table),
                  BaseReferences<
                    _$MarketDatabase,
                    $ChartPointsTable,
                    ChartPointRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChartPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDatabase,
      $ChartPointsTable,
      ChartPointRow,
      $$ChartPointsTableFilterComposer,
      $$ChartPointsTableOrderingComposer,
      $$ChartPointsTableAnnotationComposer,
      $$ChartPointsTableCreateCompanionBuilder,
      $$ChartPointsTableUpdateCompanionBuilder,
      (
        ChartPointRow,
        BaseReferences<_$MarketDatabase, $ChartPointsTable, ChartPointRow>,
      ),
      ChartPointRow,
      PrefetchHooks Function()
    >;
typedef $$ChartStatesTableCreateCompanionBuilder =
    ChartStatesCompanion Function({
      required String coinId,
      required String range,
      required int syncedAtMicros,
      Value<int> rowid,
    });
typedef $$ChartStatesTableUpdateCompanionBuilder =
    ChartStatesCompanion Function({
      Value<String> coinId,
      Value<String> range,
      Value<int> syncedAtMicros,
      Value<int> rowid,
    });

class $$ChartStatesTableFilterComposer
    extends Composer<_$MarketDatabase, $ChartStatesTable> {
  $$ChartStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get coinId => $composableBuilder(
    column: $table.coinId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get range => $composableBuilder(
    column: $table.range,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAtMicros => $composableBuilder(
    column: $table.syncedAtMicros,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChartStatesTableOrderingComposer
    extends Composer<_$MarketDatabase, $ChartStatesTable> {
  $$ChartStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get coinId => $composableBuilder(
    column: $table.coinId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get range => $composableBuilder(
    column: $table.range,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAtMicros => $composableBuilder(
    column: $table.syncedAtMicros,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChartStatesTableAnnotationComposer
    extends Composer<_$MarketDatabase, $ChartStatesTable> {
  $$ChartStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get coinId =>
      $composableBuilder(column: $table.coinId, builder: (column) => column);

  GeneratedColumn<String> get range =>
      $composableBuilder(column: $table.range, builder: (column) => column);

  GeneratedColumn<int> get syncedAtMicros => $composableBuilder(
    column: $table.syncedAtMicros,
    builder: (column) => column,
  );
}

class $$ChartStatesTableTableManager
    extends
        RootTableManager<
          _$MarketDatabase,
          $ChartStatesTable,
          ChartStateRow,
          $$ChartStatesTableFilterComposer,
          $$ChartStatesTableOrderingComposer,
          $$ChartStatesTableAnnotationComposer,
          $$ChartStatesTableCreateCompanionBuilder,
          $$ChartStatesTableUpdateCompanionBuilder,
          (
            ChartStateRow,
            BaseReferences<_$MarketDatabase, $ChartStatesTable, ChartStateRow>,
          ),
          ChartStateRow,
          PrefetchHooks Function()
        > {
  $$ChartStatesTableTableManager(_$MarketDatabase db, $ChartStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChartStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChartStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChartStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> coinId = const Value.absent(),
                Value<String> range = const Value.absent(),
                Value<int> syncedAtMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChartStatesCompanion(
                coinId: coinId,
                range: range,
                syncedAtMicros: syncedAtMicros,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String coinId,
                required String range,
                required int syncedAtMicros,
                Value<int> rowid = const Value.absent(),
              }) => ChartStatesCompanion.insert(
                coinId: coinId,
                range: range,
                syncedAtMicros: syncedAtMicros,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChartStatesTable, ChartStateRow>(table),
                  BaseReferences<
                    _$MarketDatabase,
                    $ChartStatesTable,
                    ChartStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChartStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDatabase,
      $ChartStatesTable,
      ChartStateRow,
      $$ChartStatesTableFilterComposer,
      $$ChartStatesTableOrderingComposer,
      $$ChartStatesTableAnnotationComposer,
      $$ChartStatesTableCreateCompanionBuilder,
      $$ChartStatesTableUpdateCompanionBuilder,
      (
        ChartStateRow,
        BaseReferences<_$MarketDatabase, $ChartStatesTable, ChartStateRow>,
      ),
      ChartStateRow,
      PrefetchHooks Function()
    >;

class $MarketDatabaseManager {
  final _$MarketDatabase _db;
  $MarketDatabaseManager(this._db);
  $$CoinsTableTableManager get coins =>
      $$CoinsTableTableManager(_db, _db.coins);
  $$ListEntriesTableTableManager get listEntries =>
      $$ListEntriesTableTableManager(_db, _db.listEntries);
  $$ListPagesTableTableManager get listPages =>
      $$ListPagesTableTableManager(_db, _db.listPages);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$ChartPointsTableTableManager get chartPoints =>
      $$ChartPointsTableTableManager(_db, _db.chartPoints);
  $$ChartStatesTableTableManager get chartStates =>
      $$ChartStatesTableTableManager(_db, _db.chartStates);
}
