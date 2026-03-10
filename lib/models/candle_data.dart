class CandleData {
  const CandleData({
    this.closes = const [],
    this.volumes = const [],
  });

  final List<double> closes;
  final List<int> volumes;
}
