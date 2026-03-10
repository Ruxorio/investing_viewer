import '../../models/analysis_result.dart';
import '../../models/market_data.dart';
import '../../models/technical_indicators.dart';

class AnalysisService {
  const AnalysisService();

  AnalysisResult analyze(MarketData data, {TechnicalIndicators? indicators}) {
    final momentumSignal = indicators == null || indicators.sma50 == null || indicators.sma200 == null
        ? _signalFromChange(data.changePercent)
        : _signalFromMomentum(indicators);
    final volumeSignal = data.volume >= 1500000 ? Signal.bullish : Signal.neutral;
    final rsiSignal = indicators == null || indicators.rsi == null
        ? _rsiSignalFromChange(data.changePercent)
        : _rsiSignal(indicators);
    final breakoutSignal = data.changePercent >= 5 ? Signal.bullish : Signal.neutral;

    final overallScore = _overallScore(
      momentum: momentumSignal,
      volume: volumeSignal,
      rsi: rsiSignal,
      breakout: breakoutSignal,
    );

    return AnalysisResult(
      momentumSignal: momentumSignal,
      volumeSignal: volumeSignal,
      rsiSignal: rsiSignal,
      breakoutSignal: breakoutSignal,
      overallScore: overallScore,
    );
  }

  Signal _signalFromChange(double changePercent) {
    if (changePercent >= 2.5) {
      return Signal.bullish;
    }
    if (changePercent <= -2.5) {
      return Signal.bearish;
    }
    return Signal.neutral;
  }

  Signal _rsiSignalFromChange(double changePercent) {
    if (changePercent >= 4.0) {
      return Signal.overbought;
    }
    if (changePercent <= -4.0) {
      return Signal.oversold;
    }
    return Signal.neutral;
  }

  Signal _rsiSignal(TechnicalIndicators indicators) {
    final rsi = indicators.rsi;
    if (rsi == null) {
      return Signal.neutral;
    }
    if (rsi >= 70) {
      return Signal.overbought;
    }
    if (rsi <= 30) {
      return Signal.oversold;
    }
    return Signal.neutral;
  }

  Signal _signalFromMomentum(TechnicalIndicators indicators) {
    final sma50 = indicators.sma50;
    final sma200 = indicators.sma200;
    if (sma50 == null || sma200 == null) {
      return Signal.neutral;
    }
    if (sma50 > sma200) {
      return Signal.bullish;
    }
    if (sma50 < sma200) {
      return Signal.bearish;
    }
    return Signal.neutral;
  }

  Signal _overallScore({
    required Signal momentum,
    required Signal volume,
    required Signal rsi,
    required Signal breakout,
  }) {
    if (rsi == Signal.overbought) {
      return Signal.bearish;
    }
    if (rsi == Signal.oversold) {
      return Signal.bullish;
    }
    if (momentum == Signal.bullish && volume == Signal.bullish) {
      return Signal.bullish;
    }
    if (momentum == Signal.bearish) {
      return Signal.bearish;
    }
    if (breakout == Signal.bullish) {
      return Signal.bullish;
    }
    return Signal.neutral;
  }
}
