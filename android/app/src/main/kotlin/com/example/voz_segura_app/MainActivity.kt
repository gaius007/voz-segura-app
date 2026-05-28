package com.example.voz_segura_app

import android.os.Build
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.voz_segura_app/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendSMS") {
                val phone = call.argument<String>("phone")
                val message = call.argument<String>("message")
                if (phone != null && message != null) {
                    try {
                        val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            context.getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }
                        smsManager.sendTextMessage(phone, null, message, null, null)
                        result.success("SMS enviado com sucesso!")
                    } catch (e: Exception) {
                        result.error("ERR_SEND", e.message, null)
                    }
                } else {
                    result.error("ERR_ARGS", "Argumentos inválidos", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
