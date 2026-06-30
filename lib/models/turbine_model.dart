class TurbineState {
  final double rotationAngle;
  final bool isPaused;
  final bool wireframe;
  final bool darkMode;
  final double cameraAzimuth;
  final double cameraElevation;
  final double cameraDistance;

  const TurbineState({
    this.rotationAngle = 0,
    this.isPaused = false,
    this.wireframe = false,
    this.darkMode = true,
    this.cameraAzimuth = 0.8,
    this.cameraElevation = 0.4,
    this.cameraDistance = 3.0,
  });

  TurbineState copyWith({
    double? rotationAngle,
    bool? isPaused,
    bool? wireframe,
    bool? darkMode,
    double? cameraAzimuth,
    double? cameraElevation,
    double? cameraDistance,
  }) {
    return TurbineState(
      rotationAngle: rotationAngle ?? this.rotationAngle,
      isPaused: isPaused ?? this.isPaused,
      wireframe: wireframe ?? this.wireframe,
      darkMode: darkMode ?? this.darkMode,
      cameraAzimuth: cameraAzimuth ?? this.cameraAzimuth,
      cameraElevation: cameraElevation ?? this.cameraElevation,
      cameraDistance: cameraDistance ?? this.cameraDistance,
    );
  }
}
