import 'dart:typed_data';

class FluidSolver {
  final int size;
  final double dt;
  final double diffusion;
  final double viscosity;

  final Float64List u;
  final Float64List v;
  final Float64List uPrev;
  final Float64List vPrev;
  final Float64List density;
  final Float64List densityPrev;

  FluidSolver({
    required this.size,
    this.dt = 0.1,
    this.diffusion = 0.0,
    this.viscosity = 0.0,
  })  : u = Float64List(size * size),
        v = Float64List(size * size),
        uPrev = Float64List(size * size),
        vPrev = Float64List(size * size),
        density = Float64List(size * size),
        densityPrev = Float64List(size * size);

  int idx(int x, int y) => x + y * size;

  void step() {
    int N = size;

    diffuse(1, uPrev, u, viscosity, N);
    diffuse(2, vPrev, v, viscosity, N);
    project(uPrev, vPrev, u, v, N);
    advect(1, u, uPrev, uPrev, vPrev, N);
    advect(2, v, vPrev, uPrev, vPrev, N);
    project(u, v, uPrev, vPrev, N);

    diffuse(0, densityPrev, density, diffusion, N);
    advect(0, density, densityPrev, u, v, N);
  }

  void addVelocity(int x, int y, double ux, double uy, int N) {
    int i = idx(x, y);
    u[i] += ux;
    v[i] += uy;
  }

  void addDensity(int x, int y, double amount, int N) {
    density[idx(x, y)] += amount;
  }

  void diffuse(int b, Float64List x, Float64List x0, double diff, int N) {
    double a = dt * diff * N * N;
    double denom = 1 + 4 * a;
    int iter = diff == 0 ? 3 : 6;
    for (int k = 0; k < iter; k++) {
      for (int i = 1; i < N - 1; i++) {
        for (int j = 1; j < N - 1; j++) {
          int ij = idx(i, j);
          x[ij] = (x0[ij] + a * (x[idx(i - 1, j)] + x[idx(i + 1, j)] + x[idx(i, j - 1)] + x[idx(i, j + 1)])) / denom;
        }
      }
      setBoundary(b, x, N);
    }
  }

  void advect(int b, Float64List d, Float64List d0, Float64List u, Float64List v, int N) {
    double dt0 = dt * N;
    for (int i = 1; i < N - 1; i++) {
      for (int j = 1; j < N - 1; j++) {
        int ij = idx(i, j);
        double x = i - dt0 * u[ij];
        double y = j - dt0 * v[ij];
        if (x < 0.5) x = 0.5;
        if (x > N - 1.5) x = N - 1.5;
        if (y < 0.5) y = 0.5;
        if (y > N - 1.5) y = N - 1.5;
        int ix = x.floor();
        int iy = y.floor();
        double sx = x - ix;
        double sy = y - iy;
        double d00 = d0[idx(ix, iy)];
        double d01 = d0[idx(ix, iy + 1)];
        double d10 = d0[idx(ix + 1, iy)];
        double d11 = d0[idx(ix + 1, iy + 1)];
        d[ij] = (1 - sx) * ((1 - sy) * d00 + sy * d01) + sx * ((1 - sy) * d10 + sy * d11);
      }
    }
    setBoundary(b, d, N);
  }

  void project(Float64List u, Float64List v, Float64List p, Float64List div, int N) {
    double scale = -0.5 / N;
    for (int i = 1; i < N - 1; i++) {
      for (int j = 1; j < N - 1; j++) {
        int ij = idx(i, j);
        div[ij] = scale * (u[idx(i + 1, j)] - u[idx(i - 1, j)] + v[idx(i, j + 1)] - v[idx(i, j - 1)]);
        p[ij] = 0;
      }
    }
    setBoundary(0, div, N);
    setBoundary(0, p, N);
    for (int k = 0; k < 6; k++) {
      for (int i = 1; i < N - 1; i++) {
        for (int j = 1; j < N - 1; j++) {
          int ij = idx(i, j);
          p[ij] = (div[ij] + p[idx(i - 1, j)] + p[idx(i + 1, j)] + p[idx(i, j - 1)] + p[idx(i, j + 1)]) * 0.25;
        }
      }
      setBoundary(0, p, N);
    }
    double scale2 = 0.5 * N;
    for (int i = 1; i < N - 1; i++) {
      for (int j = 1; j < N - 1; j++) {
        int ij = idx(i, j);
        u[ij] -= scale2 * (p[idx(i + 1, j)] - p[idx(i - 1, j)]);
        v[ij] -= scale2 * (p[idx(i, j + 1)] - p[idx(i, j - 1)]);
      }
    }
    setBoundary(1, u, N);
    setBoundary(2, v, N);
  }

  void setBoundary(int b, Float64List x, int N) {
    for (int i = 1; i < N - 1; i++) {
      x[idx(0, i)] = (b == 1) ? -x[idx(1, i)] : x[idx(1, i)];
      x[idx(N - 1, i)] = (b == 1) ? -x[idx(N - 2, i)] : x[idx(N - 2, i)];
      x[idx(i, 0)] = (b == 2) ? -x[idx(i, 1)] : x[idx(i, 1)];
      x[idx(i, N - 1)] = (b == 2) ? -x[idx(i, N - 2)] : x[idx(i, N - 2)];
    }
    x[idx(0, 0)] = 0.5 * (x[idx(1, 0)] + x[idx(0, 1)]);
    x[idx(0, N - 1)] = 0.5 * (x[idx(1, N - 1)] + x[idx(0, N - 2)]);
    x[idx(N - 1, 0)] = 0.5 * (x[idx(N - 2, 0)] + x[idx(N - 1, 1)]);
    x[idx(N - 1, N - 1)] = 0.5 * (x[idx(N - 2, N - 1)] + x[idx(N - 1, N - 2)]);
  }

  void reset() {
    u.fillRange(0, u.length, 0);
    v.fillRange(0, v.length, 0);
    uPrev.fillRange(0, uPrev.length, 0);
    vPrev.fillRange(0, vPrev.length, 0);
    density.fillRange(0, density.length, 0);
    densityPrev.fillRange(0, densityPrev.length, 0);
  }
}
