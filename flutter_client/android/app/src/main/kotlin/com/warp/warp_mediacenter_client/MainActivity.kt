package com.warp.warp_mediacenter_client

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var externalPlayerEvents: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        keepScreenOn()
        applyImmersiveMode()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NativeMedia3PlayerPlugin.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXTERNAL_PLAYER_METHODS)
            .setMethodCallHandler { call, result -> handleExternalPlayerCall(call, result) }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EXTERNAL_PLAYER_EVENTS)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        externalPlayerEvents = events
                    }

                    override fun onCancel(arguments: Any?) {
                        externalPlayerEvents = null
                    }
                },
            )
    }

    @Deprecated("Flutter owns remote Back through page/dialog shortcuts.")
    override fun onBackPressed() {
        // Consume Android's native Activity back so remote Back doesn't also
        // close the app after Flutter handles the key event.
    }

    override fun onResume() {
        super.onResume()
        keepScreenOn()
        applyImmersiveMode()
    }

    override fun onDestroy() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        super.onDestroy()
    }

    @Deprecated("Uses startActivityForResult for mpv-android result compatibility.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != MPV_REQUEST_CODE) return
        externalPlayerEvents?.success(
            mapOf(
                "type" to "result",
                "resultCode" to if (resultCode == Activity.RESULT_OK) "ok" else "canceled",
                "positionMs" to readLongExtra(data, "position"),
                "durationMs" to readLongExtra(data, "duration"),
            ),
        )
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) applyImmersiveMode()
    }

    private fun applyImmersiveMode() {
        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
    }

    private fun keepScreenOn() {
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun handleExternalPlayerCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "isMpvInstalled" -> result.success(isPackageInstalled(MPV_PACKAGE))
                "openMpvInstallPage" -> result.success(openMpvInstallPage())
                "launchMpv" -> {
                    val url = call.argument<String>("url") ?: ""
                    if (url.isBlank()) {
                        result.error("MPV_ARGUMENT_ERROR", "url is required", null)
                        return
                    }
                    val title = call.argument<String>("title")
                    val positionMs = call.argument<Number>("positionMs")?.toLong()
                    result.success(launchMpv(url, title, positionMs))
                }

                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            result.error("EXTERNAL_PLAYER_ERROR", error.message, null)
        }
    }

    private fun launchMpv(url: String, title: String?, positionMs: Long?): Boolean {
        if (!isPackageInstalled(MPV_PACKAGE)) return false
        Log.i(TAG, "launchMpv positionMs=${positionMs ?: 0L} title=${!title.isNullOrBlank()} url=$url")
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setPackage(MPV_PACKAGE)
            setDataAndType(Uri.parse(url), "video/*")
            title?.takeIf { it.isNotBlank() }?.let { putExtra("title", it) }
            positionMs?.takeIf { it > 0L }?.let {
                // mpv-android reads this extra with Bundle.getInt("position", 0).
                putExtra("position", it.coerceAtMost(Int.MAX_VALUE.toLong()).toInt())
            }
        }
        startActivityForResult(intent, MPV_REQUEST_CODE)
        return true
    }

    private fun openMpvInstallPage(): Boolean {
        val marketIntent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$MPV_PACKAGE"))
        if (tryStartActivity(marketIntent)) return true
        return tryStartActivity(
            Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=$MPV_PACKAGE")),
        )
    }

    private fun tryStartActivity(intent: Intent): Boolean = try {
        startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    }

    private fun isPackageInstalled(packageName: String): Boolean = try {
        packageManager.getPackageInfo(packageName, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private fun readLongExtra(intent: Intent?, key: String): Long? {
        if (intent?.hasExtra(key) != true) return null
        return when (val value = intent.extras?.get(key)) {
            is Number -> value.toLong()
            is String -> value.toLongOrNull()
            else -> null
        }
    }

    companion object {
        private const val EXTERNAL_PLAYER_METHODS = "warp/external_player/methods"
        private const val EXTERNAL_PLAYER_EVENTS = "warp/external_player/events"
        private const val MPV_PACKAGE = "is.xyz.mpv"
        private const val MPV_REQUEST_CODE = 8104
        private const val TAG = "WarpExternalPlayer"
    }
}
