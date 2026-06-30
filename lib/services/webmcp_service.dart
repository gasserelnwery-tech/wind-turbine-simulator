import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/simulation_provider.dart';
import '../core/simulation_engine.dart' show TurbineType;

@JS('globalThis')
external JSObject get _globalThis;

class WebMCPService {
  static Timer? _timer;
  static bool _initialized = false;

  static void init(ProviderContainer container) {
    if (_initialized) return;
    _initialized = true;

    if (!_bridgeAvailable()) return;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _poll(container);
    });
  }

  static bool _bridgeAvailable() {
    final bridge = _globalThis['__webmcp'];
    if (bridge == null) return false;
    return !bridge.isNull && !bridge.isUndefined;
  }

  static JSObject? _bridge() {
    final bridge = _globalThis['__webmcp'];
    if (bridge == null || bridge.isNull || bridge.isUndefined) return null;
    return bridge as JSObject;
  }

  static void _poll(ProviderContainer container) {
    final bridge = _bridge();
    if (bridge == null) return;

    final cmd = bridge.callMethod('dequeue'.toJS, <JSAny?>[].toJS);
    if (cmd == null || cmd.isNull || cmd.isUndefined) return;

    final cmdObj = cmd as JSObject;
    final idVal = cmdObj['id'];
    final nameVal = cmdObj['name'];

    if (idVal == null || nameVal == null || idVal.isNull || nameVal.isNull) return;

    final id = (idVal.dartify() as num).toInt();
    final name = (nameVal.dartify() as String?) ?? 'unknown';
    Map<String, dynamic> args = {};

    final argsVal = cmdObj['args'];
    if (argsVal != null && !argsVal.isNull && !argsVal.isUndefined) {
      final d = argsVal.dartify();
      if (d is Map) {
        args = d.cast<String, dynamic>();
      }
    }

    _execute(container, id, name, args);
  }

  static void _execute(ProviderContainer container, int id, String name, Map<String, dynamic> args) {
    final resultJson = _handle(container, name, args);

    final bridge = _bridge();
    if (bridge == null) return;

    bridge.callMethod('resolve'.toJS, [id.toJS, resultJson.toJS].toJS);
  }

  static String _handle(ProviderContainer container, String name, Map<String, dynamic> args) {
    try {
      final notifier = container.read(simulationProvider.notifier);
      final state = container.read(simulationProvider);

      switch (name) {
        case 'get_state':
          return jsonEncode({
            'params': {
              'windSpeed': state.params.windSpeed,
              'rotorRadius': state.params.rotorRadius,
              'bladeCount': state.params.bladeCount,
              'cp': state.params.cp,
              'tsr': state.params.tsr,
              'pitchAngle': state.params.pitchAngle,
              'airDensity': state.params.airDensity,
              'turbineType': state.params.turbineType.label,
            },
            if (state.results != null)
              'results': {
                'power': state.results!.power,
                'rpm': state.results!.rpm,
                'torque': state.results!.torque,
                'thrust': state.results!.thrust,
                'sweptArea': state.results!.sweptArea,
                'tipSpeed': state.results!.tipSpeed,
              },
            'paused': state.turbine.isPaused,
            'wireframe': state.turbine.wireframe,
            'darkMode': state.turbine.darkMode,
          });

        case 'set_parameter':
          final key = args['key'] as String;
          final value = (args['value'] as num).toDouble();
          notifier.updateParam(key, value);
          return jsonEncode({'status': 'ok'});

        case 'set_turbine_type':
          final typeStr = args['type'] as String;
          final type = switch (typeStr) {
            'high_speed' => TurbineType.twoBlade,
            'high_torque' => TurbineType.fiveBlade,
            'darrieus' => TurbineType.darrieus,
            'savonius' => TurbineType.savonius,
            _ => TurbineType.standard,
          };
          notifier.updateTurbineType(type);
          return jsonEncode({'status': 'ok', 'turbineType': typeStr});

        case 'toggle_pause':
          notifier.togglePause();
          return jsonEncode({'status': 'ok'});

        case 'toggle_wireframe':
          notifier.toggleWireframe();
          return jsonEncode({'status': 'ok'});

        case 'toggle_dark_mode':
          notifier.toggleDarkMode();
          return jsonEncode({'status': 'ok'});

        default:
          return jsonEncode({'error': 'unknown command'});
      }
    } catch (e) {
      return jsonEncode({'error': e.toString()});
    }
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
