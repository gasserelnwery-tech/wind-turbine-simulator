import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StandardsPage extends ConsumerWidget {
  const StandardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Standards', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(theme, 'IEC 61400 — Wind Turbine Design Standards', [
            _row2('Standard', 'Scope'),
            _divider(),
            _row2('IEC 61400-1', 'Overall design requirements'),
            _row2('IEC 61400-2', 'Small wind turbines'),
            _row2('IEC 61400-3', 'Offshore wind turbines'),
            _row2('IEC 61400-11', 'Acoustic noise measurement'),
            _row2('IEC 61400-12', 'Power performance'),
            _row2('IEC 61400-21', 'Power quality'),
          ]),
          _section(theme, 'Turbine Classification', [
            _row4('Class', 'Vref (m/s)', 'Iref', 'Turbulence'),
            _divider(),
            _row4('I-A', '50', '0.16', 'High'),
            _row4('II-A', '42.5', '0.16', 'High'),
            _row4('II-B', '42.5', '0.14', 'Medium'),
            _row4('III-A', '37.5', '0.16', 'High'),
            _row4('S', 'Custom', 'Custom', 'Site-specific'),
          ]),
          _section(theme, 'Betz Limit', [
            _text('The Betz limit is the theoretical maximum power coefficient Cp_max = 16/27 ≈ 0.593. '
                'It states that no wind turbine can extract more than 59.3% of the kinetic energy '
                'from the wind. This limit arises from the conservation of mass and momentum in '
                'actuator disk theory.'),
            _text('In practice, modern HAWTs achieve Cp ≈ 0.45–0.50, while Darrieus VAWTs achieve '
                'Cp ≈ 0.35–0.40, and Savonius VAWTs achieve Cp ≈ 0.15–0.25.'),
          ]),
          _section(theme, 'Tip Speed Ratio (TSR)', [
            _row3('Blades', 'Optimal TSR', 'Application'),
            _divider(),
            _row3('2', '6–8', 'High-speed, low torque'),
            _row3('3', '4–6', 'Standard HAWT'),
            _row3('4', '3–4', 'Medium speed'),
            _row3('5', '2–3', 'High torque'),
            _row3('Darrieus', '3–5', 'VAWT lift-based'),
            _row3('Savonius', '0.6–1.2', 'VAWT drag-based'),
          ]),
          _section(theme, 'Power Coefficient (Cp) — Typical Values', [
            _row3('Configuration', 'Cp range', 'Peak Cp'),
            _divider(),
            _row3('3-blade HAWT', '0.40–0.50', '0.48'),
            _row3('2-blade HAWT', '0.35–0.45', '0.42'),
            _row3('Multi-blade HAWT', '0.25–0.35', '0.32'),
            _row3('Darrieus VAWT', '0.30–0.40', '0.38'),
            _row3('Savonius VAWT', '0.12–0.25', '0.20'),
          ]),
          _section(theme, 'Key Design Formulas', [
            _formula(theme, 'Wind Power', 'P_wind = ½ ρ A v³'),
            _formula(theme, 'Extracted Power', 'P = P_wind · Cp'),
            _formula(theme, 'Swept Area (HAWT)', 'A = π r²'),
            _formula(theme, 'Swept Area (VAWT)', 'A = d · h'),
            _formula(theme, 'Tip Speed Ratio', 'TSR = ω r / v'),
            _formula(theme, 'RPM', 'RPM = TSR · v · 60 / (2π r)'),
            _formula(theme, 'Torque', 'τ = P / ω'),
            _formula(theme, 'Thrust (actuator disk)', 'T = ½ ρ A v² · 4a(1−a)'),
            _formula(theme, 'Reynolds Number', 'Re = ρ v c / μ'),
          ]),
          _section(theme, 'Reynolds Number Ranges', [
            _row3('Turbine Size', 'Re (typical)', 'Regime'),
            _divider(),
            _row3('Small (< 2m)', '2×10⁴ – 2×10⁵', 'Subcritical'),
            _row3('Medium (2–10m)', '2×10⁵ – 1×10⁶', 'Critical'),
            _row3('Large (> 10m)', '1×10⁶ – 5×10⁶', 'Supercritical'),
          ]),
          _section(theme, 'Airfoil Selection Guide', [
            _row3('Use Case', 'Recommended', 'Features'),
            _divider(),
            _row3('HAWT blade root', 'NACA 63-4xx', 'High Cl, structural'),
            _row3('HAWT blade tip', 'NACA 63-2xx', 'Low drag, high speed'),
            _row3('Darrieus VAWT', 'NACA 0015/0018', 'Symmetric, Re-tolerant'),
            _row3('Small HAWT', 'NACA 4415', 'Cambered, good stall'),
          ]),
          _section(theme, 'Materials Reference', [
            _row3('Component', 'Common Material', 'Alternative'),
            _divider(),
            _row3('Blades', 'GFRP (E-glass/epoxy)', 'CFRP, wood-epoxy'),
            _row3('Hub', 'Nodular cast iron', 'Steel fabrication'),
            _row3('Tower (small)', 'Steel tube (S235/S355)', 'Aluminum, lattice'),
            _row3('Nacelle frame', 'Welded steel', 'Cast aluminum'),
            _row3('Shaft (VAWT)', 'Steel (EN 10025)', 'Stainless steel'),
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

  Widget _row2(String c1, String c2) {
    return Semantics(
      label: '$c1: $c2',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 150, child: Text(c1, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
            Expanded(child: Text(c2, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
          ],
        ),
      ),
    );
  }

  Widget _row3(String c1, String c2, String c3) {
    return Semantics(
      label: '$c1: $c2, $c3',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 150, child: Text(c1, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
            SizedBox(width: 100, child: Text(c2, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
            Expanded(child: Text(c3, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
          ],
        ),
      ),
    );
  }

  Widget _row4(String c1, String c2, String c3, String c4) {
    return Semantics(
      label: '$c1: $c2, $c3, $c4',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 100, child: Text(c1, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
            SizedBox(width: 90, child: Text(c2, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
            SizedBox(width: 70, child: Text(c3, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
            Expanded(child: Text(c4, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 8, thickness: 0.5);

  Widget _text(String t) {
    return Semantics(
      label: t,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 11, height: 1.5, fontFamily: 'monospace')),
      ),
    );
  }

  Widget _formula(ThemeData theme, String name, String formula) {
    return Semantics(
      label: '$name: $formula',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(width: 172, child: Text(name, style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1E28),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(formula, style: TextStyle(
                  fontSize: 11, fontFamily: 'monospace',
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
