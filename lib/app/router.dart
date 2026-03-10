import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'routes.dart';
import '../features/settings/settings_screen.dart';
import '../features/stock_detail/stock_detail_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          builder: (_) => const AppShell(),
          settings: settings,
        );
      case AppRoutes.dashboard:
        return MaterialPageRoute<void>(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      case AppRoutes.watchlist:
        return MaterialPageRoute<void>(
          builder: (_) => const WatchlistScreen(),
          settings: settings,
        );
      case AppRoutes.stockDetail:
        final symbol = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => StockDetailScreen(
            symbol: symbol is String ? symbol : 'Unknown',
          ),
          settings: settings,
        );
      case AppRoutes.settings:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const AppShell(),
          settings: settings,
        );
    }
  }
}
