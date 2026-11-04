import 'package:flutter/services.dart';

/// 与原生 `TermuxBridge`（通道 `heracles/termux`）通信（阶段 2）。
class TermuxStatus {
  const TermuxStatus({required this.installed, required this.permissionGranted});
  final bool installed;
  final bool permissionGranted;

  bool get ready => installed && permissionGranted;
}

enum TermuxRunError { notInstalled, permissionDenied, backgroundBlocked, unknown }

class TermuxRunResult {
  const TermuxRunResult.ok() : ok = true, error = null;
  const TermuxRunResult.failed(this.error) : ok = false;
  final bool ok;
  final TermuxRunError? error;
}

class TermuxService {
  TermuxService._();

  static const _channel = MethodChannel('heracles/termux');

  /// 安装用的包列表。每个包单独 `pkg install`，失败只影响那一个，
  /// 并且会在 Termux 里打印出来，而不是整条命令静默失败。
  ///
  /// ⚠️ 下面的包名需要在真机上核对：`apktool`、`jadx`、`apksigner`、`frida`
  /// 不一定都在 Termux 官方仓库里（frida 通常通过 pip 安装）。
  static const packages = [
    'python',
    'openjdk-17',
    'apktool',
    'aapt',
    'zipalign',
    'git',
  ];

  /// 阶段 2 的安装命令（只展示，不自动执行）。
  static String installCommand() {
    final steps = packages
        .map((p) => 'pkg install -y $p || echo "[FAILED] $p"')
        .join(' ; ');
    return 'pkg update -y ; $steps';
  }

  static Future<TermuxStatus> status() async {
    try {
      final m = await _channel.invokeMapMethod<String, dynamic>('status');
      return TermuxStatus(
        installed: m?['installed'] == true,
        permissionGranted: m?['permissionGranted'] == true,
      );
    } on PlatformException {
      return const TermuxStatus(installed: false, permissionGranted: false);
    }
  }

  static Future<TermuxRunResult> run(String command) async {
    try {
      final m = await _channel.invokeMapMethod<String, dynamic>(
        'run',
        {'command': command},
      );
      if (m?['ok'] == true) return const TermuxRunResult.ok();
      return TermuxRunResult.failed(switch (m?['reason']) {
        'not_installed' => TermuxRunError.notInstalled,
        'permission_denied' => TermuxRunError.permissionDenied,
        'background_start_blocked' => TermuxRunError.backgroundBlocked,
        _ => TermuxRunError.unknown,
      });
    } on PlatformException {
      return const TermuxRunResult.failed(TermuxRunError.unknown);
    }
  }

  static Future<void> openDownloadPage() async {
    try {
      await _channel.invokeMethod<bool>('openDownload');
    } on PlatformException {
      // 无法打开浏览器时界面上仍有文字说明，不在这里抛错。
    }
  }
}
