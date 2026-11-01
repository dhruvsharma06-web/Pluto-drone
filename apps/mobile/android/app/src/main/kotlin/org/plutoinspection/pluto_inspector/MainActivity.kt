package org.plutoinspection.pluto_inspector

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var verificationChannel: MethodChannel? = null
    @Volatile private var engine: PropellerEngine? = null

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
                    "verify" -> try {
                        val current = engine ?: PropellerEngine(applicationContext).also { engine = it }
                        result.success(current.verify(call.arguments as Map<*, *>))
                    } catch (error: Throwable) {
                        result.error("ENGINE_ERROR", error.message, null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        verificationChannel?.setMethodCallHandler(null)
        verificationChannel = null
        engine?.close()
        engine = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
