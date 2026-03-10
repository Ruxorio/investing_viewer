import 'package:flutter/material.dart';

import '../../models/analysis_result.dart';
import '../../models/market_data.dart';
import '../../models/ticker.dart';

class TickerCard extends StatelessWidget {
  const TickerCard({
    required this.ticker,
    required this.marketData,
    required this.analysis,
    this.onTap,
    super.key,
  });

  final Ticker ticker;
  final MarketData marketData;
  final AnalysisResult analysis;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final change = marketData.changePercent;
    final changeText = change >= 0 ? '+${change.toStringAsFixed(1)}%' : '${change.toStringAsFixed(1)}%';

    return ListTile(
      title: Text(ticker.symbol),
      subtitle: Text(ticker.companyName ?? 'Unknown company'),
      onTap: onTap,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('\$${marketData.price.toStringAsFixed(2)}'),
          Text(changeText),
          Text(
            _signalLabel(analysis.overallScore),
            style: TextStyle(color: _signalColor(analysis.overallScore)),
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
