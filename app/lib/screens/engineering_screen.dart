import 'package:easy_localization/easy_localization.dart';
import '../widgets/landscape_frame.dart';
import 'package:flutter/material.dart';

import '../services/termux_service.dart';
import 're_toolkit_screen.dart';

/// 「工程」页（阶段 2）：语言选择 + Termux 集成。
/// 阶段 3 的 Reverse Engineering Toolkit 会加在这里（开发者模式入口）。
class EngineeringScreen extends StatefulWidget {
  const EngineeringScreen({super.key});

  @override
  State<EngineeringScreen> createState() => _EngineeringScreenState();
}

class _EngineeringScreenState extends State<EngineeringScreen> {
  TermuxStatus? _termux;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _checking = true);
    final s = await TermuxService.status();
    if (!mounted) return;
    setState(() {
      _termux = s;
      _checking = false;
    });
  }

  Future<void> _confirmAndRun() async {
    final command = TermuxService.installCommand();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('termux_confirm_title'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('termux_confirm_body'.tr()),
              const SizedBox(height: 12),
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final termux = _termux;

    return Scaffold(
      appBar: AppBar(title: Text('engineering_title'.tr())),
      body: LandscapeFrame(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: 'termux_section'.tr()),
          Text('termux_intro'.tr()),
          const SizedBox(height: 12),
          if (termux == null || _checking)
            const LinearProgressIndicator()
          else ...[
            _StatusRow(
              ok: termux.installed,
              text: termux.installed
                  ? 'termux_status_installed'.tr()
                  : 'termux_status_missing'.tr(),
            ),
            _StatusRow(
              ok: termux.permissionGranted,
              text: termux.permissionGranted
                  ? 'termux_permission_ok'.tr()
                  : 'termux_permission_missing'.tr(),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: TermuxService.openDownloadPage,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text('termux_download'.tr()),
              ),
              OutlinedButton(
                onPressed: _refresh,
                child: Text('termux_recheck'.tr()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('termux_external_apps_hint'.tr(),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('termux_permission_hint'.tr(),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 20),
          _Section(title: 'termux_command_title'.tr()),
          Text('termux_command_note'.tr()),
          const SizedBox(height: 8),
          SelectableText(
            TermuxService.installCommand(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: (termux?.ready ?? false)
                ? () => _confirmAndRun()
                : null,
            icon: const Icon(Icons.terminal, size: 16),
            label: Text('termux_run_button'.tr()),
          ),
          const SizedBox(height: 24),
          _Section(title: 're_toolkit_title'.tr()),
          Text('re_intro'.tr()),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReToolkitScreen()),
            ),
            icon: const Icon(Icons.build_circle_outlined, size: 16),
            label: Text('re_toolkit_title'.tr()),
          ),
        ],
      )),,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.ok, required this.text});
  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(ok ? Icons.check_circle : Icons.cancel,
                size: 18, color: ok ? Colors.green : Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
