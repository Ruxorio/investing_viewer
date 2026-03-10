import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/analysis_engine/analysis_service.dart';
import '../../core/api/finnhub_market_data_service.dart';
import '../../core/api/market_data_repository.dart';
import '../../core/api/twelve_data_provider.dart';
import '../../core/storage/watchlist_store.dart';
import '../../models/analysis_result.dart';
import '../../models/market_data.dart';
import '../../models/technical_indicators.dart';
import '../../models/ticker.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({required this.symbol, super.key});

  static const routeName = AppRoutes.stockDetail;

  final String symbol;

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  late final Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_DetailData> _loadData() async {
    await WatchlistStore.instance.ensureLoaded();
    final marketService = MarketDataRepository(
      quoteProvider: FinnhubProvider(
        apiKey: const String.fromEnvironment('FINNHUB_API_KEY'),
      ),
      candleProvider: TwelveDataProvider(
        apiKey: const String.fromEnvironment('TWELVE_DATA_API_KEY'),
      ),
    );
    const analysisService = AnalysisService();

    final tickers = WatchlistStore.instance.tickers;
    final existingTicker = tickers.firstWhere(
      (t) => t.symbol == widget.symbol,
      orElse: () => Ticker(symbol: widget.symbol),
    );

    final results = await Future.wait([
      marketService.fetchQuote(widget.symbol),
      marketService.fetchIndicators(widget.symbol),
      existingTicker.companyName == null || existingTicker.companyName!.isEmpty
          ? marketService.fetchCompanyName(widget.symbol)
          : Future.value(existingTicker.companyName),
    ]);
    final marketData = results[0] as MarketData;
    final indicators = results[1] as TechnicalIndicators?;
    final companyName = results[2] as String?;
    final analysis = analysisService.analyze(marketData, indicators: indicators);
    final indicatorError =
        marketService.lastIndicatorErrorFor(widget.symbol) ?? marketService.lastCandleErrorFor(widget.symbol);
    final ticker = Ticker(
      symbol: existingTicker.symbol,
      companyName: existingTicker.companyName ?? companyName,
      sector: existingTicker.sector,
    );

    return _DetailData(
      ticker: ticker,
      marketData: marketData,
      analysis: analysis,
      indicators: indicators,
      indicatorError: indicatorError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.symbol),
      ),
      body: FutureBuilder<_DetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No data available.'));
          }

          final marketData = data.marketData;
          final analysis = data.analysis;
          final volumeText = marketData.volume == 0 ? 'N/A' : marketData.volume.toString();
          final indicators = data.indicators;
          final indicatorError = data.indicatorError;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                data.ticker.companyName ?? 'Unknown company',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'Price', value: '\$${marketData.price.toStringAsFixed(2)}'),
              _DetailRow(
                label: 'Change',
                value:
                    '${marketData.changePercent >= 0 ? '+' : ''}${marketData.changePercent.toStringAsFixed(1)}%',
              ),
              _DetailRow(label: 'Volume', value: volumeText),
              const SizedBox(height: 24),
              const Text('Signals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _SignalRow(label: 'Momentum', signal: analysis.momentumSignal),
              _SignalRow(label: 'Volume', signal: analysis.volumeSignal),
              _SignalRow(label: 'RSI', signal: analysis.rsiSignal),
              _SignalRow(label: 'Breakout', signal: analysis.breakoutSignal),
              const SizedBox(height: 12),
              _SignalRow(label: 'Overall', signal: analysis.overallScore),
              const SizedBox(height: 24),
              const Text('Indicators', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (indicators == null)
                Text(
                  indicatorError == null
                      ? 'Indicadores no disponibles. Revisa datos de velas o limites de la API.'
                      : 'Indicadores no disponibles: $indicatorError',
                )
              else ...[
                _IndicatorRow(
                  label: 'RSI (14)',
                  value: _formatIndicator(indicators.rsi),
                ),
                _IndicatorRow(
                  label: 'EMA 50',
                  value: _formatIndicator(indicators.ema50),
                ),
                _IndicatorRow(
                  label: 'SMA 50',
                  value: _formatIndicator(indicators.sma50),
                ),
                _IndicatorRow(
                  label: 'SMA 200',
                  value: _formatIndicator(indicators.sma200),
                ),
                _IndicatorRow(
                  label: 'MACD',
                  value: _formatIndicator(indicators.macd),
                ),
                _IndicatorRow(
                  label: 'Momentum (1w)',
                  value: _formatPercent(indicators.momentumWeek),
                ),
                _IndicatorRow(
                  label: 'Rel Vol (1w)',
                  value: _formatRatio(indicators.relativeVolumeWeek),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DetailData {
  const _DetailData({
    required this.ticker,
    required this.marketData,
    required this.analysis,
    required this.indicators,
    required this.indicatorError,
  });

  final Ticker ticker;
  final MarketData marketData;
  final AnalysisResult analysis;
  final TechnicalIndicators? indicators;
  final String? indicatorError;
}

class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

String _formatIndicator(double? value) {
  if (value == null) {
    return 'N/A';
  }
  return value.toStringAsFixed(2);
}

String _formatPercent(double? value) {
  if (value == null) {
    return 'N/A';
  }
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2)}%';
}

String _formatRatio(double? value) {
  if (value == null) {
    return 'N/A';
  }
  return value.toStringAsFixed(2);
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({required this.label, required this.signal});

  final String label;
  final Signal signal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            _signalLabel(signal),
            style: TextStyle(color: _signalColor(signal), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _signalLabel(Signal signal) {
    switch (signal) {
      case Signal.bullish:
        return 'Bullish';
      case Signal.bearish:
        return 'Bearish';
      case Signal.oversold:
        return 'Oversold';
      case Signal.overbought:
        return 'Overbought';
      case Signal.neutral:
        return 'Neutral';
    }
  }

  Color _signalColor(Signal signal) {
    switch (signal) {
      case Signal.bullish:
        return Colors.green;
      case Signal.bearish:
        return Colors.red;
      case Signal.oversold:
        return Colors.teal;
      case Signal.overbought:
        return Colors.deepOrange;
      case Signal.neutral:
        return Colors.blueGrey;
    }
  }
}
