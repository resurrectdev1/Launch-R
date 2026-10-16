import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:launch_r/app.dart';
import 'package:launch_r/providers/launcher_model.dart';
import 'package:launch_r/providers/launcher_settings.dart';
import 'package:launch_r/services/icon_cache.dart';
import 'package:launch_r/services/launch_history.dart';
import 'package:launch_r/services/launcher_channel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  unawaited(
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  );
  LauncherChannel.instance.init();

  final settings = LauncherSettings();
  final model = LauncherModel();
  final history = LaunchHistory();

  try {
    await settings.init();
    IconCache.instance.shape = settings.iconShape;
  } catch (e, s) {
    debugPrint('Launch-R: settings init failed: $e\n$s');
  }

  try {
    await history.init();
  } catch (e, s) {
    debugPrint('Launch-R: launch history init failed: $e\n$s');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: model),
        ChangeNotifierProvider.value(value: history),
      ],
      child: const LaunchRApp(),
    ),
  );

  try {
    final pack = settings.iconPack;
    if (pack != null) {
      final ok = await LauncherChannel.instance.setIconPack(pack);
      if (ok == false) await settings.setIconPack(null, null);
    }
  } catch (e, s) {
    debugPrint('Launch-R: icon pack restore failed: $e\n$s');
  }

  try {
    await model.init();
    debugPrint('Launch-R: model ready');
  } catch (e, s) {
    debugPrint('Launch-R: model init failed: $e\n$s');
  }
}
