import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../services/locale_controller.dart';

/// 语言选择（设置 → 语言）。
///
/// 选择后：1) 持久化到 LocaleController；2) 调用
/// `EasyLocalization.of(context)!.setLocale(...)` 立即切换，界面（含 RTL 方向）即时刷新。
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  Future<void> _select(BuildContext context, String code) async {
    await LocaleController.save(code);
    if (!context.mounted) return;
    final locale = code == 'system' ? LocaleController.deviceLocale() : Locale(code);
    EasyLocalization.of(context)!.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final followSystem = LocaleController.current.value == null;
    final active = EasyLocalization.of(context)!.locale.languageCode;

    final options = <(String, String, String)>[
      ('system', 'language_system'.tr(), ''),
      ('ar', 'العربية', 'ar'),
      ('en', 'English', 'en'),
      ('fr', 'Français', 'fr'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('language_section'.tr())),
      body: ListView(
        children: [
          for (final (code, label, _) in options)
            ListTile(
              title: Text(label),
              trailing: (code == 'system' ? followSystem : (!followSystem && active == code))
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => _select(context, code),
            ),
        ],
      ),
    );
  }
}
