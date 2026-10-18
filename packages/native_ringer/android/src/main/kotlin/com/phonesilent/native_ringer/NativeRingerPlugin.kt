package com.phonesilent.native_ringer

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Ringer / DND control backed by [AudioManager] and [NotificationManager].
 *
 * Deliberately uses the *application context* (not an Activity), so every method
 * works when invoked from the geofence background isolate where no Activity
 * exists.
 *
 * Wire values for ringer mode match [AudioManager]: SILENT=0, VIBRATE=1,
 * NORMAL=2, and -1 for unknown.
 */
class NativeRingerPlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "native_ringer")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private val audioManager: AudioManager
        get() = appContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private val notificationManager: NotificationManager
        get() =
            appContext.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isSupported" -> result.success(true)

            // Milliseconds since boot. Used to tell "the user changed the
            // ringer" apart from "the device rebooted and reset it".
            "elapsedRealtime" -> result.success(android.os.SystemClock.elapsedRealtime())

            "isDndAccessGranted" ->
                result.success(notificationManager.isNotificationPolicyAccessGranted)

            "openDndSettings" -> {
                val intent =
                    Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                appContext.startActivity(intent)
                result.success(null)
            }

            "capture" -> {
                val ringer = ringerModeToWire(audioManager.ringerMode)
                val dnd = isDndActive()
                result.success(mapOf("ringerMode" to ringer, "dndEnabled" to dnd))
            }

            "applyState" -> {
                val ringerWire = call.argument<Int>("ringerMode") ?: -1
                val dndEnabled = call.argument<Boolean>("dndEnabled") ?: false
                try {
                    applyState(ringerWire, dndEnabled)
                    result.success(null)
                } catch (e: SecurityException) {
                    // Thrown when DND policy access hasn't been granted.
                    result.error("dnd_access_denied", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Drives the device to an absolute state. Order matters: clear any active
     * interruption filter first so the ringer-mode change is honoured, set the
     * ringer mode, then (re)apply DND if requested. Setting the ringer mode to
     * silent/vibrate while DND is active can otherwise be ignored by the OS.
     */
    private fun applyState(ringerWire: Int, dndEnabled: Boolean) {
        val hasDndAccess = notificationManager.isNotificationPolicyAccessGranted

        if (hasDndAccess) {
            notificationManager.setInterruptionFilter(
                NotificationManager.INTERRUPTION_FILTER_ALL,
            )
        }

        val ringerMode = wireToRingerMode(ringerWire)
        if (ringerMode != null) {
            audioManager.ringerMode = ringerMode
        }

        if (dndEnabled && hasDndAccess) {
            notificationManager.setInterruptionFilter(
                NotificationManager.INTERRUPTION_FILTER_PRIORITY,
            )
        }
    }

    private fun isDndActive(): Boolean {
        if (!notificationManager.isNotificationPolicyAccessGranted) return false
        val filter = notificationManager.currentInterruptionFilter
        return filter != NotificationManager.INTERRUPTION_FILTER_ALL &&
            filter != NotificationManager.INTERRUPTION_FILTER_UNKNOWN
    }

    private fun ringerModeToWire(mode: Int): Int =
        when (mode) {
            AudioManager.RINGER_MODE_SILENT -> 0
            AudioManager.RINGER_MODE_VIBRATE -> 1
            AudioManager.RINGER_MODE_NORMAL -> 2
            else -> -1
        }

    private fun wireToRingerMode(wire: Int): Int? =
        when (wire) {
            0 -> AudioManager.RINGER_MODE_SILENT
            1 -> AudioManager.RINGER_MODE_VIBRATE
            2 -> AudioManager.RINGER_MODE_NORMAL
            else -> null
        }
}
