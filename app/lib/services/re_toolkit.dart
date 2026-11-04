/// Reverse Engineering Toolkit（阶段 3）—— 只负责**生成命令字符串**。
///
/// 本文件不执行任何东西。执行只能经由 `TermuxService.run`，而且调用方
/// 必须先把命令完整展示给用户并得到明确确认（见 `engineering_screen.dart`）。
///
/// ## 路径约定
/// Termux 读不到本 App 的私有目录，所以所有输入/输出都放在共享存储：
/// `/storage/emulated/0/Download/HeraclesRE/`。用户需要先在 Termux 里运行
/// `termux-setup-storage` 授予存储权限。
class ReToolkit {
  ReToolkit._();

  static const baseDir = '/storage/emulated/0/Download/HeraclesRE';
  static const defaultApk = '$baseDir/app.apk';
  static const defaultSrcDir = '$baseDir/app_src';
  static const defaultOutApk = '$baseDir/app_patched.apk';
  static const defaultKeystore = '$baseDir/heracles.jks';
  static const defaultScript = '$baseDir/hook.js';

  /// 为 shell 单引号包裹转义：`it's` -> `'it'\''s'`。
  /// 所有来自用户输入的路径都必须经过这里，不能直接拼接。
  static String q(String s) => "'${s.replaceAll("'", "'\\''")}'";

  static String setupStorage() => 'termux-setup-storage';

  static String installFrida() => 'pip install frida-tools';

  // ---- 1. 反编译 ----
  static String apktoolDecode(String apk, String outDir) =>
      'apktool d -f ${q(apk)} -o ${q(outDir)}';

  static String jadxDecode(String apk, String outDir) =>
      'jadx -d ${q(outDir)} ${q(apk)}';

  // ---- 2. 重打包与签名 ----
  static String apktoolBuild(String srcDir, String outApk) =>
      'apktool b ${q(srcDir)} -o ${q(outApk)}';

  /// zipalign 必须在 apksigner 之前执行（v2+ 签名要求 4 字节对齐）。
  static String zipalign(String inApk, String outApk) =>
      'zipalign -f -v 4 ${q(inApk)} ${q(outApk)}';

  /// 用 `--out` 另存，不覆盖原文件。密码由 apksigner 交互式询问，
  /// 不写进命令行（否则会出现在 shell 历史和进程列表里）。
  static String apksign(String alignedApk, String keystore, String outApk) =>
      'apksigner sign --ks ${q(keystore)} --out ${q(outApk)} ${q(alignedApk)}';

  /// 同样交互式输入密码，不带 -storepass / -keypass。
  static String keystore(String path) =>
      'keytool -genkeypair -v -keystore ${q(path)} -alias heracles '
      '-keyalg RSA -keysize 2048 -validity 10000';

  // ---- 3. Frida（需要 root）----
  static const fridaServerPath = '/data/local/tmp/frida-server';

  /// 在设备上以 root 启动 frida-server，监听本机 27042 端口。
  static String fridaServerStart() =>
      "su -c '$fridaServerPath -D' &";

  /// 通过本机端口连接已运行的 frida-server，并加载脚本。
  static String fridaLoad(String package, String script) =>
      'frida -H 127.0.0.1:27042 -f ${q(package)} -l ${q(script)}';
}
