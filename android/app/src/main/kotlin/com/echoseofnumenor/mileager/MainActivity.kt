package com.echoseofnumenor.mileager

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.pm.PackageManager
import android.content.Intent
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mileager/android_auto"
    private val TAG = "MileagerMainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAndroidAutoConnected" -> {
                    try {
                        val isConnected = isAndroidAutoConnected()
                        Log.d(TAG, "🚗 Android Auto check result: $isConnected")
                        result.success(isConnected)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error checking Android Auto status: ${e.message}")
                        result.error("ANDROID_AUTO_ERROR", "Failed to check Android Auto status", e.message)
                    }
                }
                else -> {
                    Log.w(TAG, "⚠️ Unknown method called: ${call.method}")
                    result.notImplemented()
                }
            }
        }
        
        Log.i(TAG, "✅ Android Auto platform channel registered successfully")
    }

    private fun isAndroidAutoConnected(): Boolean {
        return try {
            // Method 1: Check if Android Auto app is running
            val autoRunning = isAndroidAutoAppRunning()
            
            // Method 2: Check for Android Auto service connections
            val serviceConnected = checkAndroidAutoServices()
            
            // Method 3: Check automotive projection manager (Android 9+)
            val projectionActive = checkAutomotiveProjection()
            
            val result = autoRunning || serviceConnected || projectionActive
            
            Log.d(TAG, "🔍 Android Auto detection: app=$autoRunning, service=$serviceConnected, projection=$projectionActive, final=$result")
            
            result
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception in Android Auto detection: ${e.message}")
            false
        }
    }

            private fun isAndroidAutoAppRunning(): Boolean {
        return try {
            val packageManager = packageManager
            val androidAutoPackage = "com.google.android.projection.gearhead"
            
            // Check if Android Auto package is installed
            val isInstalled = try {
                val packageInfo = packageManager.getPackageInfo(androidAutoPackage, 0)
                Log.d(TAG, "📱 Android Auto app is installed: ${packageInfo.versionName}")
                true
            } catch (e: PackageManager.NameNotFoundException) {
                Log.d(TAG, "📱 Android Auto app not installed")
                false
            }
            
            if (!isInstalled) return false
            
            // Check if Android Auto is currently running
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val runningApps = activityManager.runningAppProcesses
            
            val isRunning = runningApps?.any { it.processName.contains(androidAutoPackage) } ?: false
            Log.d(TAG, "🏃 Android Auto app running: $isRunning")
            
            isRunning
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking Android Auto app: ${e.message}")
            false
        }
    }

    private fun checkAndroidAutoServices(): Boolean {
        return try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val runningServices = activityManager.getRunningServices(Integer.MAX_VALUE)
            
            val autoServices = runningServices.filter { service ->
                val serviceName = service.service.className
                serviceName.contains("android.projection") || 
                serviceName.contains("gearhead") || 
                serviceName.contains("CarService") ||
                serviceName.contains("automotive")
            }
            
            val hasAutoServices = autoServices.isNotEmpty()
            Log.d(TAG, "🔧 Android Auto services found: $hasAutoServices (${autoServices.size} services)")
            
            if (hasAutoServices) {
                autoServices.forEach { service ->
                    Log.d(TAG, "   - Service: ${service.service.className}")
                }
            }
            
            hasAutoServices
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking Android Auto services: ${e.message}")
            false
        }
    }

    private fun checkAutomotiveProjection(): Boolean {
        return try {
            // Android 9+ method - check UiModeManager for automotive mode
            val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as android.app.UiModeManager
            val isCarMode = uiModeManager.currentModeType == android.content.res.Configuration.UI_MODE_TYPE_CAR
            
            Log.d(TAG, "🚗 Automotive UI mode active: $isCarMode")
            
            isCarMode
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking automotive projection: ${e.message}")
            false
        }
    }
} 