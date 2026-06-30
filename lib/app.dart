import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/pages/home_page.dart';
import 'ui/theme.dart';
import 'ui/pages/standards_page.dart' deferred as s;
import 'ui/pages/calculator_page.dart' deferred as c;

class WindTurbineApp extends ConsumerWidget {
  const WindTurbineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Wind Turbine Simulator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomePage(),
      routes: {
        '/standards': (context) => const _DeferredStandardsPage(),
        '/calculator': (context) => const _DeferredCalculatorPage(),
      },
    );
  }
}

class _DeferredStandardsPage extends StatelessWidget {
  const _DeferredStandardsPage();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: s.loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return s.StandardsPage();
      },
    );
  }
}

class _DeferredCalculatorPage extends StatelessWidget {
  const _DeferredCalculatorPage();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: c.loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return c.CalculatorPage();
      },
    );
  }
}
