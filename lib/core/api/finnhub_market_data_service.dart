import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/candle_data.dart';
import '../../models/market_data.dart';
import '../../models/ticker.dart';
import 'market_data_provider.dart';

class FinnhubProvider implements MarketDataProvider {
  FinnhubProvider({
    required this.apiKey,
    http.Client? client,
  })
      : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;
  static const _quoteTtl = Duration(minutes: 5);
  static const _candlesTtl = Duration(hours: 6);
  static const _candleFailureTtl = Duration(minutes: 5);
  static const _profileTtl = Duration(hours: 24);

  static final Map<String, _CacheEntry<MarketData>> _quoteCache = {};
  static final Map<String, _CacheEntry<CandleData>> _candlesCache = {};
  static final Map<String, _CacheEntry<String>> _profileCache = {};
  static final Map<String, Future<CandleData>> _candlesInFlight = {};
  static final Map<String, _CacheEntry<String>> _candleFailureCache = {};
  static final Map<String, String> _lastCandleErrors = {};

  Future<List<MarketData>> fetchQuotes(List<Ticker> tickers) async {
    _ensureApiKey();
    final futures = tickers.map((ticker) => fetchQuote(ticker.symbol)).toList();
    return Future.wait(futures);
  }

  Future<MarketData> fetchQuote(String symbol) async {
    _ensureApiKey();
    final cachedQuote = _readCache(_quoteCache, symbol, _quoteTtl);
    if (cachedQuote != null) {
      return cachedQuote;
    }
    final uri = Uri.https(
      'finnhub.io',
      '/api/v1/quote',
      {'symbol': symbol, 'token': apiKey},
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Finnhub error ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final current = (data['c'] as num?)?.toDouble() ?? 0.0;
    final prevClose = (data['pc'] as num?)?.toDouble() ?? 0.0;
    final quoteVolume = (data['v'] as num?)?.toInt() ?? 0;

    final changePercent = prevClose == 0 ? 0.0 : ((current - prevClose) / prevClose) * 100;
    final volume = quoteVolume > 0 ? quoteVolume : await _fetchVolumeFromCandles(symbol);

    final quote = MarketData(
      symbol: symbol,
      price: current,
      changePercent: changePercent,
      volume: volume,
    );
    _writeCache(_quoteCache, symbol, quote);
    return quote;
  }

  Future<CandleData> fetchDailyCandles(String symbol, {int days = 260}) async {
    final cachedCandles = _readCache(_candlesCache, symbol, _candlesTtl);
    if (cachedCandles != null) {
      return cachedCandles;
    }
    final cachedFailure = _readCache(_candleFailureCache, symbol, _candleFailureTtl);
    if (cachedFailure != null) {
      _lastCandleErrors[symbol] = cachedFailure;
      return const CandleData();
    }
    final existing = _candlesInFlight[symbol];
    if (existing != null) {
      return existing;
    }
    final future = () async {
      _ensureApiKey();
      return _fetchDailyCandlesInternal(symbol, days: days);
    }();
    _candlesInFlight[symbol] = future;
    try {
      return await future;
    } finally {
      _candlesInFlight.remove(symbol);
    }
  }

  Future<bool> isValidSymbol(String symbol) async {
    _ensureApiKey();
    final uri = Uri.https(
      'finnhub.io',
      '/api/v1/quote',
      {'symbol': symbol, 'token': apiKey},
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return false;
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    final current = (data['c'] as num?)?.toDouble() ?? 0.0;
    final open = (data['o'] as num?)?.toDouble() ?? 0.0;
    final high = (data['h'] as num?)?.toDouble() ?? 0.0;
    final low = (data['l'] as num?)?.toDouble() ?? 0.0;
    final prevClose = (data['pc'] as num?)?.toDouble() ?? 0.0;

    return current > 0 || open > 0 || high > 0 || low > 0 || prevClose > 0;
  }

  Future<String?> fetchCompanyName(String symbol) async {
    _ensureApiKey();
    final cachedName = _readCache(_profileCache, symbol, _profileTtl);
    if (cachedName != null && cachedName.isNotEmpty) {
      return cachedName;
    }
    final uri = Uri.https(
      'finnhub.io',
      '/api/v1/stock/profile2',
      {'symbol': symbol, 'token': apiKey},
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return null;
    }
    final data = json.decode(response.body) as Map<String, dynamic>;
    final name = (data['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      return null;
    }
    _writeCache(_profileCache, symbol, name);
    return name;
  }

  String? lastCandleErrorFor(String symbol) => _lastCandleErrors[symbol];

  void _ensureApiKey() {
    if (apiKey.isEmpty) {
      throw Exception('Missing FINNHUB_API_KEY (use --dart-define=FINNHUB_API_KEY=YOUR_KEY).');
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

  Future<int> _fetchVolumeFromCandles(String symbol) async {
    final candles = await fetchDailyCandles(symbol);
    if (candles.volumes.isEmpty) {
      return 0;
    }
    return candles.volumes.last;
  }

  Future<CandleData> _fetchDailyCandlesInternal(String symbol, {required int days}) async {
    final attempts = <int>{days, 120, 60, 30, 7};
    for (final attempt in attempts) {
      final candles = await _requestCandles(symbol, attempt, resolution: 'D');
      if (candles.closes.isNotEmpty) {
        _writeCache(_candlesCache, symbol, candles);
        return candles;
      }
    }
    final intradayAttempts = <int>{30, 14, 7, 3};
    for (final attempt in intradayAttempts) {
      final candles = await _requestCandles(symbol, attempt, resolution: '60');
      if (candles.closes.isNotEmpty) {
        _writeCache(_candlesCache, symbol, candles);
        return candles;
      }
    }
    return const CandleData();
  }

  List<double> _toDoubleList(List<dynamic> values) {
    final result = <double>[];
    for (final value in values) {
      if (value is num) {
        result.add(value.toDouble());
      } else if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          result.add(parsed);
        }
      }
    }
    return result;
  }

  List<int> _toIntList(List<dynamic> values) {
    final result = <int>[];
    for (final value in values) {
      if (value is int) {
        result.add(value);
      } else if (value is num) {
        result.add(value.toInt());
      } else if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          result.add(parsed);
        }
      }
    }
    return result;
  }

  Future<CandleData> _requestCandles(
    String symbol,
    int days, {
    required String resolution,
  }) async {
    final now = DateTime.now().toUtc();
    final from = now.subtract(Duration(days: days));
    final uri = Uri.https(
      'finnhub.io',
      '/api/v1/stock/candle',
      {
        'symbol': symbol,
        'resolution': resolution,
        'from': (from.millisecondsSinceEpoch ~/ 1000).toString(),
        'to': (now.millisecondsSinceEpoch ~/ 1000).toString(),
        'token': apiKey,
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
    if (data['s'] != null && data['s'] != 'ok') {
      _lastCandleErrors[symbol] = 'Candle status ${data['s']}';
    }
    final closes = data['c'] ?? data['close'];
    if (closes is! List) {
      _lastCandleErrors[symbol] = 'Candle data sin cierres.';
      return const CandleData();
    }

    final closeValues = _toDoubleList(closes);
    if (closeValues.isEmpty) {
      _lastCandleErrors[symbol] = 'Candle cierres vacios.';
      return const CandleData();
    }

    final volumes = data['v'] ?? data['volume'] ?? data['volumes'];
    final volumeValues = volumes is List ? _toIntList(volumes) : const <int>[];
    _lastCandleErrors.remove(symbol);
    return CandleData(closes: closeValues, volumes: volumeValues);
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
