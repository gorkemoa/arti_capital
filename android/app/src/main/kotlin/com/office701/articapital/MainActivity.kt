package com.office701.articapital

import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app_group_prefs"
    private var privacyOverlayView: View? = null

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

    override fun onPause() {
        super.onPause()
        addPrivacyOverlay()
    }

    override fun onResume() {
        removePrivacyOverlay()
        super.onResume()
    }

    private fun addPrivacyOverlay() {
        if (privacyOverlayView != null) return
        val decorView = window?.decorView as? ViewGroup ?: return

        val container = FrameLayout(this)
        container.setBackgroundColor(Color.parseColor("#F3EFE6"))

        val icon = ImageView(this)
        icon.setImageResource(R.mipmap.ic_launcher)
        val size = (resources.displayMetrics.widthPixels * 0.60).toInt()
        val lp = FrameLayout.LayoutParams(size, size)
        lp.gravity = Gravity.CENTER
        icon.layoutParams = lp

        container.addView(icon)

        val match = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        decorView.addView(container, match)

        privacyOverlayView = container
    }

    private fun removePrivacyOverlay() {
        val decorView = window?.decorView as? ViewGroup ?: return
        privacyOverlayView?.let { overlay ->
            decorView.removeView(overlay)
        }
        privacyOverlayView = null
    }
}


