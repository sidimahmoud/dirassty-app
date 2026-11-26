package com.dirassti.app

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.graphics.Color
import android.os.Build
import android.content.Context
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Edge-to-edge on every Android version (the default from Android 15
        // / SDK 35): the app draws behind the status and navigation bars
        // with transparent bars; Flutter keeps content out of them
        // (SafeArea, SystemUiMode.edgeToEdge in lib/app/bootstrap.dart).
        WindowCompat.enableEdgeToEdge(window)
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        // No FLAG_SECURE here: screenshots are blocked only on the learning
        // screens (lessons, videos, QCM, exams), turned on and off from Dart
        // — see lib/core/security/screen_capture_guard.dart.
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
