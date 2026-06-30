import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'wind_fluid.dart';

class FluidPainter {
  WindFluid? windFluid;
  bool darkMode;
  final Paint _densityPaint = Paint()..style = PaintingStyle.fill;
  final Paint _streamPaint = Paint()
    ..style = PaintingStyle.stroke;
  final Paint _rotorPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  FluidPainter({this.windFluid, this.darkMode = true});

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

    // Density at 1/2 resolution (40x40 instead of 80x80 cells)
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

    // Streamlines (reduced seeds)
    _streamPaint.color = (darkMode ? Colors.white : Colors.blueGrey).withValues(alpha: 0.08);
    _streamPaint.strokeWidth = 0.5;

    for (double sj = 3; sj < N - 3; sj += 6) {
      for (double si = 3; si < N - 4; si += 10) {
        int ix = si.round().clamp(1, N - 2);
        int iy = sj.round().clamp(1, N - 2);

        Path path = Path();
        path.moveTo(offsetX + ix * cellW, offsetY + iy * cellH);
        double cx2 = ix.toDouble(), cy2 = iy.toDouble();
        for (int s = 0; s < 20; s++) {
          int ux = cx2.round().clamp(1, N - 2);
          int uy = cy2.round().clamp(1, N - 2);
          double u = wf.getU(ux, uy);
          double v = wf.getV(ux, uy);
          double mag = sqrt(u * u + v * v);
          if (mag < 0.005) break;
          cx2 += u / mag * 0.6;
          cy2 += v / mag * 0.6;
          if (cx2 < 1 || cx2 >= N - 1 || cy2 < 1 || cy2 >= N - 1) break;
          path.lineTo(offsetX + cx2 * cellW, offsetY + cy2 * cellH);
        }
        canvas.drawPath(path, _streamPaint);
      }
    }

    // Velocity arrows (reduced density)
    Paint arrowPaint = Paint()
      ..color = (darkMode ? Colors.white : Colors.blueGrey).withValues(alpha: 0.04)
      ..strokeWidth = 0.3;
    for (int aj = 4; aj < N - 4; aj += 12) {
      for (int ai = 4; ai < N - 4; ai += 12) {
        double u = wf.getU(ai, aj);
        double v = wf.getV(ai, aj);
        double mag = sqrt(u * u + v * v);
        if (mag < 0.02) continue;
        double px = offsetX + ai * cellW;
        double py = offsetY + aj * cellH;
        double normU = u / mag, normV = v / mag;
        double len = (mag / (wf.windSpeed * 3)).clamp(0, 1) * cellW * 3;
        canvas.drawLine(Offset(px, py), Offset(px + normU * len, py + normV * len), arrowPaint);
      }
    }
  }
}
