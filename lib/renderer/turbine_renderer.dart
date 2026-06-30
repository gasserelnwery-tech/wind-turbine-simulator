import 'dart:math';
import 'dart:ui' show Color;
import '../core/math3d.dart';
import '../core/simulation_engine.dart' show TurbineType;

class TurbineMeshes {
  final List<TriMesh> meshes = [];
  double _bladeAngle = 0;

  void build(int bladeCount, double radius, double pitchDeg,
      {double towerHeight = 1.5, TurbineType type = TurbineType.standard}) {
    meshes.clear();
    if (type.isVawt) {
      _buildVawt(radius, bladeCount, type);
    } else {
      _buildHawt(bladeCount, radius, pitchDeg, towerHeight);
    }
  }

  void _buildHawt(int bladeCount, double radius, double pitchDeg, double towerHeight) {
    meshes.add(buildTower(towerHeight));
    meshes.add(buildNacelle());
    meshes.add(buildHub());
    for (int i = 0; i < bladeCount; i++) {
      double ang = 2 * pi * i / bladeCount + _bladeAngle;
      TriMesh blade = buildBlade(radius, pitchDeg);
      blade.rotation.y = ang;
      meshes.add(blade);
    }
  }

  void _buildVawt(double radius, int bladeCount, TurbineType type) {
    double rotorY = 0.2;
    double shaftHeight = radius * 2.4;
    TriMesh shaft = buildTower(shaftHeight);
    shaft.position = Vec3(0, rotorY - radius - 0.1, 0);
    meshes.add(shaft);
    if (type == TurbineType.darrieus) {
      meshes.add(buildDarrieus(radius, bladeCount));
    } else {
      meshes.add(buildSavonius(radius));
    }
  }

  void updateRotation(double angle) {
    _bladeAngle = angle;
  }

  void applyRotation(int bladeCount, double pitchDeg, {TurbineType type = TurbineType.standard}) {
    if (type.isVawt) {
      if (meshes.length > 1) {
        int idx = type == TurbineType.darrieus ? 1 : 1;
        if (idx < meshes.length) meshes[idx].rotation.y = _bladeAngle;
      }
      return;
    }
    int idx = 3;
    for (int i = 0; i < bladeCount && idx < meshes.length; i++) {
      meshes[idx].rotation.y = 2 * pi * i / bladeCount + _bladeAngle;
      idx++;
    }
  }

  TriMesh buildTower(double height) {
    TriMesh m = TriMesh();
    m.position = Vec3(0, -height - 0.08, 0);
    int segs = 10;
    double rBot = 0.06, rTop = 0.025;
    Color c = const Color.fromARGB(255, 150, 155, 170);
    Color cDark = const Color.fromARGB(255, 130, 135, 150);
    for (int i = 0; i < segs; i++) {
      double a0 = 2 * pi * i / segs;
      double a1 = 2 * pi * (i + 1) / segs;
      m.addQuad(
        Vec3(rBot * cos(a0), 0, rBot * sin(a0)),
        Vec3(rBot * cos(a1), 0, rBot * sin(a1)),
        Vec3(rTop * cos(a1), height, rTop * sin(a1)),
        Vec3(rTop * cos(a0), height, rTop * sin(a0)),
        i % 2 == 0 ? c : cDark,
      );
    }
    return m;
  }

  TriMesh buildNacelle() {
    TriMesh m = TriMesh();
    m.position = Vec3(0, 0, 0);
    Color c = const Color.fromARGB(255, 120, 125, 140);
    Color cDark = const Color.fromARGB(255, 100, 105, 120);
    int segs = 10;
    double len = 0.1, w = 0.045, h = 0.04;
    for (int i = 0; i < segs; i++) {
      double a0 = 2 * pi * i / segs;
      double a1 = 2 * pi * (i + 1) / segs;
      double r0x = w * cos(a0), r0z = h * sin(a0);
      double r1x = w * cos(a1), r1z = h * sin(a1);
      m.addQuad(
        Vec3(r0x, 0, r0z),
        Vec3(r1x, 0, r1z),
        Vec3(r1x, len, r1z),
        Vec3(r0x, len, r0z),
        i % 2 == 0 ? c : cDark,
      );
    }
    return m;
  }

  TriMesh buildHub() {
    TriMesh m = TriMesh();
    m.position = Vec3(0, 0.02, 0.05);
    Color cHub = const Color.fromARGB(255, 110, 115, 130);
    Color cDark = const Color.fromARGB(255, 90, 95, 110);
    int segs = 8, rings = 4;
    for (int j = 0; j < rings; j++) {
      double v0 = pi * (j + 1) / (rings + 1) - pi * 0.45;
      double v1 = pi * (j + 2) / (rings + 1) - pi * 0.45;
      double r0 = 0.035 * sin(v0 + pi * 0.45);
      double r1 = 0.035 * sin(v1 + pi * 0.45);
      for (int i = 0; i < segs; i++) {
        double u0 = 2 * pi * i / segs;
        double u1 = 2 * pi * (i + 1) / segs;
        m.addQuad(
          Vec3(r0 * cos(u0), 0.035 * cos(v0 + pi * 0.45), r0 * sin(u0)),
          Vec3(r0 * cos(u1), 0.035 * cos(v0 + pi * 0.45), r0 * sin(u1)),
          Vec3(r1 * cos(u1), 0.035 * cos(v1 + pi * 0.45), r1 * sin(u1)),
          Vec3(r1 * cos(u0), 0.035 * cos(v1 + pi * 0.45), r1 * sin(u0)),
          i % 2 == 0 ? cHub : cDark,
        );
      }
    }
    return m;
  }

  List<Vec3> nacaAirfoil(double t, double m, double p, int n, double chord) {
    List<Vec3> pts = [];
    for (int j = 0; j < n; j++) {
      double theta = 2 * pi * j / n;
      double x = 0.5 * (1 + cos(theta));
      double yt = (t / 0.2) * (0.2969 * sqrt(x) - 0.1260 * x - 0.3516 * x * x +
          0.2843 * x * x * x - 0.1015 * x * x * x * x);
      double yc = 0, dyc = 0;
      if (m > 0) {
        if (x < p) {
          yc = m / (p * p) * (2 * p * x - x * x);
          dyc = 2 * m / (p * p) * (p - x);
        } else {
          yc = m / ((1 - p) * (1 - p)) * (1 - 2 * p + 2 * p * x - x * x);
          dyc = 2 * m / ((1 - p) * (1 - p)) * (p - x);
        }
      }
      double tc = atan(dyc);
      double xs, ys;
      if (j <= n ~/ 2) {
        xs = x - yt * sin(tc);
        ys = yc + yt * cos(tc);
      } else {
        xs = x + yt * sin(tc);
        ys = yc - yt * cos(tc);
      }
      xs = (xs - 0.25) * chord;
      ys = ys * chord;
      pts.add(Vec3(xs, 0, ys));
    }
    return pts;
  }

  TriMesh buildBlade(double radius, double pitchDeg) {
    TriMesh m = TriMesh();
    m.position = Vec3(0, 0, 0);
    Color cBlade = const Color.fromARGB(255, 210, 215, 225);
    Color cDark = const Color.fromARGB(255, 170, 175, 185);
    int nSpan = 12;
    int nSec = 10;
    double pitch = pitchDeg * pi / 180;
    List<List<Vec3>> stations = [];
    for (int i = 0; i <= nSpan; i++) {
      double frac = i / nSpan;
      double rPos = 0.04 + frac * (radius - 0.04);
      double chord = 0.050 * (1 - 0.60 * frac);
      double twist = pitch + (10 * pi / 180) * (1 - frac) * (1 - frac);
      double thick = 0.15 - 0.05 * frac;
      double camber = 0.04 - 0.02 * frac;
      List<Vec3> section = nacaAirfoil(thick, camber, 0.4, nSec, chord);
      for (int j = 0; j < section.length; j++) {
        Vec3 p = section[j];
        double dx = p.x * cos(twist) - p.z * sin(twist);
        double dz = p.x * sin(twist) + p.z * cos(twist);
        section[j] = Vec3(dx, rPos, dz);
      }
      stations.add(section);
    }
    for (int i = 0; i < stations.length - 1; i++) {
      for (int j = 0; j < nSec; j++) {
        int jn = (j + 1) % nSec;
        m.addQuad(stations[i][j], stations[i][jn], stations[i + 1][jn], stations[i + 1][j],
            (j > nSec ~/ 2 && j < nSec * 3 ~/ 4) ? cDark : cBlade);
      }
    }
    return m;
  }

  TriMesh buildDarrieus(double radius, int bladeCount) {
    TriMesh m = TriMesh();
    m.position = Vec3(0, 0.2, 0);
    double height = radius * 2.0;
    int nSpan = 10;
    int nSec = 10;
    Color c = const Color.fromARGB(255, 190, 195, 210);
    Color cDark = const Color.fromARGB(255, 150, 155, 170);
    double chord = radius * 0.08;

    for (int b = 0; b < bladeCount; b++) {
      double bladeAngle = 2 * pi * b / bladeCount;
      List<List<Vec3>> stations = [];
      for (int i = 0; i <= nSpan; i++) {
        double frac = i / nSpan;
        double yPos = -height / 2 + frac * height;
        List<Vec3> section = nacaAirfoil(0.18, 0, 0, nSec, chord * (1 - 0.3 * frac));
        for (int j = 0; j < section.length; j++) {
          Vec3 p = section[j];
          double r = radius;
          double dx = r * cos(bladeAngle) + p.x * cos(bladeAngle) - p.z * sin(bladeAngle);
          double dz = r * sin(bladeAngle) + p.x * sin(bladeAngle) + p.z * cos(bladeAngle);
          section[j] = Vec3(dx, yPos, dz);
        }
        stations.add(section);
      }
      for (int i = 0; i < stations.length - 1; i++) {
        for (int j = 0; j < nSec; j++) {
          int jn = (j + 1) % nSec;
          m.addQuad(stations[i][j], stations[i][jn], stations[i + 1][jn], stations[i + 1][j],
              i % 2 == 0 ? c : cDark);
        }
        if (i == 0) {
          double frac = 0.1;
          double yTop = -height / 2 + frac * height;
          double yBot = -height / 2;
          double cx = radius * cos(bladeAngle);
          double cz = radius * sin(bladeAngle);
          m.addTri(Vec3(0, yBot, 0), Vec3(cx, yBot, cz), Vec3(cx, yTop, cz), cDark);
          m.addTri(Vec3(0, yBot, 0), Vec3(cx, yTop, cz), Vec3(0, yTop, 0), cDark);
          yBot = -height / 2 + (1 - frac) * height;
          yTop = -height / 2 + height;
          m.addTri(Vec3(0, yBot, 0), Vec3(0, yTop, 0), Vec3(cx, yTop, cz), cDark);
          m.addTri(Vec3(0, yBot, 0), Vec3(cx, yTop, cz), Vec3(cx, yBot, cz), cDark);
        }
      }
    }
    return m;
  }

  TriMesh buildSavonius(double radius) {
    TriMesh m = TriMesh();
    m.position = Vec3(0, 0.2, 0);
    double height = radius * 2.0;
    int nSegs = 10;
    int nRings = 6;
    double bucketR = radius * 0.50;
    double gap = bucketR * 2 - radius * 0.15;
    Color c1 = const Color.fromARGB(255, 180, 65, 65);
    Color c2 = const Color.fromARGB(255, 55, 115, 180);

    for (int half = 0; half < 2; half++) {
      Color col = half == 0 ? c1 : c2;
      double sign = half == 0 ? 1.0 : -1.0;
      double cx = gap / 2 * sign;
      for (int j = 0; j < nRings; j++) {
        double y0 = -height / 2 + j * height / nRings;
        double y1 = -height / 2 + (j + 1) * height / nRings;
        for (int i = 0; i < nSegs; i++) {
          double a0 = pi + sign * pi * i / nSegs;
          double a1 = pi + sign * pi * (i + 1) / nSegs;
          m.addQuad(
            Vec3(cx + bucketR * cos(a0), y0, bucketR * sin(a0)),
            Vec3(cx + bucketR * cos(a1), y0, bucketR * sin(a1)),
            Vec3(cx + bucketR * cos(a1), y1, bucketR * sin(a1)),
            Vec3(cx + bucketR * cos(a0), y1, bucketR * sin(a0)),
            col,
          );
        }
      }
    }

    Color ep = const Color.fromARGB(255, 100, 100, 110);
    int epSegs = 10;
    double epR = radius * 0.55;
    for (int side = 0; side < 2; side++) {
      double y = side == 0 ? -height / 2 : height / 2;
      for (int i = 0; i < epSegs; i++) {
        double a0 = 2 * pi * i / epSegs;
        double a1 = 2 * pi * (i + 1) / epSegs;
        m.addTri(
          Vec3(0, y, 0),
          Vec3(epR * cos(a0), y, epR * sin(a0)),
          Vec3(epR * cos(a1), y, epR * sin(a1)),
          ep,
        );
      }
    }
    return m;
  }
}
