import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/simulation_provider.dart';

class SimulationCharts extends ConsumerWidget {
  const SimulationCharts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(simulationProvider);
    final data = state.curveData;
    if (data.isEmpty) return const SizedBox();

    // Force chart rebuild on data change via hash key
    final dataKey = Object.hashAll(data.map((d) => Object.hash(d.windSpeed, d.power, d.rpm, d.cp)));

    String curveSummary = data.isNotEmpty
        ? 'Power from ${data.first.power.toStringAsFixed(0)} to ${data.last.power.toStringAsFixed(0)} W, RPM from ${data.first.rpm.toStringAsFixed(0)} to ${data.last.rpm.toStringAsFixed(0)}'
        : '';

    return Semantics(
      label: 'Performance curves. $curveSummary',
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text('Performance Curves', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[400])),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _powerChart(context, data, dataKey)),
                Expanded(child: _rpmChart(context, data, dataKey)),
                Expanded(child: _cpChart(context, data, dataKey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineTouchData _touchData(String label) {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            return LineTooltipItem(
              '${spot.x.toStringAsFixed(1)} m/s\n${spot.y.toStringAsFixed(1)} $label',
              const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
            );
          }).toList();
        },
      ),
    );
  }

  Widget _powerChart(BuildContext context, List<({double windSpeed, double power, double rpm, double cp})> data, int dataKey) {
    String maxPower = data.isNotEmpty ? '${data.map((d) => d.power).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)} W' : '0 W';
    return Semantics(
      label: 'Power chart, max power $maxPower',
      child: Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Power (W)', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 1)),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 2, maxX: 20,
                minY: 0,
                lineTouchData: _touchData('W'),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.where((d) => d.windSpeed >= 2).map((d) => FlSpot(d.windSpeed, d.power)).toList(),
                    color: Colors.cyan,
                    barWidth: 2,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
              duration: Duration.zero,
              key: ValueKey('power_$dataKey'),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _rpmChart(BuildContext context, List<({double windSpeed, double power, double rpm, double cp})> data, int dataKey) {
    String maxRpm = data.isNotEmpty ? '${data.map((d) => d.rpm).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)} RPM' : '0';
    return Semantics(
      label: 'RPM chart, max $maxRpm',
      child: Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RPM', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 1)),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 2, maxX: 20,
                minY: 0,
                lineTouchData: _touchData('RPM'),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.where((d) => d.windSpeed >= 2).map((d) => FlSpot(d.windSpeed, d.rpm)).toList(),
                    color: Colors.greenAccent,
                    barWidth: 2,
                    isCurved: true,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
              duration: Duration.zero,
              key: ValueKey('rpm_$dataKey'),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _cpChart(BuildContext context, List<({double windSpeed, double power, double rpm, double cp})> data, int dataKey) {
    double maxCp = data.isNotEmpty ? data.map((d) => d.cp).reduce((a, b) => a > b ? a : b) : 0;
    return Semantics(
      label: 'CP chart, max Cp ${maxCp.toStringAsFixed(3)}, Betz limit 0.593',
      child: Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cp', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withValues(alpha: 0.15), strokeWidth: 1)),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 2, maxX: 20,
                minY: 0, maxY: 0.6,
                lineTouchData: _touchData('Cp'),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.where((d) => d.windSpeed >= 2).map((d) => FlSpot(d.windSpeed, d.cp)).toList(),
                    color: Colors.orangeAccent,
                    barWidth: 2,
                    isCurved: true,
                    dotData: FlDotData(show: false),
                  ),
                ],
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(y: 0.593, color: Colors.red.withValues(alpha: 0.4), strokeWidth: 1, dashArray: [4, 4], label: HorizontalLineLabel(show: false)),
                ]),
              ),
              duration: Duration.zero,
              key: ValueKey('cp_$dataKey'),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
