package com.example.just_save_gallery

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/**
 * Flutter plugin entry point for just_save_gallery.
 *
 * Routes method channel calls to [GallerySaver] and handles runtime
 * permission requests on Android.
 */
class JustSaveGalleryPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var saver: GallerySaver
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private var pendingCall: MethodCall? = null

    companion object {
        private const val PERMISSION_REQUEST_CODE = 29741
    }

    // region FlutterPlugin

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "just_save_gallery")
        channel.setMethodCallHandler(this)
        saver = GallerySaver(binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // endregion

    // region ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // endregion

    // region MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "saveBytes", "saveFile" -> handleSave(call, result)
            else -> result.notImplemented()
        }
    }

    // endregion

    /**
     * Handles both `saveBytes` and `saveFile` method calls.
     *
     * If [requestPermission] is true and the required permission has not been
     * granted, this stores the pending call and requests permission. The actual
     * save is performed either immediately or after the permission callback.
     */
    private fun handleSave(call: MethodCall, result: Result) {
        val requestPermission = call.argument<Boolean>("requestPermission") ?: true

        if (requestPermission && needsPermission() && !hasPermission()) {
            pendingResult = result
            pendingCall = call
            requestPermission()
            return
        }

        executeSave(call, result)
    }

    /**
     * Executes the actual save operation by delegating to [GallerySaver].
     */
    private fun executeSave(call: MethodCall, result: Result) {
        try {
            val name = call.argument<String>("name")!!
            val albumName = call.argument<String>("albumName")
            val isVideo = call.argument<String>("mediaType") == "video"

            val uri = when (call.method) {
                "saveBytes" -> {
                    val bytes = call.argument<ByteArray>("bytes")!!
                    saver.saveBytes(bytes, name, albumName, isVideo)
                }
                "saveFile" -> {
                    val filePath = call.argument<String>("filePath")!!
                    saver.saveFile(filePath, name, albumName, isVideo)
                }
                else -> {
                    result.notImplemented()
                    return
                }
            }

            result.success(uri)
        } catch (e: GallerySaver.FileNotFoundException) {
            result.error("FILE_NOT_FOUND", e.message, null)
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", e.message, null)
        } catch (e: java.io.IOException) {
            // Check for common disk-full indicators
            val msg = e.message?.lowercase() ?: ""
            if (msg.contains("no space") || msg.contains("enospc")) {
                result.error("DISK_FULL", e.message, null)
            } else {
                result.error("UNKNOWN", e.message, null)
            }
        } catch (e: Exception) {
            result.error("UNKNOWN", e.message, null)
        }
    }

    // region Permissions

    /**
     * Returns true if runtime permission is needed for the current API level.
     * Android 10 (API 29)+ uses scoped storage and does not require
     * WRITE_EXTERNAL_STORAGE for MediaStore inserts.
     */
    private fun needsPermission(): Boolean {
        return Build.VERSION.SDK_INT <= Build.VERSION_CODES.P
    }

    private fun hasPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            activity ?: return false,
            Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermission() {
        activity?.let {
            ActivityCompat.requestPermissions(
                it,
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                PERMISSION_REQUEST_CODE
            )
        } ?: run {
            pendingResult?.error("PERMISSION_DENIED", "No activity available to request permission", null)
            clearPending()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false

        val call = pendingCall ?: return false
        val result = pendingResult ?: return false

        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            executeSave(call, result)
        } else {
            result.error("PERMISSION_DENIED", "Storage permission denied by user", null)
        }

        clearPending()
        return true
    }

    private fun clearPending() {
        pendingResult = null
        pendingCall = null
    }

    // endregion
}
