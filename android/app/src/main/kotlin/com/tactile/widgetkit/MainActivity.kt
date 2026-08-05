package com.tactile.widgetkit

import android.content.Intent
import android.os.Bundle
import com.tactile.widgetkit.wonder.WonderCalendarWidgetProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingAction: String? = null
    private var pendingDate: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val route = intent?.getStringExtra("route")
        if (route != null) {
            pendingAction = route
            pendingDate = intent.getStringExtra("target_date")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tactile.widgetkit/wonder_channel")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "refresh" -> {
                        WonderCalendarWidgetProvider.updateAll(this)
                        result.success(true)
                    }
                    "getPendingAction" -> {
                        val action = pendingAction
                        val date = pendingDate
                        pendingAction = null
                        pendingDate = null
                        result.success(mapOf("action" to action, "date" to date))
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
