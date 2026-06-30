import 'dart:math';

enum TurbineType {
  standard('Standard HAWT', 3, 0.35, 5.0, 5),
  twoBlade('2-Blade HAWT', 2, 0.32, 6.0, 3),
  fiveBlade('5-Blade HAWT', 5, 0.38, 3.5, 8),
  darrieus('Darrieus VAWT', 2, 0.30, 4.0, 0),
  savonius('Savonius VAWT', 2, 0.18, 0.8, 0);

  final String label;
  final int defaultBlades;
  final double defaultCp;
  final double defaultTsr;
  final double defaultPitch;
  const TurbineType(this.label, this.defaultBlades, this.defaultCp, this.defaultTsr, this.defaultPitch);

  bool get isVawt => this == darrieus || this == savonius;
}

class SimulationParams {
  double windSpeed;      // m/s
  double rotorRadius;    // m
  int bladeCount;
  double cp;
  double airDensity;     // kg/m^3
  double tsr;            // tip speed ratio
  double pitchAngle;     // degrees
  TurbineType turbineType;

  SimulationParams({
    this.windSpeed = 6,
    this.rotorRadius = 0.6,
    this.bladeCount = 3,
    this.cp = 0.35,
    this.airDensity = 1.225,
    this.tsr = 5.0,
    this.pitchAngle = 5,
    this.turbineType = TurbineType.standard,
  });
}

class SimulationResults {
  final double power;      // W
  final double rpm;
  final double torque;     // N.m
  final double thrust;     // N
  final double sweptArea;  // m^2
  final double tipSpeed;   // m/s
  final double effectiveCp;
  final double pitchFactor;

  SimulationResults({
    required this.power,
    required this.rpm,
    required this.torque,
    required this.thrust,
    required this.sweptArea,
    required this.tipSpeed,
    required this.effectiveCp,
    required this.pitchFactor,
  });
}

double _pitchFactor(double pitchAngle, TurbineType type) {
  if (type.isVawt) return 1.0;
  double optimal;
  switch (type) {
    case TurbineType.standard: optimal = 5; break;
    case TurbineType.twoBlade: optimal = 3; break;
    case TurbineType.fiveBlade: optimal = 8; break;
    default: optimal = 5;
  }
  double dev = pitchAngle - optimal;
  return exp(-0.5 * (dev * dev) / (10 * 10));
}

double _aFromCp(double cp) {
  if (cp <= 0) return 0;
  if (cp >= 0.59) return 1 / 3;
  double a = 0.2;
  for (int i = 0; i < 8; i++) {
    double f = 4 * a * (1 - a) * (1 - a) - cp;
    double df = 4 * (1 - 4 * a + 3 * a * a);
    a -= f / df;
    if (a < 0) a = 0;
    if (a > 0.5) a = 0.5;
  }
  return a;
}

SimulationResults computeSimulation(SimulationParams p) {
  double pitchAdj = _pitchFactor(p.pitchAngle, p.turbineType);
  double effCp = p.cp * pitchAdj;
  double A = pi * p.rotorRadius * p.rotorRadius;
  double pWind = 0.5 * p.airDensity * A * pow(p.windSpeed, 3);
  double power = pWind * effCp;
  double rpm = (p.tsr * p.windSpeed) / (2 * pi * p.rotorRadius) * 60;
  double torque = power / max(rpm / 60 * 2 * pi, 0.001);
  double a = _aFromCp(effCp);
  double thrust = 0.5 * p.airDensity * A * p.windSpeed * p.windSpeed * 4 * a * (1 - a);
  double tipSpeed = p.tsr * p.windSpeed;

  if (p.turbineType == TurbineType.darrieus) {
    double solidity = p.bladeCount * 0.05 / p.rotorRadius;
    rpm = rpm * (1 + solidity);
    torque = power / max(rpm / 60 * 2 * pi, 0.001);
  } else if (p.turbineType == TurbineType.savonius) {
    rpm *= 0.3;
    torque = power / max(rpm / 60 * 2 * pi, 0.001);
  }

  return SimulationResults(
    power: power,
    rpm: rpm,
    torque: torque,
    thrust: thrust,
    sweptArea: A,
    tipSpeed: tipSpeed,
    effectiveCp: effCp,
    pitchFactor: pitchAdj,
  );
}

List<({double windSpeed, double power, double rpm, double cp})> computeCurves(
    SimulationParams p) {
  double pitchAdj = _pitchFactor(p.pitchAngle, p.turbineType);
  double effCp = p.cp * pitchAdj;
  List<({double windSpeed, double power, double rpm, double cp})> points = [];
  for (double v = 2; v <= 20; v += 0.5) {
    double A = pi * p.rotorRadius * p.rotorRadius;
    double pWind = 0.5 * p.airDensity * A * v * v * v;
    double power = pWind * effCp;
    double rpm = (p.tsr * v) / (2 * pi * p.rotorRadius) * 60;
    if (p.turbineType == TurbineType.darrieus) {
      double solidity = p.bladeCount * 0.05 / p.rotorRadius;
      rpm = rpm * (1 + solidity);
    } else if (p.turbineType == TurbineType.savonius) {
      rpm *= 0.3;
    }
    if (v < 2.5) { power = 0; rpm = 0; }
    points.add((windSpeed: v, power: power, rpm: rpm, cp: effCp));
  }
  return points;
}

class SuggestionEngine {
  static double suggestedCp(double tsr, int bladeCount) {
    if (tsr < 2) return 0.20;
    if (tsr < 4) return 0.25;
    if (tsr < 6) return 0.30;
    return 0.25;
  }

  static double suggestedTsr(int bladeCount) {
    switch (bladeCount) {
      case 2: return 6.0;
      case 3: return 5.5;
      case 4: return 3.5;
      case 5: return 2.5;
      case 6: return 2.0;
      default: return 4.0;
    }
  }

  static bool isWindSpeedOptimal(double v) => v >= 3 && v <= 12;
  static bool isRotorRadiusOptimal(double r) => r >= 0.3 && r <= 2.0;
  static bool isCpOptimal(double cp) => cp >= 0.2 && cp <= 0.5;
  static bool isTsrOptimal(double tsr, int blades) {
    double suggested = suggestedTsr(blades);
    return (tsr - suggested).abs() <= 1.5;
  }

  static String warningFor(String param, double value, {int? bladeCount, TurbineType? turbineType}) {
    switch (param) {
      case 'windSpeed':
        if (value < 2) return 'Increase wind speed above 2 m/s to generate power';
        if (value > 15) return 'Reduce wind speed — above 15 m/s risks structural damage';
        return '';
      case 'cp':
        if (value > 0.593) return 'Reduce Cp — the Betz limit is 0.593';
        if (value < 0.1) return 'Increase Cp — efficiency below 10%';
        return '';
      case 'tsr':
        if (bladeCount != null) {
          double s = suggestedTsr(bladeCount);
          if ((value - s).abs() > 2) return 'Set TSR to $s for optimal performance with $bladeCount blades';
        }
        if (value < 1) return 'Increase TSR above 1 for lift-based turbine operation';
        if (value > 10) return 'Reduce TSR — values above 10 cause noise and structural stress';
        return '';
      case 'pitchAngle':
        if (turbineType != null && turbineType.isVawt) return 'Pitch has no effect on VAWT designs';
        double? opt;
        switch (turbineType ?? TurbineType.standard) {
          case TurbineType.standard: opt = 5; break;
          case TurbineType.twoBlade: opt = 3; break;
          case TurbineType.fiveBlade: opt = 8; break;
          default: opt = 5;
        }
        if ((value - opt).abs() > 5) return 'Pitch deviates from optimal ($opt\u00b0) — power drops significantly beyond \u00b15\u00b0';
        return '';
      default: return '';
    }
  }
}
