import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/simulation_engine.dart' show SuggestionEngine, TurbineType;
import '../../providers/simulation_provider.dart';

class ControlsPanel extends ConsumerWidget {
  const ControlsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(simulationProvider);
    final p = state.params;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Parameters', Icons.tune, theme),
          const SizedBox(height: 8),
          _paramSlider(context, ref, 'Wind Speed', 'windSpeed', p.windSpeed, 0.5, 25, 0.5, 'm/s'),
          _paramSlider(context, ref, 'Rotor Radius', 'rotorRadius', p.rotorRadius, 0.1, 3.0, 0.1, 'm'),
          _paramSlider(context, ref, 'Power Coefficient (Cp)', 'cp', p.cp, 0.01, 0.55, 0.01, ''),
          _paramSlider(context, ref, 'Air Density', 'airDensity', p.airDensity, 0.8, 1.5, 0.005, 'kg/m³'),
          _paramSlider(context, ref, 'Tip Speed Ratio', 'tsr', p.tsr, 0.5, 10, 0.5, ''),
          _paramSlider(context, ref, 'Pitch Angle', 'pitchAngle', p.pitchAngle, -5, 20, 1, 'deg'),

          const SizedBox(height: 8),
          _sectionHeader('Turbine Type', Icons.precision_manufacturing, theme),
          const SizedBox(height: 4),
          _turbineTypeSelector(context, ref, p.turbineType),

          if (!p.turbineType.isVawt) ...[
            const SizedBox(height: 8),
            _sectionHeader('Blades', Icons.rotate_right, theme),
            const SizedBox(height: 4),
            _bladeSelector(context, ref, p.bladeCount),
          ],

          const SizedBox(height: 12),
          _suggestionBox(context, ref),

          const SizedBox(height: 8),
          _resultsBox(context, state),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _paramSlider(BuildContext context, WidgetRef ref, String label,
      String key, double value, double min, double max, double step, String unit) {
    final simParams = ref.read(simulationProvider).params;
    String warning = SuggestionEngine.warningFor(key, value,
        bladeCount: key == 'tsr' ? simParams.bladeCount : null,
        turbineType: key == 'pitchAngle' ? simParams.turbineType : null);
    bool hasWarning = warning.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: '$label: ${value.toStringAsFixed(step < 1 ? 1 : 2)} $unit ${hasWarning ? ". Warning: $warning" : ""}',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 4),
                Text('${value.toStringAsFixed(step < 1 ? 1 : 2)} $unit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: hasWarning ? Colors.orangeAccent : null)),
              ],
            ),
          ),
          Slider(
            value: value.clamp(min, max),
            min: min, max: max, divisions: ((max - min) / step).round().clamp(1, 1000),
            onChanged: (v) => ref.read(simulationProvider.notifier).updateParam(key, v),
          ),
          if (hasWarning)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Semantics(
                liveRegion: true,
                child: Text(warning, style: TextStyle(fontSize: 10, color: Colors.orangeAccent[200])),
              ),
            ),
        ],
      ),
    );
  }

  Widget _turbineTypeSelector(BuildContext context, WidgetRef ref, TurbineType current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: TurbineType.values.map((type) {
        bool selected = type == current;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: InkWell(
            onTap: () => ref.read(simulationProvider.notifier).updateTurbineType(type),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    type.isVawt ? Icons.swap_vert : Icons.rotate_right,
                    size: 16,
                    color: selected ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.check, size: 14),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _bladeSelector(BuildContext context, WidgetRef ref, int current) {
    return Row(
      children: [2, 3, 4, 5, 6].map((n) {
        bool selected = n == current;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text('$n'),
            selected: selected,
            onSelected: (_) => ref.read(simulationProvider.notifier).updateBladeCount(n),
            selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        );
      }).toList(),
    );
  }

  Widget _suggestionBox(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text('Suggestions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Cp: 0.30–0.45 | TSR: ${SuggestionEngine.suggestedTsr(ref.read(simulationProvider).params.bladeCount)} for ${ref.read(simulationProvider).params.bladeCount} blades | Pitch: ${ref.read(simulationProvider).params.turbineType.defaultPitch}° optimal',
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.auto_fix_high, size: 14),
              label: const Text('Apply Suggested Values', style: TextStyle(fontSize: 11)),
              onPressed: () => ref.read(simulationProvider.notifier).applySuggestions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsBox(BuildContext context, SimulationState state) {
    final r = state.results;
    if (r == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, size: 16, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 6),
              Text('Results', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          _resultRow('Power', '${r.power.toStringAsFixed(1)} W', Colors.cyan),
          _resultRow('RPM', r.rpm.toStringAsFixed(1), Colors.greenAccent),
          _resultRow('Torque', '${r.torque.toStringAsFixed(3)} N·m', Colors.orangeAccent),
          _resultRow('Thrust', '${r.thrust.toStringAsFixed(2)} N', Colors.redAccent),
          _resultRow('Eff. Cp (pitch)', r.effectiveCp.toStringAsFixed(3), r.pitchFactor < 0.95 ? Colors.orangeAccent : Colors.grey),
          _resultRow('Swept Area', '${r.sweptArea.toStringAsFixed(3)} m²', Colors.grey),
          _resultRow('Tip Speed', '${r.tipSpeed.toStringAsFixed(1)} m/s', Colors.purpleAccent),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
