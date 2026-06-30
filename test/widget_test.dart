import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wind_turbine_sim/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WindTurbineApp()));
    expect(find.text('Wind Turbine Sim'), findsOneWidget);
  });
}
