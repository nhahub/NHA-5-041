import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'app/app_dependencies.dart';
import 'app/food_planner_app.dart';
import 'core/prefs/preference_manager.dart';
import 'data/reminders/reminder_service_impl.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase needs google-services.json / DefaultFirebaseOptions.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  try {
    await Workmanager().initialize(reminderCallbackDispatcher);
  } catch (_) {}

  // Initialise the SharedPreferences singleton once — every later access
  // goes through PreferenceManager.instance (no await needed).
  final prefManager = await PreferenceManager.init();

  runApp(
    FoodPlannerApp(
      deps: AppDependencies.production(
        prefManager: prefManager,
        firebaseReady: firebaseReady,
      ),
    ),
  );
}
