import 'package:easy_localization/easy_localization.dart';
import '../widgets/landscape_frame.dart';
import 'package:flutter/material.dart';

import '../services/re_toolkit.dart';
import '../services/termux_service.dart';

/// Reverse Engineering Toolkit（阶段 3）。
///
/// 每个按钮都先弹出**完整命令**，用户确认后才交给 Termux 执行。
/// 没有任何一条命令会自动运行。
class ReToolkitScreen extends StatefulWidget {
  const ReToolkitScreen({super.key});

  @override
  State<ReToolkitScreen> createState() => _ReToolkitScreenState();
}

class _ReToolkitScreenState extends State<ReToolkitScreen> {
  final _apk = TextEditingController(text: ReToolkit.defaultApk);
  final _src = TextEditingController(text: ReToolkit.defaultSrcDir);
  final _out = TextEditingController(text: ReToolkit.defaultOutApk);
  final _keystore = TextEditingController(text: ReToolkit.defaultKeystore);
  final _package = TextEditingController();
  final _script = TextEditingController(text: ReToolkit.defaultScript);

  bool? _termuxReady;

  @override
  void initState() {
    super.initState();
    TermuxService.status().then((s) {
      if (mounted) setState(() => _termuxReady = s.ready);
    });
  }

  @override
  void dispose() {
    for (final c in [_apk, _src, _out, _keystore, _package, _script]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmAndRun(String title, String command) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('re_confirm_title'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('re_confirm_body'.tr()),
              const SizedBox(height: 12),
              Text('re_command_label'.tr(),
                  style: Theme.of(ctx).textTheme.labelSmall),
              const SizedBox(height: 4),
              SelectableText(
                command,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('termux_confirm_action'.tr()),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final result = await TermuxService.run(command);
    if (!mounted) return;
    final msg = result.ok
        ? 'termux_sent'.tr()
        : switch (result.error) {
            TermuxRunError.notInstalled => 'termux_err_not_installed'.tr(),
            TermuxRunError.permissionDenied => 'termux_err_permission'.tr(),
            TermuxRunError.backgroundBlocked => 'termux_err_background'.tr(),
            _ => 'termux_err_unknown'.tr(),
          };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          decoration: InputDecoration(labelText: label, isDense: true),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      );

  Widget _action(String label, String Function() build, {String? title}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton(
          onPressed: (_termuxReady ?? false)
              ? () => _confirmAndRun(title ?? label, build())
              : null,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(label),
          ),
        ),
      );

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('re_toolkit_title'.tr())),
      body: LandscapeFrame(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('re_intro'.tr()),
          const SizedBox(height: 8),
          Text('re_storage_note'.tr(),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: (_termuxReady ?? false)
                ? () => _confirmAndRun(
                    're_setup_storage'.tr(), ReToolkit.setupStorage())
                : null,
            child: Text('re_setup_storage'.tr()),
          ),
          const SizedBox(height: 16),
          _field(_apk, 're_path_apk'.tr()),
          _field(_src, 're_path_src'.tr()),
          _field(_out, 're_path_out'.tr()),
          _field(_keystore, 're_path_keystore'.tr()),
          _field(_package, 're_path_package'.tr()),
          _field(_script, 're_path_script'.tr()),

          _section('re_section_decode'.tr()),
          _action('re_decode_apktool'.tr(),
              () => ReToolkit.apktoolDecode(_apk.text, _src.text)),
          _action('re_decode_jadx'.tr(),
              () => ReToolkit.jadxDecode(_apk.text, '${_src.text}_java')),

          _section('re_section_build'.tr()),
          _action('re_rebuild'.tr(),
              () => ReToolkit.apktoolBuild(_src.text, _out.text)),
          _action('re_align'.tr(),
              () => ReToolkit.zipalign(_out.text, '${_out.text}.aligned.apk')),
          _action('re_sign'.tr(),
              () => ReToolkit.apksign(
                  '${_out.text}.aligned.apk', _keystore.text, _out.text)),
          _action('re_keystore'.tr(), () => ReToolkit.keystore(_keystore.text)),

          _section('re_section_frida'.tr()),
          _action('re_frida_install'.tr(), ReToolkit.installFrida),
          Text('re_root_warning'.tr(), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          _action('re_frida_server'.tr(), ReToolkit.fridaServerStart),
          _action('re_frida_load'.tr(),
              () => ReToolkit.fridaLoad(_package.text, _script.text)),
          const SizedBox(height: 24),
        ],
      )),
    );
  }
}
