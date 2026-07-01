import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'wind_fluid.dart';

class FluidPainter {
  WindFluid? windFluid;
  bool darkMode;
  final Paint _densityPaint = Paint()..style = PaintingStyle.fill;
  final Paint _rotorPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  final Paint _streamPaint = Paint()
    ..style = PaintingStyle.stroke;

  static const int _seedsPerCol = 30;
  static const int _colStart = 2;
  static const int _numCols = 12;
  final List<double> _jitter = [];

  FluidPainter({this.windFluid, this.darkMode = true}) {
    _initJitter();
  }

  void _initJitter() {
    _jitter.clear();
    Random rng = Random(42);
    for (int i = 0; i < _seedsPerCol * _numCols; i++) {
      _jitter.add(rng.nextDouble() * 0.8 - 0.4);
    }
  }

  void paint(Canvas canvas, Size size, double cx, double cy, double radius, double time) {
    final wf = windFluid;
    if (wf == null) return;
    int N = wf.size;
    double cellW = radius * 2 / N;
    double cellH = radius * 2 / N;
    double offsetX = cx - radius;
    double offsetY = cy - radius;

    ui.Color baseColor = darkMode
        ? const ui.Color.fromARGB(255, 80, 180, 255)
        : const ui.Color.fromARGB(255, 30, 120, 220);
    ui.Color highColor = darkMode
        ? const ui.Color.fromARGB(255, 180, 230, 255)
        : const ui.Color.fromARGB(255, 120, 200, 255);

    // Density at 1/2 resolution
    for (int i = 0; i < N; i += 2) {
      for (int j = 0; j < N; j += 2) {
        double d = wf.getDensity(i, j);
        if (d < 0.012) continue;
        double val = d.clamp(0, 1);
        double a = val * 0.3;
        ui.Color c = val > 0.5
            ? ui.Color.lerp(baseColor, highColor, (val - 0.5) * 2)!.withValues(alpha: a)
            : baseColor.withValues(alpha: a * val * 2);
        _densityPaint.color = c;
        canvas.drawRect(
          Rect.fromLTWH(offsetX + i * cellW, offsetY + j * cellH, cellW * 2 + 1, cellH * 2 + 1),
          _densityPaint,
        );
      }
    }

    double maxSpeed = wf.windSpeed * 3.5;

    // RK4 streamlines from left edge
    double seedSpacing = (N - 4).toDouble() / _seedsPerCol;
    int si = 0;
    for (int col = 0; col < _numCols; col++) {
      double startX = _colStart + col * 4.0 + 1.0;
      for (int row = 0; row < _seedsPerCol; row++) {
        double startY = 2 + row * seedSpacing + _jitter[si % _jitter.length];

        List<StreamPoint> pts = wf.traceStreamline(startX, startY, maxSteps: 50, stepSize: 0.6);
        if (pts.length < 3) continue;

        Path path = Path();
        double firstX = offsetX + startX * cellW;
        double firstY = offsetY + startY * cellH;
        path.moveTo(firstX, firstY);

        double avgSpeed = 0;
        for (final p in pts) {
          path.lineTo(offsetX + p.x * cellW, offsetY + p.y * cellH);
          avgSpeed += p.speed;
        }
        avgSpeed /= pts.length;

        double speedNorm = (avgSpeed / maxSpeed).clamp(0, 1);
        double width = 0.5 + speedNorm * 2.0;
        double opacity = 0.04 + speedNorm * 0.25;

        ui.Color streamColor;
        if (speedNorm < 0.3) {
          double t = speedNorm / 0.3;
          streamColor = ui.Color.lerp(
            darkMode ? const Color(0xFF1A3A5C) : const Color(0xFF4A7B9C),
            darkMode ? const Color(0xFF40A0FF) : const Color(0xFF2080D0),
            t,
          )!.withValues(alpha: opacity);
        } else if (speedNorm < 0.6) {
          double t = (speedNorm - 0.3) / 0.3;
          streamColor = ui.Color.lerp(
            darkMode ? const Color(0xFF40A0FF) : const Color(0xFF2080D0),
            darkMode ? const Color(0xFF80D0FF) : const Color(0xFF40C0F0),
            t,
          )!.withValues(alpha: opacity);
        } else {
          double t = (speedNorm - 0.6) / 0.4;
          streamColor = ui.Color.lerp(
            darkMode ? const Color(0xFF80D0FF) : const Color(0xFF40C0F0),
            darkMode ? const Color(0xFFE0F4FF) : const Color(0xFFA0E0FF),
            t,
          )!.withValues(alpha: opacity);
        }

        _streamPaint.color = streamColor;
        _streamPaint.strokeWidth = width;
        canvas.drawPath(path, _streamPaint);

        si++;
      }
    }

    // Rotor indicator
    int cxR = wf.rotorCx.round();
    int cyR = wf.rotorCy.round();
    int rR = wf.rotorRadius.round();
    _rotorPaint.color = (darkMode ? Colors.cyan : Colors.blue).withValues(alpha: 0.15);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(offsetX + cxR * cellW, offsetY + cyR * cellH),
        width: rR * 2 * cellW,
        height: rR * 2 * cellH,
      ),
      _rotorPaint,
    );

    // Velocity arrows (sparse)
    Paint arrowPaint = Paint()
      ..color = (darkMode ? Colors.white : Colors.blueGrey).withValues(alpha: 0.03)
      ..strokeWidth = 0.3;
    for (int aj = 4; aj < N - 4; aj += 16) {
      for (int ai = 4; ai < N - 4; ai += 16) {
        double u = wf.getU(ai, aj);
        double v = wf.getV(ai, aj);
        double mag = sqrt(u * u + v * v);
        if (mag < 0.02) continue;
        double px = offsetX + ai * cellW;
        double py = offsetY + aj * cellH;
        double normU = u / mag, normV = v / mag;
        double len = (mag / maxSpeed).clamp(0, 1) * cellW * 2;
        canvas.drawLine(Offset(px, py), Offset(px + normU * len, py + normV * len), arrowPaint);
      }
    }
  }
}
