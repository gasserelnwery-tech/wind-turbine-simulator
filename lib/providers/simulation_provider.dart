import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/simulation_engine.dart';
import '../models/turbine_model.dart';
import '../renderer/camera.dart' show Camera3D;

class SimulationState {
  final SimulationParams params;
  final SimulationResults? results;
  final TurbineState turbine;
  final List<({double windSpeed, double power, double rpm, double cp})> curveData;
  final double elapsedTime;
  final double lastRpm;

  SimulationState({
    required this.params,
    this.results,
    required this.turbine,
    required this.curveData,
    this.elapsedTime = 0,
    this.lastRpm = 0,
  });

  SimulationState copyWith({
    SimulationParams? params,
    SimulationResults? results,
    TurbineState? turbine,
    List<({double windSpeed, double power, double rpm, double cp})>? curveData,
    double? elapsedTime,
    double? lastRpm,
  }) {
    return SimulationState(
      params: params ?? this.params,
      results: results ?? this.results,
      turbine: turbine ?? this.turbine,
      curveData: curveData ?? this.curveData,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      lastRpm: lastRpm ?? this.lastRpm,
    );
  }
}

class SimulationNotifier extends Notifier<SimulationState> {
  @override
  SimulationState build() {
    state = SimulationState(
      params: SimulationParams(),
      turbine: const TurbineState(),
      curveData: [],
    );
    _recompute();
    return state;
  }

  void _recompute() {
    SimulationResults r = computeSimulation(state.params);
    List<({double windSpeed, double power, double rpm, double cp})> curves =
        computeCurves(state.params);
    state = state.copyWith(results: r, curveData: curves, lastRpm: r.rpm);
  }

  void updateParam(String key, double value) {
    SimulationParams p = state.params;
    switch (key) {
      case 'windSpeed': p.windSpeed = value; break;
      case 'rotorRadius': p.rotorRadius = value; break;
      case 'cp': p.cp = value; break;
      case 'airDensity': p.airDensity = value; break;
      case 'tsr': p.tsr = value; break;
      case 'pitchAngle': p.pitchAngle = value; break;
    }
    _recompute();
  }

  void updateTurbineType(TurbineType type) {
    state.params.turbineType = type;
    state.params.bladeCount = type.defaultBlades;
    state.params.cp = type.defaultCp;
    state.params.tsr = type.defaultTsr;
    state.params.pitchAngle = type.defaultPitch;
    _recompute();
  }

  void updateBladeCount(int count) {
    state.params.bladeCount = count;
    double suggestedTsr = SuggestionEngine.suggestedTsr(count);
    state.params.tsr = suggestedTsr;
    _recompute();
  }

  void applySuggestions() {
    state.params.cp = 0.35;
    state.params.tsr = SuggestionEngine.suggestedTsr(state.params.bladeCount);
    state.params.airDensity = 1.225;
    state.params.pitchAngle = state.params.turbineType.defaultPitch;
    _recompute();
  }

  void togglePause() {
    state = state.copyWith(turbine: state.turbine.copyWith(isPaused: !state.turbine.isPaused));
  }

  void toggleWireframe() {
    state = state.copyWith(turbine: state.turbine.copyWith(wireframe: !state.turbine.wireframe));
  }

  void toggleDarkMode() {
    state = state.copyWith(
        turbine: state.turbine.copyWith(darkMode: !state.turbine.darkMode));
  }

  void resetCamera(Camera3D cam) {
    cam.azimuth = 0.8;
    cam.elevation = 0.4;
    cam.distance = 3.0;
  }

  void updateRotation(double dt) {
    if (state.turbine.isPaused) return;
    double rpm = state.lastRpm;
    if (rpm <= 0) return;
    double radPerSec = rpm / 60 * 2 * pi;
    double delta = radPerSec * dt;
    state = state.copyWith(
      turbine: state.turbine.copyWith(
        rotationAngle: state.turbine.rotationAngle + delta,
      ),
    );
  }
}

final simulationProvider =
    NotifierProvider<SimulationNotifier, SimulationState>(SimulationNotifier.new);
