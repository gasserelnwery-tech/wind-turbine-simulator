import 'dart:math';
import 'dart:typed_data';
import 'fluid_solver.dart';
import '../core/simulation_engine.dart' show TurbineType;

class WindFluid {
  static const int gridSize = 80;
  final FluidSolver solver;
  double windSpeed = 6;
  double _time = 0;
  final Float64List obstacleMask;
  double rotorCx = gridSize / 2;
  double rotorCy = gridSize / 2;
  double rotorRadius = gridSize * 0.10;

  WindFluid()
      : solver = FluidSolver(size: gridSize, dt: 0.08, diffusion: 0.0, viscosity: 0.0),
        obstacleMask = Float64List(gridSize * gridSize);

  int get size => gridSize;
  int idx(int x, int y) => x + y * size;

  void init(double speed) {
    windSpeed = speed;
    solver.reset();
    obstacleMask.fillRange(0, obstacleMask.length, 0);
    _time = 0;
    rotorCx = gridSize / 2;
    rotorCy = gridSize / 2;
    rotorRadius = gridSize * 0.10;

    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        int ix = (rotorCx + i).round().clamp(1, size - 2);
        int iy = (rotorCy + j).round().clamp(1, size - 2);
        obstacleMask[idx(ix, iy)] = 1;
      }
    }
  }

  void update(double dt,
      {double rotationAngle = 0,
      double cp = 0.35,
      int bladeCount = 3,
      TurbineType turbineType = TurbineType.standard}) {
    _time += dt;
    int N = size;
    double t = _time;

    // Source injection
    double windSrc = windSpeed * 3;
    for (int j = 1; j < N - 1; j++) {
      solver.u[idx(1, j)] = windSrc;
      solver.density[idx(1, j)] = (j % 5 == 1) ? 1.2 : 1.0;
      if (j % 7 == 3) solver.density[idx(2, j)] += 0.6;
    }

    // Turbulence
    double turbStrength = 0.3 + windSpeed * 0.05;
    for (int j = 2; j < N - 2; j += 2) {
      solver.v[idx(1, j)] += sin(t * 2.0 + j * 0.3) * turbStrength;
      solver.v[idx(1, j)] += cos(t * 1.7 + j * 0.5) * turbStrength * 0.5;
    }

    int cx = rotorCx.round();
    int cy = rotorCy.round();
    int r = rotorRadius.round();
    double rSq = (r * r).toDouble();
    bool isVawt = turbineType.isVawt;
    double extractionStrength = cp * 0.8;

    // VAWT hub deceleration
    if (isVawt) {
      int halfH = r ~/ 2;
      for (int j = cy - halfH; j <= cy + halfH; j++) {
        for (int i = cx - 2; i <= cx + 2; i++) {
          if (i < 1 || i >= N - 1 || j < 1 || j >= N - 1) continue;
          solver.u[idx(i, j)] *= 0.6;
          solver.v[idx(i, j)] += sin(t * 3.0 + j * 0.2) * 0.05;
        }
      }
      extractionStrength *= 0.7;
    }

    // Rotor extraction
    double bladePassFreq = bladeCount.toDouble();
    for (int i = cx - r; i <= cx + r; i++) {
      for (int j = cy - r; j <= cy + r; j++) {
        if (i < 1 || i >= N - 1 || j < 1 || j >= N - 1) continue;
        double dx = (i - cx).toDouble();
        double dy = (j - cy).toDouble();
        double distSq = dx * dx + dy * dy;
        if (distSq > rSq || distSq < 1) continue;
        double dist = sqrt(distSq);
        double weight = 1.0 - (dist / r) * (dist / r);
        double factor = weight * extractionStrength;

        int ij = idx(i, j);
        if (solver.u[ij] > 0) {
          solver.u[ij] *= (1.0 - factor);
        }

        double bladePhase = rotationAngle + atan2(dy, dx);
        double bladeMod = 1.0 + 0.3 * sin(bladePhase * bladePassFreq);
        solver.v[ij] += sin(t * 4.0 + dx * 0.5 + dy * 0.3) * 0.06 * bladeMod;
        solver.u[ij] *= (1.0 - factor * 0.15 * sin(bladePhase * bladePassFreq + t * 2.0) * bladeMod);
      }
    }

    // Wake + density decay combined loop
    double wakeWidth = isVawt ? r + 5 : r + 2;
    double wakeStrength = isVawt ? 0.35 : 0.25;

    for (int i = cx + 2; i < N - 2; i++) {
      for (int j = 1; j < N - 1; j++) {
        int ij = idx(i, j);
        double dy = (j - cy).toDouble();

        // Density decay
        solver.density[ij] *= (j > cy - r - 2 && j < cy + r + 2) ? 0.990 : 0.998;

        // Wake
        if (dy.abs() > wakeWidth) continue;
        double wakeAge = (i - cx) / (N - cx);
        if (dy.abs() > r - 2) {
          double shear = (1.0 - wakeAge).clamp(0, 1) * 0.25;
          solver.v[ij] += sin(t * 3.0 + i * 0.5 + dy * 0.2) * shear;
        } else {
          double decay = 1.0 - (1.0 - wakeAge) * wakeStrength * cp;
          solver.u[ij] *= decay;
          double wakeTurb = 0.12 * (1.0 - wakeAge).clamp(0, 1) * (1 + cp);
          solver.v[ij] += sin(t * 2.5 + i * 0.3 + dy * 0.4) * wakeTurb;
        }
      }
    }

    solver.step();

    // Post-step obstacle clamp
    for (int i = 1; i < N - 1; i++) {
      for (int j = 1; j < N - 1; j++) {
        int ij = idx(i, j);
        if (obstacleMask[ij] > 0.5) {
          solver.u[ij] = 0;
          solver.v[ij] = 0;
          solver.density[ij] = 0;
        }
      }
    }
  }

  double getVelocity(int x, int y) => sqrt(solver.u[idx(x, y)] * solver.u[idx(x, y)] + solver.v[idx(x, y)] * solver.v[idx(x, y)]);
  double getDensity(int x, int y) => solver.density[idx(x, y)];
  bool isObstacle(int x, int y) => obstacleMask[idx(x, y)] > 0.5;
  double getU(int x, int y) => solver.u[idx(x, y)];
  double getV(int x, int y) => solver.v[idx(x, y)];
}
