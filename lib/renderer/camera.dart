import 'dart:math';
import 'dart:ui' as ui;
import '../core/math3d.dart';

class Camera3D {
  double azimuth = 0.8;
  double elevation = 0.4;
  double distance = 3.0;
  Vec3 target = Vec3.zero();

  final double _fov = 0.8;
  final double _near = 0.1;
  final double _far = 20.0;

  void orbit(double da, double de) {
    azimuth = (azimuth + da) % (2 * pi);
    elevation = (elevation + de).clamp(0.1, pi / 2 - 0.1);
  }

  void zoom(double delta) {
    distance = (distance + delta).clamp(0.5, 10);
  }

  Vec3 getEye() {
    return Vec3(
      target.x + distance * cos(elevation) * sin(azimuth),
      target.y + distance * sin(elevation),
      target.z + distance * cos(elevation) * cos(azimuth),
    );
  }

  Mat4 getViewProjection(double aspect) {
    Mat4 proj = Mat4.perspective(_fov, aspect, _near, _far);
    Vec3 eye = getEye();
    Vec3 up = Vec3(0, 1, 0);
    Mat4 view = Mat4.lookAt(eye, target, up);
    return proj.multiply(view);
  }
}

class Renderer3D {
  final Camera3D camera;
  final List<TriMesh> meshes;
  bool wireframe = false;

  Renderer3D({Camera3D? camera, List<TriMesh>? meshes, this.wireframe = false})
      : camera = camera ?? Camera3D(),
        meshes = meshes ?? [];

  void render(ui.Canvas canvas, ui.Size size, double dt) {
    double aspect = size.width / size.height;
    Mat4 vp = camera.getViewProjection(aspect);

    canvas.save();
    double halfW = size.width / 2;
    double halfH = size.height / 2;
    canvas.translate(halfW, halfH);

    List<_TriData> visible = [];
    int estTris = 0;
    for (var mesh in meshes) {
      estTris += mesh.triangles.length;
    }
    if (estTris > 0) visible = List<_TriData>.filled(estTris, _TriData.zero());
    int vi = 0;

    for (var mesh in meshes) {
      Mat4 model = mesh.getTransform();
      double m00 = model.m[0], m01 = model.m[1], m02 = model.m[2], m03 = model.m[3];
      double m40 = model.m[4], m41 = model.m[5], m42 = model.m[6], m43 = model.m[7];
      double m80 = model.m[8], m81 = model.m[9], m82 = model.m[10], m83 = model.m[11];
      double m120 = model.m[12], m121 = model.m[13], m122 = model.m[14], m123 = model.m[15];

      // Pre-multiply vp * model into mvp
      final mvp = [
        vp.m[0]*m00 + vp.m[1]*m40 + vp.m[2]*m80 + vp.m[3]*m120,
        vp.m[0]*m01 + vp.m[1]*m41 + vp.m[2]*m81 + vp.m[3]*m121,
        vp.m[0]*m02 + vp.m[1]*m42 + vp.m[2]*m82 + vp.m[3]*m122,
        vp.m[0]*m03 + vp.m[1]*m43 + vp.m[2]*m83 + vp.m[3]*m123,
        vp.m[4]*m00 + vp.m[5]*m40 + vp.m[6]*m80 + vp.m[7]*m120,
        vp.m[4]*m01 + vp.m[5]*m41 + vp.m[6]*m81 + vp.m[7]*m121,
        vp.m[4]*m02 + vp.m[5]*m42 + vp.m[6]*m82 + vp.m[7]*m122,
        vp.m[4]*m03 + vp.m[5]*m43 + vp.m[6]*m83 + vp.m[7]*m123,
        vp.m[8]*m00 + vp.m[9]*m40 + vp.m[10]*m80 + vp.m[11]*m120,
        vp.m[8]*m01 + vp.m[9]*m41 + vp.m[10]*m81 + vp.m[11]*m121,
        vp.m[8]*m02 + vp.m[9]*m42 + vp.m[10]*m82 + vp.m[11]*m122,
        vp.m[8]*m03 + vp.m[9]*m43 + vp.m[10]*m83 + vp.m[11]*m123,
        vp.m[12]*m00 + vp.m[13]*m40 + vp.m[14]*m80 + vp.m[15]*m120,
        vp.m[12]*m01 + vp.m[13]*m41 + vp.m[14]*m81 + vp.m[15]*m121,
        vp.m[12]*m02 + vp.m[13]*m42 + vp.m[14]*m82 + vp.m[15]*m122,
        vp.m[12]*m03 + vp.m[13]*m43 + vp.m[14]*m83 + vp.m[15]*m123,
      ];

      for (var tri in mesh.triangles) {
        double ax = tri.a.x, ay = tri.a.y, az = tri.a.z;
        double aw = 1 / (mvp[12] * ax + mvp[13] * ay + mvp[14] * az + mvp[15]);
        double saX = (mvp[0] * ax + mvp[1] * ay + mvp[2] * az + mvp[3]) * aw;
        double saY = (mvp[4] * ax + mvp[5] * ay + mvp[6] * az + mvp[7]) * aw;
        double saZ = (mvp[8] * ax + mvp[9] * ay + mvp[10] * az + mvp[11]) * aw;

        double bx = tri.b.x, by = tri.b.y, bz = tri.b.z;
        double bw = 1 / (mvp[12] * bx + mvp[13] * by + mvp[14] * bz + mvp[15]);
        double sbX = (mvp[0] * bx + mvp[1] * by + mvp[2] * bz + mvp[3]) * bw;
        double sbY = (mvp[4] * bx + mvp[5] * by + mvp[6] * bz + mvp[7]) * bw;
        double sbZ = (mvp[8] * bx + mvp[9] * by + mvp[10] * bz + mvp[11]) * bw;

        double cx2 = tri.c.x, cy2 = tri.c.y, cz = tri.c.z;
        double cw = 1 / (mvp[12] * cx2 + mvp[13] * cy2 + mvp[14] * cz + mvp[15]);
        double scX = (mvp[0] * cx2 + mvp[1] * cy2 + mvp[2] * cz + mvp[3]) * cw;
        double scY = (mvp[4] * cx2 + mvp[5] * cy2 + mvp[6] * cz + mvp[7]) * cw;
        double scZ = (mvp[8] * cx2 + mvp[9] * cy2 + mvp[10] * cz + mvp[11]) * cw;

        if (saZ > 1 || sbZ > 1 || scZ > 1) continue;

        double avgZ = (saZ + sbZ + scZ) / 3;
        visible[vi++] = _TriData(
          saX * halfW, saY * halfH,
          sbX * halfW, sbY * halfH,
          scX * halfW, scY * halfH,
          tri.color, avgZ,
        );
      }
    }

    if (vi < visible.length) visible = visible.sublist(0, vi);
    if (visible.isEmpty) { canvas.restore(); return; }
    visible.sort((a, b) => a.avgZ.compareTo(b.avgZ));

    bool isWire = wireframe;
    for (var t in visible) {
      if (isWire) {
        ui.Paint p = ui.Paint()..color = ui.Color(t.color)..style = ui.PaintingStyle.stroke..strokeWidth = 1;
        canvas.drawPath(ui.Path()..moveTo(t.aX, -t.aY)..lineTo(t.bX, -t.bY)..lineTo(t.cX, -t.cY)..close(), p);
      } else {
        canvas.drawPath(ui.Path()..moveTo(t.aX, -t.aY)..lineTo(t.bX, -t.bY)..lineTo(t.cX, -t.cY)..close(), ui.Paint()..color = ui.Color(t.color));
      }
    }

    canvas.restore();
  }
}

class _TriData {
  final double aX, aY, bX, bY, cX, cY;
  final int color;
  final double avgZ;

  _TriData(this.aX, this.aY, this.bX, this.bY, this.cX, this.cY, ui.Color color, this.avgZ)
      : color = color.toARGB32();

  _TriData.zero()
      : aX = 0, aY = 0, bX = 0, bY = 0, cX = 0, cY = 0, color = 0, avgZ = 0;
}
