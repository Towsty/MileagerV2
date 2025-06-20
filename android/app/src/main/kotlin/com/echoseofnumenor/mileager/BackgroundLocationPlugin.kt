package com.echoseofnumenor.mileager

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class BackgroundLocationPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "background_location_plugin")
        methodChannel.setMethodCallHandler(this)
        LocationService.methodChannel = methodChannel

        eventChannel = EventChannel(binding.binaryMessenger, "background_location_events")
        LocationService.eventChannel = eventChannel
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        LocationService.methodChannel = null
        LocationService.eventChannel = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startLocationService" -> {
                val intent = Intent(context, LocationService::class.java)
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                result.success(null)
            }
            "stopLocationService" -> {
                context.stopService(Intent(context, LocationService::class.java))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
} 