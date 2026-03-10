import '../../models/candle_data.dart';
import '../../models/market_data.dart';
import '../../models/ticker.dart';

abstract class MarketDataProvider {
  Future<List<MarketData>> fetchQuotes(List<Ticker> tickers);
  Future<MarketData> fetchQuote(String symbol);
  Future<CandleData> fetchDailyCandles(String symbol, {int days = 260});
  Future<String?> fetchCompanyName(String symbol);
  Future<bool> isValidSymbol(String symbol);
  String? lastCandleErrorFor(String symbol);
}
