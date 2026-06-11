import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/strings.dart';
import 'data/level_repository.dart';
import 'data/progress_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mobilde dikey öncelikli (tasarım §12); masaüstü/web'de etkisizdir.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp],
    );
  }

  await Strings.load();
  final levels = await LevelRepository.load();
  final store = await ProgressStore.create();

  runApp(DoshApp(levels: levels, store: store));
}
