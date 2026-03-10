import '../../core/indicators/indicator_calculator.dart';
import '../../models/candle_data.dart';
import '../../models/market_data.dart';
import '../../models/technical_indicators.dart';
import '../../models/ticker.dart';
import 'market_data_provider.dart';

class MarketDataRepository {
  MarketDataRepository({
    required this.quoteProvider,
    required this.candleProvider,
  });

  final MarketDataProvider quoteProvider;
  final MarketDataProvider candleProvider;
  static const _indicatorCalculator = IndicatorCalculator();
  static const _indicatorsTtl = Duration(hours: 6);

  static final Map<String, _CacheEntry<TechnicalIndicators?>> _indicatorsCache = {};
  static final Map<String, Future<TechnicalIndicators?>> _indicatorsInFlight = {};
  static final Map<String, String> _lastIndicatorErrors = {};

  Future<List<MarketData>> fetchQuotes(List<Ticker> tickers) {
    return quoteProvider.fetchQuotes(tickers);
  }

  Future<MarketData> fetchQuote(String symbol) {
    return quoteProvider.fetchQuote(symbol);
  }

  Future<CandleData> fetchDailyCandles(String symbol, {int days = 260}) {
    return candleProvider.fetchDailyCandles(symbol, days: days);
  }

  Future<TechnicalIndicators?> fetchIndicators(String symbol) async {
    final cachedIndicators = _readCache(_indicatorsCache, symbol, _indicatorsTtl);
    if (cachedIndicators != null) {
      return cachedIndicators;
    }
    final inFlight = _indicatorsInFlight[symbol];
    if (inFlight != null) {
      return inFlight;
    }
    final future = () async {
      final candles = await fetchDailyCandles(symbol);
      if (candles.closes.isEmpty) {
        _lastIndicatorErrors[symbol] =
            candleProvider.lastCandleErrorFor(symbol) ?? 'Sin velas para indicadores.';
        return null;
      }
      final indicators = _indicatorCalculator.calculate(candles.closes, volumes: candles.volumes);
      if (indicators == null) {
        _lastIndicatorErrors[symbol] = 'No hay suficientes datos para indicadores.';
        return null;
      }
      _lastIndicatorErrors.remove(symbol);
      _writeCache(_indicatorsCache, symbol, indicators);
      return indicators;
    }();
    _indicatorsInFlight[symbol] = future;
    try {
      return await future;
    } finally {
      _indicatorsInFlight.remove(symbol);
    }
  }

  Future<String?> fetchCompanyName(String symbol) {
    return quoteProvider.fetchCompanyName(symbol);
  }

  Future<bool> isValidSymbol(String symbol) {
    return quoteProvider.isValidSymbol(symbol);
  }

  String? lastCandleErrorFor(String symbol) {
    return candleProvider.lastCandleErrorFor(symbol);
  }

  String? lastIndicatorErrorFor(String symbol) => _lastIndicatorErrors[symbol];

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
}

class _CacheEntry<T> {
  const _CacheEntry(this.value, this.timestamp);

  final T value;
  final DateTime timestamp;
}
