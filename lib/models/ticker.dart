class Ticker {
  const Ticker({
    required this.symbol,
    this.companyName,
    this.sector,
  });

  final String symbol;
  final String? companyName;
  final String? sector;
}
