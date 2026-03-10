enum Signal {
  bullish,
  bearish,
  neutral,
  oversold,
  overbought,
}

class AnalysisResult {
  const AnalysisResult({
    required this.momentumSignal,
    required this.volumeSignal,
    required this.rsiSignal,
    required this.breakoutSignal,
    required this.overallScore,
  });

  final Signal momentumSignal;
  final Signal volumeSignal;
  final Signal rsiSignal;
  final Signal breakoutSignal;
  final Signal overallScore;
}
