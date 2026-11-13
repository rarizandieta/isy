import 'package:flutter/material.dart';

import '../../data/services/token_storage.dart';

/// Controla el modo de tema de la app (sistema / claro / oscuro) y lo persiste
/// en el almacenamiento del dispositivo. Por defecto: CLARO.
class ThemeController extends ChangeNotifier {
  ThemeController(this._storage, {ThemeMode initial = ThemeMode.light}) : _mode = initial;

  final TokenStorage _storage;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _storage.saveThemeMode(themeModeToWire(mode));
  }
}

/// Serializa el modo de tema para guardarlo.
String themeModeToWire(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    };

/// Lee el modo de tema guardado. Por defecto CLARO (nacen en claro).
ThemeMode themeModeFromWire(String? value) => switch (value) {
      'system' => ThemeMode.system,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };

/// Etiqueta en español para la UI.
String themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'Según el sistema',
      ThemeMode.light => 'Claro',
      ThemeMode.dark => 'Oscuro',
    };
