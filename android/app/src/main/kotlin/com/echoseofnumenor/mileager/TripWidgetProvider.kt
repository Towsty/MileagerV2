package com.echoseofnumenor.mileager

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class TripWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.trip_widget).apply {
                // Get data from shared preferences (set by Flutter)
                val tripStatus = widgetData.getString("trip_status", "Not Active") ?: "Not Active"
                val tripDistance = widgetData.getString("trip_distance", "0.0 mi") ?: "0.0 mi"
                val tripDuration = widgetData.getString("trip_duration", "00:00") ?: "00:00"
                val vehicleName = widgetData.getString("vehicle_name", "No Vehicle") ?: "No Vehicle"
                val isPaused = widgetData.getBoolean("is_paused", false)

                // Update widget text views
                setTextViewText(R.id.trip_status, tripStatus)
                setTextViewText(R.id.trip_distance, tripDistance)
                setTextViewText(R.id.trip_duration, tripDuration)
                setTextViewText(R.id.vehicle_name, vehicleName)

                // Set up click intents for buttons
                val startStopIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("widget://trip/toggle")
                )
                setOnClickPendingIntent(R.id.start_stop_button, startStopIntent)

                val pauseResumeIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("widget://trip/pause")
                )
                setOnClickPendingIntent(R.id.pause_resume_button, pauseResumeIntent)

                // Update button text based on trip state
                if (tripStatus == "Active") {
                    setTextViewText(R.id.start_stop_button, "Stop")
                    setTextViewText(R.id.pause_resume_button, if (isPaused) "Resume" else "Pause")
                } else {
                    setTextViewText(R.id.start_stop_button, "Start")
                    setTextViewText(R.id.pause_resume_button, "Pause")
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
} 