import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/strings.dart';
import 'data/models.dart';
import 'data/level_repository.dart';
import 'data/progress_store.dart';
import 'ui/theme.dart';

void main() => runApp(const _Bootstrap());

/// Uygulama başlatıcı: asset'ler yüklenirken loading gösterir, hata olursa
/// hata ekranı basar, başarılı olursa asıl uygulamaya geçer.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  List<Level>? _levels;
  ProgressStore? _store;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp],
      );
    }

    try {
      await Strings.load();
      final levels = await LevelRepository.load();
      final store = await ProgressStore.create();
      if (!mounted) return;
      setState(() {
        _levels = levels;
        _store = store;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Дош йоазув чекхдаккха цалуш я:\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );
    }
    if (_levels == null || _store == null) {
      return MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    return DoshApp(levels: _levels!, store: _store!);
  }
}
