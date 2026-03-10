import 'package:flutter/material.dart';

class StockDetailScreen extends StatelessWidget {
  const StockDetailScreen({super.key});

  static const routeName = '/stock-detail';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Detail'),
      ),
      body: const Center(
        child: Text('Stock detail placeholder'),
      ),
    );
  }
}
