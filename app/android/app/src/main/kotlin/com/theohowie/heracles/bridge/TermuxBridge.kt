package com.theohowie.heracles.bridge

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Termux 集成（阶段 2）—— 通道 `heracles/termux`。
 *
 * 只做三件事：
 *  1. 查询 Termux 是否安装、`com.termux.permission.RUN_COMMAND` 是否已授予；
 *  2. 把一条命令交给 Termux 的 `RunCommandService` 执行（命令本身由 Dart 侧
 *     展示给用户，用户确认后才会调用这里）；
 *  3. 打开 Termux 的 F-Droid 页面（Play 版 Termux 已停止维护，签名也不同）。
 *
 * ## 注意
 *  - Termux 的输出不会回到本 App：命令在 Termux 里以可见会话运行，结果由用户在
 *    Termux 里查看。这是有意的 —— 安装过程要让用户看得见。
 *  - 用户还需要在 Termux 的 `~/.termux/termux.properties` 里设置
 *    `allow-external-apps = true`，否则 Termux 会拒绝外部 Intent。
 *    本 App 无法读取或修改这个设置，只能提示用户。
 */
class TermuxBridge(private val context: Context) {

    companion object {
        const val CHANNEL = "heracles/termux"

        const val TERMUX_PACKAGE = "com.termux"
        const val TERMUX_PERMISSION = "com.termux.permission.RUN_COMMAND"
        const val RUN_COMMAND_ACTION = "com.termux.RUN_COMMAND"
        const val RUN_COMMAND_SERVICE = "com.termux.app.RunCommandService"
        const val EXTRA_PATH = "com.termux.RUN_COMMAND_PATH"
        const val EXTRA_ARGUMENTS = "com.termux.RUN_COMMAND_ARGUMENTS"
        const val EXTRA_WORKDIR = "com.termux.RUN_COMMAND_WORKDIR"
        const val EXTRA_BACKGROUND = "com.termux.RUN_COMMAND_BACKGROUND"
        const val EXTRA_SESSION_ACTION = "com.termux.RUN_COMMAND_SESSION_ACTION"

        // Termux 自己的 bash，路径固定。
        const val TERMUX_BASH = "/data/data/com.termux/files/usr/bin/bash"
        const val TERMUX_HOME = "/data/data/com.termux/files/home"

        const val FDROID_PAGE = "https://f-droid.org/packages/com.termux/"
    }

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(status())
            "run" -> {
                val command = call.argument<String>("command")
                if (command.isNullOrBlank()) {
                    result.success(mapOf("ok" to false, "reason" to "empty_command"))
                } else {
                    result.success(runCommand(command))
                }
            }
            "openDownload" -> {
                openUrl(FDROID_PAGE)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun isInstalled(): Boolean = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.packageManager.getPackageInfo(
                TERMUX_PACKAGE,
                PackageManager.PackageInfoFlags.of(0),
            )
        } else {
            @Suppress("DEPRECATION")
            context.packageManager.getPackageInfo(TERMUX_PACKAGE, 0)
        }
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private fun permissionGranted(): Boolean =
        context.checkSelfPermission(TERMUX_PERMISSION) == PackageManager.PERMISSION_GRANTED

    private fun status(): Map<String, Any> = mapOf(
        "installed" to isInstalled(),
        "permissionGranted" to permissionGranted(),
    )

    private fun runCommand(command: String): Map<String, Any> {
        if (!isInstalled()) return mapOf("ok" to false, "reason" to "not_installed")
        if (!permissionGranted()) return mapOf("ok" to false, "reason" to "permission_denied")

        val intent = Intent(RUN_COMMAND_ACTION).apply {
            setClassName(TERMUX_PACKAGE, RUN_COMMAND_SERVICE)
            putExtra(EXTRA_PATH, TERMUX_BASH)
            putExtra(EXTRA_ARGUMENTS, arrayOf("-lc", command))
            putExtra(EXTRA_WORKDIR, TERMUX_HOME)
            // 前台会话：用户能在 Termux 里看到安装进度与报错。
            putExtra(EXTRA_BACKGROUND, false)
            putExtra(EXTRA_SESSION_ACTION, "0")
        }
        return try {
            context.startService(intent)
            mapOf("ok" to true)
        } catch (e: SecurityException) {
            mapOf("ok" to false, "reason" to "permission_denied")
        } catch (e: IllegalStateException) {
            // Android 8+ 在后台启动服务会抛这个；本 App 通常在前台，但仍要兜住。
            mapOf("ok" to false, "reason" to "background_start_blocked")
        }
    }

    private fun openUrl(url: String) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }
}
