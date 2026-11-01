package org.plutoinspection.pluto_inspector

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var verificationChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        verificationChannel = MethodChannel(
            messenger,
            "org.plutoinspection/verification_v1",
            io.flutter.plugin.common.StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue()
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    // Explicit absence, not synthetic inference. ML's Android
                    // adapter must replace this handler at final integration.
                    "verify" -> result.error("ENGINE_UNAVAILABLE",
                        "No Android verification engine/model is installed.", null)
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        verificationChannel?.setMethodCallHandler(null)
        verificationChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
