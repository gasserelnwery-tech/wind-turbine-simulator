import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalculatorPage extends ConsumerWidget {
  const CalculatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wind Power Calculator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(theme, 'Wind Power Formula', [
            const SizedBox(height: 4),
            _text('The power available in wind is calculated using the kinetic energy flux through the rotor swept area:'),
            const SizedBox(height: 8),
            _formulaCard(theme, 'P_wind = ½ · ρ · A · V³'),
            const SizedBox(height: 8),
            _text('Where:'),
            _text('  P_wind = total wind power (Watts)'),
            _text('  ρ = air density (kg/m³) — default 1.225 at sea level'),
            _text('  A = rotor swept area (m²) — A = π · r² for HAWT'),
            _text('  V = wind speed (m/s)'),
          ]),
          _section(theme, 'Extracted Power', [
            _text('The actual power extracted by the turbine is:'),
            const SizedBox(height: 8),
            _formulaCard(theme, 'P = Cp · ½ · ρ · A · V³'),
            const SizedBox(height: 8),
            _text('Where Cp (power coefficient) is limited by the Betz limit of 16/27 ≈ 0.593.'),
            _text('Our simulator allows Cp values from 0.10 to 0.55, with Newton-Raphson iteration adjusting the axial induction factor a to determine the actual flow conditions at the rotor plane.'),
          ]),
          _section(theme, 'Step-by-Step Calculation', [
            _text('1. Swept Area:  A = π · r²  (for HAWT — horizontal axis)'),
            _text('2. Wind Power:  P_wind = ½ · ρ · A · V³'),
            _text('3. Axial Induction Factor (a): solved via Newton-Raphson:'),
            _text('     f(a) = 4a(1−a)² − Cp'),
            _text('     a_{n+1} = a_n − f(a_n) / f\'(a_n)'),
            _text('4. Extracted Power:  P = P_wind · Cp'),
            _text('5. Rotor RPM:  RPM = TSR · V · 60 / (2π · r)'),
            _text('6. Torque:  τ = P / ω  (where ω = 2π · RPM / 60)'),
            _text('7. Thrust:  T = ½ · ρ · A · V² · 4a(1−a)'),
          ]),
          _section(theme, 'Example Calculation', [
            _text('For a Standard HAWT (3-blade, r=5m, V=6 m/s, ρ=1.225, Cp=0.45):'),
            const SizedBox(height: 8),
            _text('  A = π · 25 = 78.54 m²'),
            _text('  P_wind = 0.5 · 1.225 · 78.54 · 216 = 10,388 W'),
            _text('  P = 0.45 · 10,388 = 4,675 W'),
            _text('  At TSR = 5: RPM = 5 · 6 · 60 / (2π · 5) = 57.3 RPM'),
            _text('  Torque = 4,675 / (2π · 57.3/60) = 779 Nm'),
            _text('  Thrust = 0.5 · 1.225 · 78.54 · 36 · 4·0.2·0.8 = 1,108 N'),
            const SizedBox(height: 8),
            _text('Note: The actual simulation uses Newton-Raphson iteration to solve for the induction factor a, which adjusts Cp based on the Betz limit constraint. The example above uses a simplified approximation.'),
          ]),
          _section(theme, 'Interactive Simulator', [
            _text('Adjust these parameters in real-time on the main simulator page:'),
            _text('  • Wind Speed (0–25 m/s)'),
            _text('  • Rotor Radius (0.5–10 m)'),
            _text('  • Blade Count (1–6)'),
            _text('  • Tip Speed Ratio (0.5–12)'),
            _text('  • Pitch Angle (−10° to 30°)'),
            _text('  • Air Density (0.8–1.4 kg/m³)'),
            _text('  • Power Coefficient (0.10–0.55)'),
            _text(''),
            _text('Switch between 5 turbine presets: Standard HAWT, High-Speed HAWT, High-Torque HAWT, Darrieus VAWT, and Savonius VAWT to compare performance characteristics.'),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _section(ThemeData theme, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary, fontWeight: FontWeight.w700,
              fontSize: 13,
            )),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _text(String t) {
    return Semantics(
      label: t,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t, style: const TextStyle(fontSize: 11, height: 1.5, fontFamily: 'monospace')),
      ),
    );
  }

  Widget _formulaCard(ThemeData theme, String formula) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E28),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(formula, style: TextStyle(
        fontSize: 13, fontFamily: 'monospace',
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      )),
    );
  }
}
