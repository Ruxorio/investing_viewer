class MarketData {
  const MarketData({
    required this.symbol,
    required this.price,
    required this.changePercent,
    required this.volume,
    this.marketCap,
    this.eps,
    this.revenueGrowth,
  });

  final String symbol;
  final double price;
  final double changePercent;
  final int volume;
  final double? marketCap;
  final double? eps;
  final double? revenueGrowth;
}
