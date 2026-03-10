import 'package:flutter/material.dart';

import '../../core/analysis_engine/analysis_service.dart';
import '../../core/api/finnhub_market_data_service.dart';
import '../../core/api/market_data_repository.dart';
import '../../core/api/twelve_data_provider.dart';
import '../../core/storage/watchlist_store.dart';
import '../../models/ticker.dart';
import '../../app/routes.dart';
import '../stock_detail/stock_detail_screen.dart';
import '../shared/ticker_list.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  static const routeName = AppRoutes.watchlist;

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
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
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddTickerDialog,
          ),
        ],
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
            return const Center(child: Text('Watchlist empty.'));
          }
          return TickerList(
            items: items,
            onTap: (context, item) {
              Navigator.of(context).pushNamed(
                StockDetailScreen.routeName,
                arguments: item.ticker.symbol,
              );
            },
            itemWrapper: (context, item, child) {
              return Dismissible(
                key: ValueKey(item.ticker.symbol),
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _watchlistStore.removeTicker(item.ticker.symbol),
                child: child,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddTickerDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add ticker'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'e.g. AAPL'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    final symbol = result.trim().toUpperCase();
    if (symbol.isEmpty) {
      _showMessage('Ticker inválido.');
      return;
    }
    if (_watchlistStore.containsSymbol(symbol)) {
      _showMessage('Ticker ya existe en la lista.');
      return;
    }

    final ticker = await _validateSymbol(symbol);
    if (ticker == null) {
      _showMessage('Ticker no válido o sin datos.');
      return;
    }

    _watchlistStore.addTicker(ticker.symbol, companyName: ticker.companyName);
  }

  Future<Ticker?> _validateSymbol(String symbol) async {
    final marketService = MarketDataRepository(
      quoteProvider: FinnhubProvider(
        apiKey: const String.fromEnvironment('FINNHUB_API_KEY'),
      ),
      candleProvider: TwelveDataProvider(
        apiKey: const String.fromEnvironment('TWELVE_DATA_API_KEY'),
      ),
    );
    _showLoading('Validando...');
    try {
      final isValid = await marketService.isValidSymbol(symbol);
      if (!isValid) {
        return null;
      }
      final companyName = await marketService.fetchCompanyName(symbol);
      return Ticker(symbol: symbol, companyName: companyName);
    } catch (_) {
      return null;
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showLoading(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
