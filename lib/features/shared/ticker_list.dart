import 'package:flutter/material.dart';

import '../../models/analysis_result.dart';
import '../../models/market_data.dart';
import '../../models/ticker.dart';
import '../../models/technical_indicators.dart';
import '../stock_detail/stock_detail_screen.dart';
import 'ticker_card.dart';

class TickerListItem {
  const TickerListItem({
    required this.ticker,
    required this.marketData,
    required this.analysis,
    this.indicators,
  });

  final Ticker ticker;
  final MarketData marketData;
  final AnalysisResult analysis;
  final TechnicalIndicators? indicators;
}

class TickerList extends StatelessWidget {
  const TickerList({
    required this.items,
    super.key,
    this.filter,
    this.sort,
    this.limit,
    this.onTap,
    this.itemWrapper,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<TickerListItem> items;
  final bool Function(TickerListItem item)? filter;
  final Comparator<TickerListItem>? sort;
  final int? limit;
  final void Function(BuildContext context, TickerListItem item)? onTap;
  final Widget Function(BuildContext context, TickerListItem item, Widget child)? itemWrapper;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final filteredItems = items.where((item) => filter?.call(item) ?? true).toList();
    if (sort != null) {
      filteredItems.sort(sort);
    }
    final visibleItems = limit == null ? filteredItems : filteredItems.take(limit!).toList();

    return ListView.separated(
      itemCount: visibleItems.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemBuilder: (context, index) {
        final item = visibleItems[index];

        final card = TickerCard(
          ticker: item.ticker,
          marketData: item.marketData,
          analysis: item.analysis,
          onTap: () {
            final handler = onTap ??
                (BuildContext context, TickerListItem item) {
                  Navigator.of(context).pushNamed(
                    StockDetailScreen.routeName,
                    arguments: item.ticker.symbol,
                  );
                };
            handler(context, item);
          },
        );

        if (itemWrapper != null) {
          return itemWrapper!(context, item, card);
        }
        return card;
      },
    );
  }
}
