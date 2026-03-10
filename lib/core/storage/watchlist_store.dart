import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/ticker.dart';

class WatchlistStore extends ChangeNotifier {
  WatchlistStore._();

  static final WatchlistStore instance = WatchlistStore._();
  static const _prefsKey = 'watchlist_symbols';
  static const _prefsKeyV2 = 'watchlist_tickers_v2';
  static const _seedSymbols = {'ROOT', 'SOUN', 'TSSI', 'NVDA', 'AVGO'};
  Future<void>? _loadFuture;

  final List<Ticker> _tickers = [];

  List<Ticker> get tickers => List.unmodifiable(_tickers);

  Future<void> ensureLoaded() {
    _loadFuture ??= _load();
    return _loadFuture!;
  }

  bool containsSymbol(String symbol) {
    return _tickers.any((ticker) => ticker.symbol == symbol.toUpperCase());
  }

  void addTicker(String symbol, {String? companyName}) {
    final normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty || containsSymbol(normalized)) {
      return;
    }
    _tickers.add(Ticker(symbol: normalized, companyName: companyName));
    notifyListeners();
    _save();
  }

  void updateTickerMetadata(String symbol, {String? companyName, String? sector}) {
    final normalized = symbol.trim().toUpperCase();
    final index = _tickers.indexWhere((ticker) => ticker.symbol == normalized);
    if (index == -1) {
      return;
    }
    final current = _tickers[index];
    final next = Ticker(
      symbol: current.symbol,
      companyName: companyName ?? current.companyName,
      sector: sector ?? current.sector,
    );
    if (next.companyName == current.companyName && next.sector == current.sector) {
      return;
    }
    _tickers[index] = next;
    notifyListeners();
    _save();
  }

  void removeTicker(String symbol) {
    _tickers.removeWhere((ticker) => ticker.symbol == symbol.toUpperCase());
    notifyListeners();
    _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedTickers = prefs.getStringList(_prefsKeyV2);
    if (encodedTickers != null && encodedTickers.isNotEmpty) {
      _tickers
        ..clear()
        ..addAll(_decodeTickers(encodedTickers));
      notifyListeners();
      return;
    }

    final symbols = prefs.getStringList(_prefsKey);
    if (symbols == null || symbols.isEmpty) {
      return;
    }
    final filteredSymbols = symbols
        .map((symbol) => symbol.trim().toUpperCase())
        .where((symbol) => symbol.isNotEmpty && !_seedSymbols.contains(symbol))
        .toList();
    if (filteredSymbols.isEmpty) {
      return;
    }
    _tickers
      ..clear()
      ..addAll(filteredSymbols.map((symbol) => Ticker(symbol: symbol)));
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _tickers.map(_encodeTicker).toList();
    await prefs.setStringList(_prefsKeyV2, encoded);
  }

  String _encodeTicker(Ticker ticker) {
    return json.encode({
      'symbol': ticker.symbol,
      'companyName': ticker.companyName,
      'sector': ticker.sector,
    });
  }

  List<Ticker> _decodeTickers(List<String> encoded) {
    final tickers = <Ticker>[];
    for (final entry in encoded) {
      try {
        final data = json.decode(entry) as Map<String, dynamic>;
        final symbol = (data['symbol'] as String?)?.trim().toUpperCase();
        if (symbol == null || symbol.isEmpty) {
          continue;
        }
        tickers.add(
          Ticker(
            symbol: symbol,
            companyName: data['companyName'] as String?,
            sector: data['sector'] as String?,
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return tickers;
  }
}
