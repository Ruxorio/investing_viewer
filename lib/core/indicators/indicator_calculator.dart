import '../../models/technical_indicators.dart';

class IndicatorCalculator {
  const IndicatorCalculator();

  TechnicalIndicators? calculate(List<double> closes, {List<int>? volumes}) {
    final sma50 = _simpleMovingAverage(closes, 50);
    final sma200 = _simpleMovingAverage(closes, 200);
    final rsi = _relativeStrengthIndex(closes, 14);
    final macd = _macd(closes);
    final ema50 = _exponentialMovingAverage(closes, 50);
    final momentumWeek = _momentumWeek(closes);
    final relativeVolumeWeek = _relativeVolumeWeek(volumes);

    if (sma50 == null &&
        sma200 == null &&
        rsi == null &&
        macd == null &&
        ema50 == null &&
        momentumWeek == null &&
        relativeVolumeWeek == null) {
      return null;
    }

    return TechnicalIndicators(
      rsi: rsi,
      sma50: sma50,
      sma200: sma200,
      macd: macd,
      ema50: ema50,
      momentumWeek: momentumWeek,
      relativeVolumeWeek: relativeVolumeWeek,
    );
  }

  double? _simpleMovingAverage(List<double> closes, int period) {
    if (closes.length < period) {
      return null;
    }
    final slice = closes.sublist(closes.length - period);
    final sum = slice.fold<double>(0, (total, value) => total + value);
    return sum / period;
  }

  double? _relativeStrengthIndex(List<double> closes, int period) {
    if (closes.length <= period) {
      return null;
    }

    double gains = 0;
    double losses = 0;
    for (var i = closes.length - period; i < closes.length; i++) {
      final change = closes[i] - closes[i - 1];
      if (change >= 0) {
        gains += change;
      } else {
        losses += change.abs();
      }
    }

    if (losses == 0) {
      return 100;
    }

    final rs = gains / losses;
    return 100 - (100 / (1 + rs));
  }

  double? _macd(List<double> closes) {
    if (closes.length < 26) {
      return null;
    }
    final ema12 = _exponentialMovingAverage(closes, 12);
    final ema26 = _exponentialMovingAverage(closes, 26);
    if (ema12 == null || ema26 == null) {
      return null;
    }
    return ema12 - ema26;
  }

  double? _exponentialMovingAverage(List<double> closes, int period) {
    if (closes.length < period) {
      return null;
    }
    final k = 2 / (period + 1);
    double ema = closes[closes.length - period];
    for (var i = closes.length - period + 1; i < closes.length; i++) {
      ema = (closes[i] * k) + (ema * (1 - k));
    }
    return ema;
  }

  double? _momentumWeek(List<double> closes) {
    if (closes.length < 6) {
      return null;
    }
    final last = closes.last;
    final weekAgo = closes[closes.length - 6];
    if (weekAgo == 0) {
      return null;
    }
    return ((last - weekAgo) / weekAgo) * 100;
  }

  double? _relativeVolumeWeek(List<int>? volumes) {
    if (volumes == null || volumes.length < 6) {
      return null;
    }
    final last = volumes.last;
    final slice = volumes.sublist(volumes.length - 6);
    final avg = slice.fold<int>(0, (total, value) => total + value) / slice.length;
    if (avg == 0) {
      return null;
    }
    return last / avg;
  }
}
