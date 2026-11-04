import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言偏好的持久化（easy_localization 负责实时切换）。
///
/// `current == null` 表示「跟随系统」。启动时把它交给 `EasyLocalization(startLocale: …)`。
class LocaleController {
  LocaleController._();

  static const _kKey = 'app_locale';
  static const supported = [Locale('en'), Locale('ar'), Locale('fr')];

  static final ValueNotifier<Locale?> current = ValueNotifier<Locale?>(null);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kKey);
    current.value = switch (code) {
      'ar' => const Locale('ar'),
      'en' => const Locale('en'),
      'fr' => const Locale('fr'),
      _ => null,
    };
  }

  /// [code] 为 `system` / `ar` / `en` / `fr`。
  static Future<void> save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, code);
    current.value = code == 'system' ? null : Locale(code);
  }

  /// 系统语言在支持列表内则用它，否则英文（与需求中的默认 en 一致）。
  static Locale deviceLocale() {
    final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    for (final l in supported) {
      if (l.languageCode == device) return l;
    }
    return const Locale('en');
  }
}
