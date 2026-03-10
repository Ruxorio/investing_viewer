import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stock_detail/stock_detail_screen.dart';
import '../features/watchlist/watchlist_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case DashboardScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      case WatchlistScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const WatchlistScreen(),
          settings: settings,
        );
      case StockDetailScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const StockDetailScreen(),
          settings: settings,
        );
      case SettingsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
    }
  }
}
