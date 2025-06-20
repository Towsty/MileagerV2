package com.echoseofnumenor.mileager

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class LocationService : Service() {
    private var fusedLocationClient: FusedLocationProviderClient? = null
    private var locationCallback: LocationCallback? = null
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        const val CHANNEL_ID = "location_service_channel"
        const val NOTIFICATION_ID = 1
        var methodChannel: MethodChannel? = null
        var eventChannel: EventChannel? = null
    }

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startLocationUpdates()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Location Service Channel",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Used for location tracking notifications"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("Tracking Location")
        .setContentText("Location tracking is active")
        .setSmallIcon(R.drawable.ic_notification)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .build()

    private fun startLocationUpdates() {
        val locationRequest = LocationRequest.Builder(10000) // 10 seconds
            .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
            .setMinUpdateIntervalMillis(5000) // 5 seconds
            .build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    val locationMap = mapOf(
                        "latitude" to location.latitude,
                        "longitude" to location.longitude,
                        "accuracy" to location.accuracy,
                        "altitude" to location.altitude,
                        "speed" to location.speed,
                        "time" to location.time,
                        "bearing" to location.bearing
                    )
                    methodChannel?.invokeMethod("locationUpdate", locationMap)
                    eventSink?.success(locationMap)
                }
            }
        }

        try {
            fusedLocationClient?.requestLocationUpdates(
                locationRequest,
                locationCallback!!,
                Looper.getMainLooper()
            )
        } catch (e: SecurityException) {
            stopSelf()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        fusedLocationClient?.removeLocationUpdates(locationCallback!!)
        eventSink = null
    }
} 