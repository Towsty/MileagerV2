package com.mileager

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.app.UiModeManager
import android.content.res.Configuration
import android.app.ActivityManager
import android.util.Log

class MainActivity: FlutterActivity() {
    private val ANDROID_AUTO_CHANNEL = "com.mileager/android_auto"
    private val ANDROID_AUTO_EVENT_CHANNEL = "com.mileager/android_auto_events"
    
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    
    private var isAndroidAutoConnected = false
    
    private val androidAutoReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                "android.car.intent.action.MEDIA_TEMPLATE" -> {
                    Log.d("AutoTracking", "Android Auto connected via broadcast")
                    updateAndroidAutoStatus(true)
                }
                "android.intent.action.MEDIA_BUTTON" -> {
                    Log.d("AutoTracking", "Media button pressed - checking Auto status")
                    checkAndroidAutoStatus()
                }
                Intent.ACTION_CONFIGURATION_CHANGED -> {
                    Log.d("AutoTracking", "Configuration changed - checking Auto status")
                    checkAndroidAutoStatus()
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d("AutoTracking", "Configuring Flutter engine with platform channels")
        
        // Method channel for checking Android Auto status
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ANDROID_AUTO_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            Log.d("AutoTracking", "Received method call: ${call.method}")
            when (call.method) {
                "isAndroidAutoConnected" -> {
                    Log.d("AutoTracking", "Returning Android Auto status: $isAndroidAutoConnected")
                    result.success(isAndroidAutoConnected)
                }
                else -> {
                    Log.d("AutoTracking", "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
        
        // Event channel for Android Auto connection changes
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, ANDROID_AUTO_EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                Log.d("AutoTracking", "Event channel listener attached")
                eventSink = events
            }
            
            override fun onCancel(arguments: Any?) {
                Log.d("AutoTracking", "Event channel listener cancelled")
                eventSink = null
            }
        })
        
        Log.d("AutoTracking", "Platform channels configured, initializing detection")
        initializeAndroidAutoDetection()
    }
    
    private fun initializeAndroidAutoDetection() {
        try {
            // Register broadcast receiver for Android Auto events
            val filter = IntentFilter().apply {
                addAction("android.car.intent.action.MEDIA_TEMPLATE")
                addAction("android.intent.action.MEDIA_BUTTON")
                addAction(Intent.ACTION_CONFIGURATION_CHANGED)
                addAction("android.car.intent.action.TEMPLATE_RENDERER_STATE_CHANGED")
            }
            registerReceiver(androidAutoReceiver, filter)
            
            // Initial status check
            checkAndroidAutoStatus()
            
            Log.d("AutoTracking", "Android Auto detection initialized")
        } catch (e: Exception) {
            Log.w("AutoTracking", "Failed to initialize Android Auto detection: ${e.message}")
        }
    }
    
    private fun checkAndroidAutoStatus() {
        try {
            var isConnected = false
            
            // Method 1: Check UI mode (Android Auto changes UI mode to car)
            val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
            val isCarMode = uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_CAR
            
            // Method 2: Check if Android Auto process is running
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningApps = activityManager.runningAppProcesses
            val isAndroidAutoRunning = runningApps?.any { 
                it.processName.contains("gearhead") || 
                it.processName.contains("android.car") ||
                it.processName.contains("projection")
            } ?: false
            
            // Method 3: Check if Android Auto package is installed and active
            val packageManager = packageManager
            var isAndroidAutoInstalled = false
            try {
                packageManager.getPackageInfo("com.google.android.projection.gearhead", 0)
                isAndroidAutoInstalled = true
            } catch (e: PackageManager.NameNotFoundException) {
                // Android Auto not installed
            }
            
            // Combine detection methods
            isConnected = isCarMode || (isAndroidAutoRunning && isAndroidAutoInstalled)
            
            Log.d("AutoTracking", "Status check - CarMode: $isCarMode, AutoRunning: $isAndroidAutoRunning, AutoInstalled: $isAndroidAutoInstalled, Final: $isConnected")
            
            if (isConnected != isAndroidAutoConnected) {
                updateAndroidAutoStatus(isConnected)
            }
            
        } catch (e: Exception) {
            Log.w("AutoTracking", "Error checking Android Auto status: ${e.message}")
        }
    }
    
    private fun updateAndroidAutoStatus(connected: Boolean) {
        if (isAndroidAutoConnected != connected) {
            isAndroidAutoConnected = connected
            Log.d("AutoTracking", "Android Auto status changed: $connected")
            
            // Notify Flutter
            eventSink?.success(connected)
        }
    }
    
    override fun onResume() {
        super.onResume()
        // Check Android Auto status when app resumes
        checkAndroidAutoStatus()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(androidAutoReceiver)
        } catch (e: Exception) {
            Log.w("AutoTracking", "Error unregistering receiver: ${e.message}")
        }
    }
} 