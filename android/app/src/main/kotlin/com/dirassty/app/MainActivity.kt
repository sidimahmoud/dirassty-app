package com.dirassty.app

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.graphics.Color
import android.os.Build
import android.content.pm.ApplicationInfo
import android.content.Context
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        // Blocks screenshots, screen recording/casting and the recent-apps
        // thumbnail from the very first frame (ScreenCaptureGuard re-applies
        // the same flag from Dart). Release builds only: the emulator's
        // mirrored screen is itself a capture, so with FLAG_SECURE a debug
        // build just shows black there.
        val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!isDebuggable) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
    }

    // The "Dirassty" channel every push uses (FCM messages name it, see
    // supabase/functions/_shared/fcm.ts). High importance so notifications
    // show as a heads-up banner with sound. Re-creating it is a no-op.
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "dirassty_default",
            "Dirassty",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Examens, séries, abonnement et annonces de Dirassty"
            enableLights(true)
            lightColor = Color.parseColor("#0E6B5C")
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Parental focus mode (lib/features/focus/data/focus_lock_platform.dart):
        // screen pinning keeps the student inside the app during a
        // parent-set window. Without device-owner provisioning Android
        // treats this as user-visible "app pinning", not a hard kiosk.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ai.dirassty/focus_lock")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pin" -> {
                        try {
                            startLockTask()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("pin_failed", e.message, null)
                        }
                    }
                    "unpin" -> {
                        try {
                            stopLockTask()
                        } catch (_: Exception) {
                            // Not pinned — nothing to undo.
                        }
                        result.success(null)
                    }
                    "isLocked" -> {
                        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        result.success(am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
