import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/webmcp_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    try {
      FirebaseCrashlytics.instance.recordFlutterError(details);
    } catch (_) {
      debugPrint('Unhandled Flutter error: ${details.exception}');
    }
  };

  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    try {
      FirebaseCrashlytics.instance.recordError(error, stack);
    } catch (_) {
      debugPrint('Unhandled platform error: $error');
    }
    return true;
  };

  final container = ProviderContainer();
  runApp(UncontrolledProviderScope(container: container, child: const WindTurbineApp()));

  unawaited(_initFirebase());
  WebMCPService.init(container);
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
}
