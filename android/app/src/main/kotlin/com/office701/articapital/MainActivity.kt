package com.office701.articapital

import android.content.Context
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app_group_prefs"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val group = call.argument<String>("group") ?: "group.com.office701.articapital"
            val key = call.argument<String>("key")
            val prefs = getSharedPreferences(group, Context.MODE_PRIVATE)

            when (call.method) {
                "setString" -> {
                    val value = call.argument<String>("value")
                    if (key == null || value == null) {
                        result.success(false)
                    } else {
                        val ok = prefs.edit().putString(key, value).commit()
                        result.success(ok)
                    }
                }
                "getString" -> {
                    if (key == null) {
                        result.success(null)
                    } else {
                        val value = prefs.getString(key, null)
                        result.success(value)
                    }
                }
                "remove" -> {
                    if (key == null) {
                        result.success(false)
                    } else {
                        val ok = prefs.edit().remove(key).commit()
                        result.success(ok)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}


