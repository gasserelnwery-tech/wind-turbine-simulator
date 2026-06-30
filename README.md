# Wind Turbine Simulator — Interactive 3D BEM Physics Simulation

**Live Demo** → [wind-turbine-1ef3d.web.app](https://wind-turbine-1ef3d.web.app/)  
**GitHub** → [github.com/gasserelnwery-tech/wind-turbine-simulator](https://github.com/gasserelnwery-tech/wind-turbine-simulator)  
**Stack** → Flutter Web · Dart · Riverpod · BEM Physics · Stable Fluids · Wasm · Firebase Hosting

Real-time interactive 3D wind turbine simulation built with **Flutter Web**. Features a custom software 3D renderer (no WebGL), Blade Element Momentum (BEM) physics engine with Newton-Raphson iteration, and a 2D wind fluid dynamics solver using the Stable Fluids method.

```bash
git clone https://github.com/gasserelnwery-tech/wind-turbine-simulator.git
cd wind_turbine_app
flutter pub get
flutter run -d chrome
```

**Routes** — `/` (simulation) · [`/standards`](https://wind-turbine-1ef3d.web.app/standards) (IEC 61400) · [`/calculator`](https://wind-turbine-1ef3d.web.app/calculator) (wind power)

---

## Features

- **Real-time 3D rendering** — Custom software renderer with painter's algorithm, horizon gradient, and perspective projection
- **BEM Physics Engine** — Actuator disk model computes power, RPM, torque, and thrust via Newton-Raphson axial induction factor
- **2D Wind Fluid Simulation** — Jos Stam Stable Fluids method on an 80×80 grid with wake modeling and turbulence
- **5 Turbine Presets** — Standard HAWT, High-Speed HAWT (2-blade), High-Torque HAWT (5-blade), Darrieus VAWT, Savonius VAWT
- **Live Performance Charts** — Power vs wind speed, RPM vs wind speed, Cp vs wind speed with Betz limit line
- **Interactive Controls** — Adjust wind speed, rotor radius, blade count, TSR, pitch angle, air density, and Cp in real-time
- **IEC 61400 Standards Reference** — Design requirements, power performance classes, wind speed bins
- **Keyboard & Touch Controls** — Drag to orbit, pinch/scroll to zoom, arrow keys for fine camera control

---

## Tech Stack

| Technology | Purpose |
|------------|---------|
| **Flutter Web 3.41** | Cross-platform UI framework |
| **Dart 3.11** | Application language |
| **Riverpod 3.x** | Reactive state management |
| **Custom 3D Renderer** | `CustomPainter` + `Canvas` (no WebGL/Three.js) |
| **Custom Math Library** | `Vec3`, `Mat4`, `TriMesh` in `math3d.dart` |
| **BEM Physics** | Actuator disk + Newton-Raphson solver |
| **Stable Fluids** | Jos Stam 1999, 80×80 grid |
| **fl_chart** | Performance visualization charts |
| **Firebase Hosting** | Deployment & Crashlytics |
| **WebAssembly (Wasm)** | Production build target for performance |

---

## Physics Models

### Blade Element Momentum (BEM) Theory

The simulator implements the industry-standard BEM method for wind turbine rotor analysis:

1. **Actuator Disk Model** — Treats the rotor as a permeable disk that extracts kinetic energy from the wind
2. **Newton-Raphson Solver** — Iteratively converges on the axial induction factor `a` (the fractional wind speed reduction at the rotor plane)
3. **Betz Limit** — Maximum theoretical Cp = 16/27 ≈ 0.593, achieved at `a = 1/3`
4. **Outputs** — Power (W), RPM, torque (N·m), thrust (N), swept area (m²), tip speed (m/s)
5. **Pitch Factor** — Gaussian efficiency curve centered on each turbine type's optimal pitch angle

### 2D Wind Fluid Simulation

- **Stable Fluids Method** (Jos Stam, SIGGRAPH 1999)
- Diffusion, advection, and projection steps per frame
- Wake modeling behind the rotor with decay and turbulence injection
- Obstacle mask for the hub/rotor area

---

## Getting Started

```bash
# Prerequisites: Flutter SDK 3.x+
git clone https://github.com/gasserelnwery-tech/wind-turbine-simulator.git
cd wind_turbine_app

# Install dependencies
flutter pub get

# Run in development (Chrome)
flutter run -d chrome

# Build for production (Wasm)
flutter build web --wasm --release

# Build without Wasm (fallback)
flutter build web --release

# Lint & typecheck
flutter analyze
```

---

## Project Structure

```
lib/
├── core/
│   ├── math3d.dart               # Vec3, Mat4, TriMesh — custom 3D math library
│   └── simulation_engine.dart     # BEM physics, Newton-Raphson solver, presets
├── fluid/
│   ├── fluid_solver.dart          # Stable Fluids (diffuse, project, advect)
│   ├── wind_fluid.dart            # Wind-specific source injection, wake, turbulence
│   └── fluid_painter.dart         # Canvas rendering of density, streamlines, arrows
├── models/
│   └── turbine_model.dart         # Data classes for params, results, state
├── providers/
│   └── simulation_provider.dart   # Riverpod Notifier — all simulation state
├── renderer/
│   ├── camera.dart                # 3D orbit camera (azimuth, elevation, distance)
│   └── turbine_renderer.dart      # Mesh builders for blades, tower, hub, VAWT
├── services/
│   └── webmcp_service.dart        # WebMCP bridge for AI agent tool integration
├── ui/
│   ├── pages/
│   │   ├── home_page.dart         # Main split-screen layout + 3D viewport + HUD
│   │   ├── standards_page.dart    # IEC 61400 reference tables
│   │   └── calculator_page.dart   # Wind power formula reference
│   ├── widgets/
│   │   ├── controls_panel.dart    # Parameter sliders, results display, presets
│   │   └── charts.dart            # fl_chart line charts (Power, RPM, Cp)
│   └── theme.dart                 # Dark theme (Google Fonts + Material)
├── app.dart                       # MaterialApp with deferred route loading
└── main.dart                      # Entry point, Firebase init, WebMCP init
web/
├── index.html                     # CSP, SEO meta, JSON-LD, OG tags, loading screen
├── webmcp.js                      # WebMCP tools for AI agent integration
└── llms.txt                       # Machine-readable site summary for AI crawlers
```

---

## Routes

| Path | Page | Description |
|------|------|-------------|
| `/` | `HomePage` | Simulation viewport + controls + charts + HUD |
| `/standards` | `StandardsPage` | IEC 61400 wind turbine design reference |
| `/calculator` | `CalculatorPage` | Wind power formula reference |

---

## Performance Optimizations

- **WebAssembly (Wasm)** — Dart compiled to Wasm instead of JS for faster execution
- **Deferred loading** — `/standards` and `/calculator` pages loaded on-demand
- **RepaintBoundary** — Isolates 3D viewport repainting from controls
- **Local rotation tracking** — Avoids Riverpod state updates per animation frame
- **Fluid solver** — Reduced Gauss-Seidel iterations, runs every 2nd frame

---

## Links

- **Live App** → [wind-turbine-1ef3d.web.app](https://wind-turbine-1ef3d.web.app/)
- **Standards Reference** → [wind-turbine-1ef3d.web.app/standards](https://wind-turbine-1ef3d.web.app/standards)
- **Calculator** → [wind-turbine-1ef3d.web.app/calculator](https://wind-turbine-1ef3d.web.app/calculator)
- **IEC 61400** → [iec.ch/standards/61400](https://iec.ch/standards/61400)
- **BEM Theory** → [Wikipedia](https://en.wikipedia.org/wiki/Blade_element_momentum_theory)
- **Betz's Law** → [Wikipedia](https://en.wikipedia.org/wiki/Betz%27s_law)

---

## License

MIT
