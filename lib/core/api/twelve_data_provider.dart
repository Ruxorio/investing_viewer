import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/candle_data.dart';
import '../../models/market_data.dart';
import '../../models/ticker.dart';
import 'market_data_provider.dart';

class TwelveDataProvider implements MarketDataProvider {
  TwelveDataProvider({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;
  static const _candlesTtl = Duration(hours: 6);
  static const _candleFailureTtl = Duration(minutes: 5);

  static final Map<String, _CacheEntry<CandleData>> _candlesCache = {};
  static final Map<String, _CacheEntry<String>> _candleFailureCache = {};
  static final Map<String, String> _lastCandleErrors = {};

  @override
  Future<List<MarketData>> fetchQuotes(List<Ticker> tickers) {
    throw UnsupportedError('TwelveDataProvider: quotes not configured.');
  }

  @override
  Future<MarketData> fetchQuote(String symbol) {
    throw UnsupportedError('TwelveDataProvider: quotes not configured.');
  }

  @override
  Future<CandleData> fetchDailyCandles(String symbol, {int days = 260}) async {
    _ensureApiKey();
    final cachedCandles = _readCache(_candlesCache, symbol, _candlesTtl);
    if (cachedCandles != null) {
      return cachedCandles;
    }
    final cachedFailure = _readCache(_candleFailureCache, symbol, _candleFailureTtl);
    if (cachedFailure != null) {
      _lastCandleErrors[symbol] = cachedFailure;
      return const CandleData();
    }

    final uri = Uri.https(
      'api.twelvedata.com',
      '/time_series',
      {
        'symbol': symbol,
        'interval': '1day',
        'outputsize': days.toString(),
        'apikey': apiKey,
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      _lastCandleErrors[symbol] =
          'Candle error ${response.statusCode}: ${_trimBody(response.body)}';
      _writeCache(_candleFailureCache, symbol, _lastCandleErrors[symbol]!);
      return const CandleData();
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['status'] == 'error') {
      _lastCandleErrors[symbol] = 'Candle error: ${data['message'] ?? 'unknown'}';
      _writeCache(_candleFailureCache, symbol, _lastCandleErrors[symbol]!);
      return const CandleData();
    }
    final values = data['values'];
    if (values is! List) {
      _lastCandleErrors[symbol] = 'Candle sin valores.';
      _writeCache(_candleFailureCache, symbol, _lastCandleErrors[symbol]!);
      return const CandleData();
    }

    final closes = <double>[];
    final volumes = <int>[];
    for (final entry in values) {
      if (entry is! Map) {
        continue;
      }
      final close = _parseDouble(entry['close']);
      if (close == null) {
        continue;
      }
      closes.add(close);
      volumes.add(_parseInt(entry['volume']) ?? 0);
    }

    if (closes.isEmpty) {
      _lastCandleErrors[symbol] = 'Candle cierres vacios.';
      _writeCache(_candleFailureCache, symbol, _lastCandleErrors[symbol]!);
      return const CandleData();
    }

    _lastCandleErrors.remove(symbol);
    _candleFailureCache.remove(symbol);
    final orderedCloses = closes.reversed.toList();
    final orderedVolumes = volumes.reversed.toList();
    final candles = CandleData(closes: orderedCloses, volumes: orderedVolumes);
    _writeCache(_candlesCache, symbol, candles);
    return candles;
  }

  @override
  Future<String?> fetchCompanyName(String symbol) {
    throw UnsupportedError('TwelveDataProvider: company name not configured.');
  }

  @override
  Future<bool> isValidSymbol(String symbol) {
    throw UnsupportedError('TwelveDataProvider: validation not configured.');
  }

  @override
  String? lastCandleErrorFor(String symbol) => _lastCandleErrors[symbol];

  void _ensureApiKey() {
    if (apiKey.isEmpty) {
      throw Exception('Missing TWELVE_DATA_API_KEY (use --dart-define=TWELVE_DATA_API_KEY=YOUR_KEY).');
    }
  }

  T? _readCache<T>(Map<String, _CacheEntry<T>> cache, String key, Duration ttl) {
    final entry = cache[key];
    if (entry == null) {
      return null;
    }
    if (DateTime.now().difference(entry.timestamp) > ttl) {
      cache.remove(key);
      return null;
    }
    return entry.value;
  }

  void _writeCache<T>(Map<String, _CacheEntry<T>> cache, String key, T value) {
    cache[key] = _CacheEntry(value, DateTime.now());
  }

  double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String _trimBody(String body) {
    if (body.length <= 120) {
      return body;
    }
    return '${body.substring(0, 120)}...';
  }
}

class _CacheEntry<T> {
  const _CacheEntry(this.value, this.timestamp);

  final T value;
  final DateTime timestamp;
}
