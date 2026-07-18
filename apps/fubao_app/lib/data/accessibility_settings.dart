import 'package:flutter/material.dart';

import 'local_data_store.dart';

class AccessibilitySettings extends ChangeNotifier {
  AccessibilitySettings({LocalDataStore? store})
      : _store = store ?? PlatformLocalDataStore();

  static const _textScaleKey = 'accessibility-text-scale-v1';
  static const _speechRateKey = 'accessibility-speech-rate-v1';
  final LocalDataStore _store;

  double _textScale = 1;
  double _speechRate = 0.5;
  bool _loaded = false;

  double get textScale => _textScale;
  double get speechRate => _speechRate;
  bool get loaded => _loaded;

  Future<void> load() async {
    final textScale = double.tryParse(await _store.read(_textScaleKey) ?? '');
    final speechRate = double.tryParse(await _store.read(_speechRateKey) ?? '');
    if (textScale != null) _textScale = textScale.clamp(0.9, 1.4);
    if (speechRate != null) _speechRate = speechRate.clamp(0.3, 0.8);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    _textScale = value.clamp(0.9, 1.4);
    notifyListeners();
    await _store.write(_textScaleKey, _textScale.toString());
  }

  Future<void> setSpeechRate(double value) async {
    _speechRate = value.clamp(0.3, 0.8);
    notifyListeners();
    await _store.write(_speechRateKey, _speechRate.toString());
  }
}

class AccessibilitySettingsScope
    extends InheritedNotifier<AccessibilitySettings> {
  const AccessibilitySettingsScope({
    required AccessibilitySettings settings,
    required super.child,
    super.key,
  }) : super(notifier: settings);

  static AccessibilitySettings? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AccessibilitySettingsScope>()
      ?.notifier;
}
