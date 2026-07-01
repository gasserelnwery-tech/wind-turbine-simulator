import 'dart:math';
import 'dart:typed_data';
import 'fluid_solver.dart';
import '../core/simulation_engine.dart' show TurbineType;

class StreamPoint {
  final double x, y, speed;
  const StreamPoint(this.x, this.y, this.speed);
}

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

  /// Bilinear interpolation of velocity at fractional grid coordinates
  (double, double) sampleVelocity(double fx, double fy) {
    int N = size;
    double x = fx.clamp(0.5, N - 1.5);
    double y = fy.clamp(0.5, N - 1.5);
    int ix = x.floor();
    int iy = y.floor();
    double sx = x - ix;
    double sy = y - iy;

    double u00 = solver.u[idx(ix, iy)];
    double u01 = solver.u[idx(ix, iy + 1)];
    double u10 = solver.u[idx(ix + 1, iy)];
    double u11 = solver.u[idx(ix + 1, iy + 1)];
    double u = (1 - sx) * ((1 - sy) * u00 + sy * u01) + sx * ((1 - sy) * u10 + sy * u11);

    double v00 = solver.v[idx(ix, iy)];
    double v01 = solver.v[idx(ix, iy + 1)];
    double v10 = solver.v[idx(ix + 1, iy)];
    double v11 = solver.v[idx(ix + 1, iy + 1)];
    double v = (1 - sx) * ((1 - sy) * v00 + sy * v01) + sx * ((1 - sy) * v10 + sy * v11);

    return (u, v);
  }

  /// RK4 integration along streamline, returns list of points from start
  List<StreamPoint> traceStreamline(double x0, double y0,
      {int maxSteps = 60, double stepSize = 0.6}) {
    List<StreamPoint> pts = [];
    double cx = x0, cy = y0;
    int N = size;
    for (int i = 0; i < maxSteps; i++) {
      if (cx < 0.5 || cx >= N - 1.5 || cy < 0.5 || cy >= N - 1.5) break;
      int ix = cx.round().clamp(0, N - 1);
      int iy = cy.round().clamp(0, N - 1);
      if (obstacleMask[idx(ix, iy)] > 0.5) break;

      double normalise(double u, double v) {
        double m = sqrt(u * u + v * v);
        return m < 0.001 ? 0.0 : m;
      }

      var (k1u, k1v) = sampleVelocity(cx, cy);
      double m1 = normalise(k1u, k1v);
      if (m1 == 0) break;
      k1u /= m1; k1v /= m1;

      var (k2u, k2v) = sampleVelocity(cx + 0.5 * stepSize * k1u, cy + 0.5 * stepSize * k1v);
      double m2 = normalise(k2u, k2v);
      if (m2 == 0) break;
      k2u /= m2; k2v /= m2;

      var (k3u, k3v) = sampleVelocity(cx + 0.5 * stepSize * k2u, cy + 0.5 * stepSize * k2v);
      double m3 = normalise(k3u, k3v);
      if (m3 == 0) break;
      k3u /= m3; k3v /= m3;

      var (k4u, k4v) = sampleVelocity(cx + stepSize * k3u, cy + stepSize * k3v);
      double m4 = normalise(k4u, k4v);
      if (m4 == 0) break;
      k4u /= m4; k4v /= m4;

      double du = (k1u + 2 * k2u + 2 * k3u + k4u) / 6;
      double dv = (k1v + 2 * k2v + 2 * k3v + k4v) / 6;
      double dm = sqrt(du * du + dv * dv);
      if (dm < 0.001) break;

      cx += stepSize * du;
      cy += stepSize * dv;

      // Sample actual speed at new position for coloring
      var (su, sv) = sampleVelocity(cx, cy);
      pts.add(StreamPoint(cx, cy, sqrt(su * su + sv * sv)));
    }
    return pts;
  }

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
