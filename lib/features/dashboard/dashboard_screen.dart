import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/analysis_engine/analysis_service.dart';
import '../../core/api/finnhub_market_data_service.dart';
import '../../core/api/market_data_repository.dart';
import '../../core/api/twelve_data_provider.dart';
import '../../core/storage/watchlist_store.dart';
import '../../models/analysis_result.dart';
import '../../models/ticker.dart';
import '../shared/ticker_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const routeName = AppRoutes.dashboard;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<TickerListItem>> _future;
  final _watchlistStore = WatchlistStore.instance;

  @override
  void initState() {
    super.initState();
    _future = _loadItems();
    _watchlistStore.addListener(_refresh);
  }

  @override
  void dispose() {
    _watchlistStore.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = _loadItems();
    });
  }

  Future<List<TickerListItem>> _loadItems() async {
    await _watchlistStore.ensureLoaded();
    final marketService = MarketDataRepository(
      quoteProvider: FinnhubProvider(
        apiKey: const String.fromEnvironment('FINNHUB_API_KEY'),
      ),
      candleProvider: TwelveDataProvider(
        apiKey: const String.fromEnvironment('TWELVE_DATA_API_KEY'),
      ),
    );
    const analysisService = AnalysisService();

    final tickers = _watchlistStore.tickers;
    final data = await marketService.fetchQuotes(tickers);
    final companyNames = await Future.wait(
      tickers.map(
        (ticker) => ticker.companyName == null || ticker.companyName!.isEmpty
            ? marketService.fetchCompanyName(ticker.symbol)
            : Future.value(ticker.companyName),
      ),
    );

    final items = <TickerListItem>[];
    for (var index = 0; index < tickers.length; index++) {
      final companyName = companyNames[index];
      if (companyName != null && companyName.isNotEmpty) {
        _watchlistStore.updateTickerMetadata(tickers[index].symbol, companyName: companyName);
      }
      items.add(
        TickerListItem(
          ticker: Ticker(
            symbol: tickers[index].symbol,
            companyName: companyName ?? tickers[index].companyName,
            sector: tickers[index].sector,
          ),
          marketData: data[index],
          analysis: analysisService.analyze(data[index]),
          indicators: null,
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: FutureBuilder<List<TickerListItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No data available.'));
          }
          final summary = _buildSummary(items.map((item) => item.analysis).toList());

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Resumen de señales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _SummaryRow(label: 'Bullish', value: summary.bullishCount, color: _signalColor(Signal.bullish)),
              _SummaryRow(label: 'Bearish', value: summary.bearishCount, color: _signalColor(Signal.bearish)),
              _SummaryRow(label: 'Oversold', value: summary.oversoldCount, color: _signalColor(Signal.oversold)),
              _SummaryRow(label: 'Overbought', value: summary.overboughtCount, color: _signalColor(Signal.overbought)),
              _SummaryRow(label: 'Neutral', value: summary.neutralCount, color: _signalColor(Signal.neutral)),
              const SizedBox(height: 24),
              const Text('Top movers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TickerList(
                items: items,
                sort: (a, b) => b.marketData.changePercent.compareTo(a.marketData.changePercent),
                limit: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ],
          );
        },
      ),
    );
  }

  _SignalSummary _buildSummary(List<AnalysisResult> analyses) {
    var bullish = 0;
    var bearish = 0;
    var oversold = 0;
    var overbought = 0;
    var neutral = 0;

    for (final analysis in analyses) {
      switch (analysis.overallScore) {
        case Signal.bullish:
          bullish++;
        case Signal.bearish:
          bearish++;
        case Signal.oversold:
          oversold++;
        case Signal.overbought:
          overbought++;
        case Signal.neutral:
          neutral++;
      }
    }

    return _SignalSummary(
      bullishCount: bullish,
      bearishCount: bearish,
      oversoldCount: oversold,
      overboughtCount: overbought,
      neutralCount: neutral,
    );
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

class _SignalSummary {
  const _SignalSummary({
    required this.bullishCount,
    required this.bearishCount,
    required this.oversoldCount,
    required this.overboughtCount,
    required this.neutralCount,
  });

  final int bullishCount;
  final int bearishCount;
  final int oversoldCount;
  final int overboughtCount;
  final int neutralCount;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value.toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
