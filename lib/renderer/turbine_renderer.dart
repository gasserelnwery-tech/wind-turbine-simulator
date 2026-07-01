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
    meshes.add(buildSpinner());
    for (int i = 0; i < bladeCount; i++) {
      double ang = 2 * pi * i / bladeCount + _bladeAngle;
      TriMesh blade = buildBlade(radius, pitchDeg);
      blade.rotation.y = ang;
      meshes.add(blade);
    }
  }

  void _buildVawt(double radius, int bladeCount, TurbineType type) {
    double rotorY = 0.3;
    double shaftHeight = radius * 2.0;
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
        int idx = 1;
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

  static const Color _turbineWhite = Color.fromARGB(255, 245, 246, 248);
  static const Color _turbineShade = Color.fromARGB(255, 225, 228, 232);
  static const Color _turbineDark = Color.fromARGB(255, 190, 194, 200);
  static const Color _steelLight = Color.fromARGB(255, 220, 223, 228);
  static const Color _steelDark = Color.fromARGB(255, 175, 180, 190);

  TriMesh buildTower(double height) {
    TriMesh m = TriMesh();
    m.position = Vec3(0, -height - 0.08, 0);
    int segs = 16;
    double rBot = 0.08, rTop = 0.022;
    for (int i = 0; i < segs; i++) {
      double a0 = 2 * pi * i / segs;
      double a1 = 2 * pi * (i + 1) / segs;
      Color c = (i + 1) % 2 == 0 ? _steelLight : _steelDark;
      m.addQuad(
        Vec3(rBot * cos(a0), 0, rBot * sin(a0)),
        Vec3(rBot * cos(a1), 0, rBot * sin(a1)),
        Vec3(rTop * cos(a1), height, rTop * sin(a1)),
        Vec3(rTop * cos(a0), height, rTop * sin(a0)),
        c,
      );
    }
    return m;
  }

  TriMesh buildNacelle() {
    TriMesh m = TriMesh();
    double w = 0.055, h = 0.050, len = 0.13;
    int segs = 16;

    for (int i = 0; i < segs; i++) {
      double a0 = 2 * pi * i / segs;
      double a1 = 2 * pi * (i + 1) / segs;
      double rx0 = w * cos(a0), rz0 = h * sin(a0);
      double rx1 = w * cos(a1), rz1 = h * sin(a1);
      Color c = (i % 2 == 0) ? _turbineWhite : _turbineShade;
      m.addQuad(Vec3(rx0, 0, rz0), Vec3(rx1, 0, rz1),
                Vec3(rx1, len, rz1), Vec3(rx0, len, rz0), c);
    }

    // Nose cone
    Color noseColor = _turbineShade;
    for (int i = 0; i < segs; i++) {
      double a0 = 2 * pi * i / segs;
      double a1 = 2 * pi * (i + 1) / segs;
      double rx0 = w * cos(a0), rz0 = h * sin(a0);
      double rx1 = w * cos(a1), rz1 = h * sin(a1);
      m.addTri(Vec3(0, len + 0.03, 0), Vec3(rx1 * 0.5, len, rz1 * 0.5),
               Vec3(rx0 * 0.5, len, rz0 * 0.5), _turbineWhite);
      m.addQuad(Vec3(rx0 * 0.5, len, rz0 * 0.5), Vec3(rx1 * 0.5, len, rz1 * 0.5),
                Vec3(rx1, len, rz1), Vec3(rx0, len, rz0), noseColor);
    }

    // Rear cap
    Color rearColor = _turbineDark;
    for (int i = 0; i < segs; i++) {
      double a0 = 2 * pi * i / segs;
      double a1 = 2 * pi * (i + 1) / segs;
      double rx0 = w * cos(a0), rz0 = h * sin(a0);
      double rx1 = w * cos(a1), rz1 = h * sin(a1);
      m.addTri(Vec3(0, -0.005, 0), Vec3(rx0, 0, rz0), Vec3(rx1, 0, rz1), rearColor);
    }
    return m;
  }

  TriMesh buildSpinner() {
    TriMesh m = TriMesh();
    double baseR = 0.04, length = 0.07;
    int segs = 12, rings = 5;
    for (int j = 0; j < rings; j++) {
      double frac0 = j / rings;
      double frac1 = (j + 1) / rings;
      double r0 = baseR * (1 - frac0);
      double r1 = baseR * (1 - frac1);
      double z0 = frac0 * length;
      double z1 = frac1 * length;
      for (int i = 0; i < segs; i++) {
        double a0 = 2 * pi * i / segs;
        double a1 = 2 * pi * (i + 1) / segs;
        Color c = (j + i) % 2 == 0 ? _turbineWhite : _turbineShade;
        m.addQuad(
          Vec3(r0 * cos(a0), z0, r0 * sin(a0)),
          Vec3(r0 * cos(a1), z0, r0 * sin(a1)),
          Vec3(r1 * cos(a1), z1, r1 * sin(a1)),
          Vec3(r1 * cos(a0), z1, r1 * sin(a0)),
          c,
        );
      }
    }
    m.position = Vec3(0, 0.02, 0.065);
    return m;
  }

  // Generate a realistic blade cross-section: flat pressure side, curved suction side
  List<Vec3> bladeSection(double chord, double thickness, int n) {
    List<Vec3> pts = [];
    for (int j = 0; j < n; j++) {
      double theta = 2 * pi * j / n;
      double x = 0.5 * (1 + cos(theta));
      double yt = thickness * 2.5 * (0.2969 * sqrt(x) - 0.1260 * x - 0.3516 * x * x
          + 0.2843 * x * x * x - 0.1015 * x * x * x * x);
      // Use ys for the upper surface only (j <= n/2), flat bottom for lower
      double ys, xs;
      if (j <= n ~/ 2) {
        xs = x;
        ys = yt;
      } else {
        // Flat pressure side
        xs = x;
        ys = -yt * 0.15;
      }
      xs = (xs - 0.25) * chord;
      ys = ys * chord;
      pts.add(Vec3(xs, 0, ys));
    }
    return pts;
  }

  TriMesh buildBlade(double radius, double pitchDeg) {
    TriMesh m = TriMesh();
    int nSpan = 18;
    int nSec = 14;
    double pitch = pitchDeg * pi / 180;
    List<List<Vec3>> stations = [];

    for (int i = 0; i <= nSpan; i++) {
      double frac = i / nSpan;
      double rPos = 0.03 + frac * (radius - 0.03);
      double chord = 0.060 * (1 - 0.65 * frac);
      double twist = pitch + (12 * pi / 180) * (1 - frac) * (1 - frac);
      double thickness = 0.12 - 0.06 * frac;

      List<Vec3> section = bladeSection(chord, thickness, nSec);
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
        double spanFrac = i / (stations.length - 2);
        bool isLeading = j > nSec * 3 ~/ 4 || j <= nSec ~/ 4;
        bool isTip = spanFrac > 0.7;
        Color col;
        if (isLeading && isTip) {
          col = _turbineDark;
        } else if (isLeading) {
          col = _turbineShade;
        } else if (isTip) {
          col = _turbineWhite;
        } else {
          col = (j % 3 == 0) ? _turbineWhite : _turbineShade;
        }
        m.addQuad(stations[i][j], stations[i][jn],
                  stations[i + 1][jn], stations[i + 1][j], col);
      }
    }
    return m;
  }

  TriMesh buildDarrieus(double radius, int bladeCount) {
    TriMesh m = TriMesh();
    m.position = Vec3(0, 0.3, 0);
    double height = radius * 1.8;
    int nSpan = 16;
    int nSec = 12;
    double chord = radius * 0.07;

    for (int b = 0; b < bladeCount; b++) {
      double bladeAngle = 2 * pi * b / bladeCount;
      List<List<Vec3>> stations = [];
      for (int i = 0; i <= nSpan; i++) {
        double frac = i / nSpan;
        double yPos = -height / 2 + frac * height;
        List<Vec3> section = bladeSection(chord * (1 - 0.25 * frac), 0.08, nSec);
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
          Color col = (i + b) % 2 == 0 ? _turbineWhite : _turbineShade;
          m.addQuad(stations[i][j], stations[i][jn],
                    stations[i + 1][jn], stations[i + 1][j], col);
        }
        if (i == 0) {
          double frac2 = 0.08;
          double yTop = -height / 2 + frac2 * height;
          double yBot = -height / 2;
          double cx = radius * cos(bladeAngle);
          double cz = radius * sin(bladeAngle);
          m.addTri(Vec3(0, yBot, 0), Vec3(cx, yBot, cz), Vec3(cx, yTop, cz), _turbineDark);
          m.addTri(Vec3(0, yBot, 0), Vec3(cx, yTop, cz), Vec3(0, yTop, 0), _turbineDark);
          yBot = -height / 2 + (1 - frac2) * height;
          yTop = -height / 2 + height;
          m.addTri(Vec3(0, yBot, 0), Vec3(0, yTop, 0), Vec3(cx, yTop, cz), _turbineDark);
          m.addTri(Vec3(0, yBot, 0), Vec3(cx, yTop, cz), Vec3(cx, yBot, cz), _turbineDark);
        }
      }
    }
    return m;
  }

  TriMesh buildSavonius(double radius) {
    TriMesh m = TriMesh();
    m.position = Vec3(0, 0.3, 0);
    double height = radius * 1.8;
    int nSegs = 16;
    int nRings = 8;
    double bucketR = radius * 0.48;
    double gap = bucketR * 2 - radius * 0.15;
    Color red = const Color.fromARGB(255, 200, 70, 70);
    Color blue = const Color.fromARGB(255, 50, 120, 200);

    for (int half = 0; half < 2; half++) {
      Color col = half == 0 ? red : blue;
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

    Color ep = const Color.fromARGB(255, 100, 105, 115);
    int epSegs = 12;
    double epR = radius * 0.52;
    for (int side = 0; side < 2; side++) {
      double y = side == 0 ? -height / 2 : height / 2;
      for (int i = 0; i < epSegs; i++) {
        double a0 = 2 * pi * i / epSegs;
        double a1 = 2 * pi * (i + 1) / epSegs;
        m.addTri(Vec3(0, y, 0), Vec3(epR * cos(a0), y, epR * sin(a0)),
                 Vec3(epR * cos(a1), y, epR * sin(a1)), ep);
      }
    }
    return m;
  }
}
