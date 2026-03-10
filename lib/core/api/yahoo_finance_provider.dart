import '../../models/candle_data.dart';
import '../../models/market_data.dart';
import '../../models/ticker.dart';
import 'market_data_provider.dart';

class YahooFinanceProvider implements MarketDataProvider {
  @override
  Future<List<MarketData>> fetchQuotes(List<Ticker> tickers) {
    throw UnsupportedError('YahooFinanceProvider: not implemented.');
  }

  @override
  Future<MarketData> fetchQuote(String symbol) {
    throw UnsupportedError('YahooFinanceProvider: not implemented.');
  }

  @override
  Future<CandleData> fetchDailyCandles(String symbol, {int days = 260}) {
    throw UnsupportedError('YahooFinanceProvider: not implemented.');
  }

  @override
  Future<String?> fetchCompanyName(String symbol) {
    throw UnsupportedError('YahooFinanceProvider: not implemented.');
  }

  @override
  Future<bool> isValidSymbol(String symbol) {
    throw UnsupportedError('YahooFinanceProvider: not implemented.');
  }

  @override
  String? lastCandleErrorFor(String symbol) {
    return null;
  }
}
