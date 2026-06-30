import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/simulation_engine.dart' show TurbineType;
import '../../fluid/wind_fluid.dart';
import '../../fluid/fluid_painter.dart';
import '../../providers/simulation_provider.dart';
import '../../renderer/camera.dart';
import '../../renderer/turbine_renderer.dart';
import '../widgets/charts.dart';
import '../widgets/controls_panel.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  final Camera3D _camera = Camera3D();
  final TurbineMeshes _turbineMeshes = TurbineMeshes();
  final WindFluid _windFluid = WindFluid();
  final FluidPainter _fluidPainter = FluidPainter();
  late Ticker _ticker;
  double _lastTime = 0;
  double _elapsedTime = 0;
  double _rotationAngle = 0;
  int _frameCount = 0;
  TurbineType _lastType = TurbineType.standard;
  bool _fluidInitialized = false;
  final ValueNotifier<int> _repaintNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _turbineMeshes.build(3, 0.6, 5, type: TurbineType.standard);
  }

  void _initFluid() {
    final p = ref.read(simulationProvider).params;
    _windFluid.init(p.windSpeed);
    _fluidInitialized = true;
  }

  void _onTick(Duration elapsed) {
    double t = elapsed.inMicroseconds / 1000000.0;
    double dt = t - _lastTime;
    _lastTime = t;
    if (dt > 0.1) dt = 0.016;
    _elapsedTime += dt;

    final state = ref.read(simulationProvider);

    double rpm = state.lastRpm;
    if (rpm > 0 && !state.turbine.isPaused) {
      double radPerSec = rpm / 60 * 2 * pi;
      _rotationAngle += radPerSec * dt;
    }
    _turbineMeshes.updateRotation(_rotationAngle);

    bool typeChanged = state.params.turbineType != _lastType;
    if (typeChanged) {
      _lastType = state.params.turbineType;
      _turbineMeshes.build(state.params.bladeCount, state.params.rotorRadius, state.params.pitchAngle, type: state.params.turbineType);
      _turbineMeshes.updateRotation(_rotationAngle);
    }
    int expectedMeshes = state.params.turbineType.isVawt ? 2 : state.params.bladeCount + 3;
    if (!typeChanged && _turbineMeshes.meshes.length != expectedMeshes) {
      _turbineMeshes.build(state.params.bladeCount, state.params.rotorRadius, state.params.pitchAngle, type: state.params.turbineType);
      _turbineMeshes.updateRotation(_rotationAngle);
    }
    _turbineMeshes.applyRotation(state.params.bladeCount, state.params.pitchAngle, type: state.params.turbineType);

    _frameCount++;
    if (!state.turbine.isPaused && _frameCount % 2 == 0) {
      if (!_fluidInitialized) _initFluid();
      _windFluid.update(dt,
          rotationAngle: _rotationAngle,
          cp: state.params.cp,
          bladeCount: state.params.bladeCount,
          turbineType: state.params.turbineType);
    }

    _repaintNotifier.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simulationProvider);
    _fluidPainter.windFluid = _windFluid;
    _fluidPainter.darkMode = state.turbine.darkMode;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          label: 'Wind Turbine Simulator — Interactive 3D BEM Physics Simulation',
          child: const Text('Wind Turbine Simulator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        actions: [
          _iconBtn(Icons.library_books_outlined, 'Design Standards', () => Navigator.pushNamed(context, '/standards')),
          _iconBtn(Icons.calculate_outlined, 'Wind Power Calculator', () => Navigator.pushNamed(context, '/calculator')),
          _iconBtn(Icons.pause_rounded, 'Pause', ref.read(simulationProvider.notifier).togglePause, state.turbine.isPaused ? Colors.amber : null),
          _iconBtn(Icons.grid_on, 'Wireframe', ref.read(simulationProvider.notifier).toggleWireframe, state.turbine.wireframe ? Colors.amber : null),
          _iconBtn(Icons.dark_mode_outlined, 'Theme', ref.read(simulationProvider.notifier).toggleDarkMode),
          _iconBtn(Icons.restart_alt, 'Reset Camera', () => ref.read(simulationProvider.notifier).resetCamera(_camera)),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isLandscape = constraints.maxWidth > constraints.maxHeight && constraints.maxWidth > 700;
          if (isLandscape) {
            return Row(
              children: [
                SizedBox(width: 320, child: _leftPanel(context, state)),
                Expanded(child: _rightPanel(context, state)),
              ],
            );
          } else {
            return Column(
              children: [
                SizedBox(height: 300, child: _rightPanel(context, state)),
                Expanded(child: _leftPanel(context, state)),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap, [Color? color]) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  Widget _leftPanel(BuildContext context, SimulationState state) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(child: ControlsPanel()),
          SizedBox(
            height: 140,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: SimulationCharts(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rightPanel(BuildContext context, SimulationState state) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowLeft:
              _camera.orbit(0.04, 0);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowRight:
              _camera.orbit(-0.04, 0);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowUp:
              _camera.orbit(0, 0.04);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.arrowDown:
              _camera.orbit(0, -0.04);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.pageUp:
              _camera.zoom(-0.3);
              return KeyEventResult.handled;
            case LogicalKeyboardKey.pageDown:
              _camera.zoom(0.3);
              return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onScaleUpdate: (details) {
          if (details.pointerCount == 1) {
            _camera.orbit(details.focalPointDelta.dx * 0.008, -details.focalPointDelta.dy * 0.008);
          } else if (details.pointerCount == 2) {
            _camera.zoom(-details.scale * 0.05);
          }
        },
        onScaleEnd: (_) {},
        child: Container(
          color: const Color(0xFF0D1117),
          child: Stack(
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: TurbinePainter(
                    repaint: _repaintNotifier,
                    camera: _camera,
                    meshes: _turbineMeshes,
                    wireframe: state.turbine.wireframe,
                    darkMode: state.turbine.darkMode,
                    turbineTypeLabel: state.params.turbineType.label,
                    windSpeed: state.params.windSpeed,
                    elapsedTime: _elapsedTime,
                    fluidPainter: _fluidPainter,
                  ),
                ),
              ),
              Positioned(
                left: 12, bottom: 12,
                child: Semantics(
                  label: 'Turbine status: ${state.params.turbineType.label}, wind speed ${state.params.windSpeed.toStringAsFixed(1)} meters per second, RPM ${state.results?.rpm.toStringAsFixed(0) ?? "0"}, power ${state.results?.power.toStringAsFixed(0) ?? "0"} watts',
                  child: state.results != null ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.params.turbineType.label, style: const TextStyle(color: Colors.cyan, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Wind: ${state.params.windSpeed.toStringAsFixed(1)} m/s  |  RPM: ${state.results!.rpm.toStringAsFixed(0)}  |  Power: ${state.results!.power.toStringAsFixed(0)} W',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
                        if (state.params.turbineType.isVawt)
                          const Text('VAWT — omnidirectional', style: TextStyle(color: Colors.white38, fontSize: 9, fontFamily: 'monospace')),
                      ],
                    ),
                  ) : const SizedBox(),
                ),
              ),
              if (state.turbine.isPaused)
                Semantics(
                  label: 'Simulation paused',
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pause_circle, color: Colors.white54, size: 48),
                        SizedBox(height: 8),
                        Text('PAUSED', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              Positioned(
                right: 12, bottom: 12,
                child: Semantics(
                  label: 'Camera controls: drag to orbit, scroll to zoom, arrow keys to rotate',
                  child: const Text('Drag to orbit • Pinch/Scroll to zoom • Arrow keys to rotate', style: TextStyle(color: Colors.white54, fontSize: 10)),
                ),
              ),
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Semantics(
                  label: 'Wind Turbine Simulator: Interactive 3D wind energy simulation using Blade Element Momentum BEM physics. Adjust wind speed, rotor radius, blade count, TSR, and pitch angle to calculate power output, RPM, torque, and thrust.',
                  child: const SizedBox(
                    height: 8,
                    child: Center(
                      child: Text('Wind Turbine Simulator — BEM Physics • HAWT & VAWT • Wind Energy Calculator',
                        style: TextStyle(color: Colors.transparent, fontSize: 8, height: 0)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TurbinePainter extends CustomPainter {
  final Camera3D camera;
  final TurbineMeshes meshes;
  final bool wireframe;
  final bool darkMode;
  final String turbineTypeLabel;
  final double windSpeed;
  final double elapsedTime;
  final FluidPainter? fluidPainter;

  TurbinePainter({
    required this.camera,
    required this.meshes,
    required this.wireframe,
    required this.darkMode,
    this.turbineTypeLabel = 'Standard HAWT',
    this.windSpeed = 6,
    this.elapsedTime = 0,
    this.fluidPainter,
    Listenable? repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    double cx = size.width / 2, cy = size.height / 2;

    if (darkMode) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF0D1117));
      Rect skyRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.6);
      canvas.drawRect(skyRect, Paint()..shader = ui.Gradient.linear(
        Offset(0, 0), Offset(0, skyRect.height),
        [const Color(0xFF0A0E14), const Color(0xFF161B22)], [0.0, 1.0],
      ));
    } else {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFE8ECF1));
      Rect skyRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.6);
      canvas.drawRect(skyRect, Paint()..shader = ui.Gradient.linear(
        Offset(0, 0), Offset(0, skyRect.height),
        [const Color(0xFF87CEEB), const Color(0xFFE8ECF1)], [0.0, 1.0],
      ));
    }

    Paint horizonPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy + 50), size.width * 0.6,
        [darkMode ? const Color(0x334FC3F7) : const Color(0x191976D2), Colors.transparent],
        [0.0, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), horizonPaint);

    Paint gridPaint = Paint()
      ..color = (darkMode ? Colors.white12 : Colors.black12)
      ..strokeWidth = 0.5;
    double horizonY = cy + 50;
    for (double x = -2; x <= 2; x += 0.5) {
      canvas.drawLine(Offset(cx + x * 100, horizonY - 2 * 100), Offset(cx + x * 100, horizonY + 2 * 100), gridPaint);
    }
    for (double y = -2; y <= 2; y += 0.5) {
      double yPos = horizonY + y * 100;
      canvas.drawLine(Offset(cx - 2 * 100, yPos), Offset(cx + 2 * 100, yPos), gridPaint);
    }
    Paint horizonLine = Paint()
      ..color = (darkMode ? Colors.white24 : Colors.black26)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), horizonLine);

    if (fluidPainter != null && fluidPainter!.windFluid != null) {
      fluidPainter!.paint(canvas, size, cx, horizonY - 40, size.width * 0.42, elapsedTime);
    }

    Renderer3D renderer = Renderer3D(camera: camera, meshes: meshes.meshes, wireframe: wireframe);
    renderer.render(canvas, size, 0);

    TextPainter tp = TextPainter(
      text: TextSpan(
        text: turbineTypeLabel,
        style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, 10));
  }

  @override
  bool shouldRepaint(covariant TurbinePainter oldDelegate) => true;
}
