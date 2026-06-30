import 'dart:math';
import 'dart:ui' show Color;

class Vec3 {
  double x, y, z;
  Vec3(this.x, this.y, this.z);
  Vec3.zero() : x = 0, y = 0, z = 0;
  Vec3.clone(Vec3 v) : x = v.x, y = v.y, z = v.z;

  Vec3 operator +(Vec3 v) => Vec3(x + v.x, y + v.y, z + v.z);
  Vec3 operator -(Vec3 v) => Vec3(x - v.x, y - v.y, z - v.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);
  Vec3 operator /(double s) => Vec3(x / s, y / s, z / s);
  Vec3 negate() => Vec3(-x, -y, -z);
  double dot(Vec3 v) => x * v.x + y * v.y + z * v.z;
  double length() => sqrt(x * x + y * y + z * z);
  Vec3 normalize() { double l = length(); return l > 0 ? this / l : this; }
  Vec3 cross(Vec3 v) => Vec3(y * v.z - z * v.y, z * v.x - x * v.z, x * v.y - y * v.x);
}

class Mat4 {
  final List<double> m = List.filled(16, 0);

  Mat4.identity() { m[0] = m[5] = m[10] = m[15] = 1; }

  Mat4.perspective(double fovY, double aspect, double near, double far) {
    double f = 1.0 / tan(fovY / 2);
    m[0] = f / aspect; m[5] = f;
    m[10] = (far + near) / (near - far);
    m[11] = 2 * far * near / (near - far);
    m[14] = -1;
    m[1] = m[2] = m[3] = m[4] = m[6] = m[7] = m[12] = m[13] = m[15] = 0;
  }

  Mat4.lookAt(Vec3 eye, Vec3 target, Vec3 up) {
    Vec3 f = (target - eye).normalize();
    Vec3 s = f.cross(up).normalize();
    Vec3 u = s.cross(f);
    m[0] = s.x; m[1] = s.y; m[2] = s.z; m[3] = -s.dot(eye);
    m[4] = u.x; m[5] = u.y; m[6] = u.z; m[7] = -u.dot(eye);
    m[8] = -f.x; m[9] = -f.y; m[10] = -f.z; m[11] = f.dot(eye);
    m[12] = 0; m[13] = 0; m[14] = 0; m[15] = 1;
  }

  void translate(double tx, double ty, double tz) {
    m[3] += tx;
    m[7] += ty;
    m[11] += tz;
  }

  void rotateY(double angle) {
    double c = cos(angle), s = sin(angle);
    double r0c0 = m[0], r0c1 = m[1], r0c2 = m[2], r0c3 = m[3];
    double r2c0 = m[8], r2c1 = m[9], r2c2 = m[10], r2c3 = m[11];
    m[0] = c * r0c0 - s * r2c0; m[1] = c * r0c1 - s * r2c1;
    m[2] = c * r0c2 - s * r2c2; m[3] = c * r0c3 - s * r2c3;
    m[8] = s * r0c0 + c * r2c0; m[9] = s * r0c1 + c * r2c1;
    m[10] = s * r0c2 + c * r2c2; m[11] = s * r0c3 + c * r2c3;
  }

  void rotateX(double angle) {
    double c = cos(angle), s = sin(angle);
    double r1c0 = m[4], r1c1 = m[5], r1c2 = m[6], r1c3 = m[7];
    double r2c0 = m[8], r2c1 = m[9], r2c2 = m[10], r2c3 = m[11];
    m[4] = c * r1c0 + s * r2c0; m[5] = c * r1c1 + s * r2c1;
    m[6] = c * r1c2 + s * r2c2; m[7] = c * r1c3 + s * r2c3;
    m[8] = -s * r1c0 + c * r2c0; m[9] = -s * r1c1 + c * r2c1;
    m[10] = -s * r1c2 + c * r2c2; m[11] = -s * r1c3 + c * r2c3;
  }

  Vec3 transform(Vec3 v) {
    double w = 1 / (m[12] * v.x + m[13] * v.y + m[14] * v.z + m[15]);
    return Vec3(
      (m[0] * v.x + m[1] * v.y + m[2] * v.z + m[3]) * w,
      (m[4] * v.x + m[5] * v.y + m[6] * v.z + m[7]) * w,
      (m[8] * v.x + m[9] * v.y + m[10] * v.z + m[11]) * w,
    );
  }

  Mat4 clone() {
    Mat4 r = Mat4.identity();
    for (int i = 0; i < 16; i++) r.m[i] = m[i];
    return r;
  }

  Mat4 multiply(Mat4 b) {
    Mat4 r = Mat4.identity();
    for (int i = 0; i < 4; i++)
      for (int j = 0; j < 4; j++) {
        r.m[i * 4 + j] = 0;
        for (int k = 0; k < 4; k++) r.m[i * 4 + j] += m[i * 4 + k] * b.m[k * 4 + j];
      }
    return r;
  }
}

class Triangle3 {
  final Vec3 a, b, c;
  final Color color;
  final Vec3 normal;
  Triangle3(this.a, this.b, this.c, this.color, this.normal);
}

class TriMesh {
  final List<Triangle3> triangles = [];
  Vec3 position = Vec3.zero();
  Vec3 rotation = Vec3.zero();
  double scale = 1;

  void clear() => triangles.clear();
  void addTri(Vec3 a, Vec3 b, Vec3 c, Color color) {
    Vec3 n = (b - a).cross(c - a).normalize();
    triangles.add(Triangle3(a, b, c, color, n));
  }

  void addQuad(Vec3 a, Vec3 b, Vec3 c, Vec3 d, Color color) {
    addTri(a, b, c, color);
    addTri(a, c, d, color);
  }

  Mat4 getTransform() {
    Mat4 t = Mat4.identity();
    t.translate(position.x, position.y, position.z);
    t.rotateX(rotation.x);
    t.rotateY(rotation.y);
    // rotation.z is around Z — not commonly needed
    return t;
  }
}
