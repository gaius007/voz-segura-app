package com.example.voz_segura_app

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity é exigida pelo plugin local_auth (biometria/PIN).
class MainActivity : FlutterFragmentActivity() {
    private val ICON_CHANNEL = "voz_segura/app_icon"

    private val DEFAULT_ALIAS = "com.example.voz_segura_app.MainActivityDefault"
    private val NEWS_ALIAS = "com.example.voz_segura_app.MainActivityNews"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Canal para alternar o ícone do launcher (padrão x camuflado de notícias).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ICON_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setIcon" -> {
                    val alias = call.argument<String>("alias")
                    if (alias == "news" || alias == "default") {
                        try {
                            setLauncherIcon(useNews = alias == "news")
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERR_ICON", e.message, null)
                        }
                    } else {
                        result.error("ERR_ARGS", "Alias inválido", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // Habilita o alias escolhido e desabilita o outro. A troca do componente
    // de launcher pode fazer o Android reiniciar o app (limitação conhecida).
    private fun setLauncherIcon(useNews: Boolean) {
        val pm = packageManager
        val enableAlias = if (useNews) NEWS_ALIAS else DEFAULT_ALIAS
        val disableAlias = if (useNews) DEFAULT_ALIAS else NEWS_ALIAS

        pm.setComponentEnabledSetting(
            ComponentName(packageName, enableAlias),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )
        pm.setComponentEnabledSetting(
            ComponentName(packageName, disableAlias),
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
    }
}
