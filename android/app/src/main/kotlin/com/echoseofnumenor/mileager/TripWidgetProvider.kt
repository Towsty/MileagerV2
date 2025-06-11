package com.echoseofnumenor.mileager

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class TripWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.trip_widget)

            // Update text views
            val tripStatus = widgetData.getString("trip_status", "No Active Trip")
            val tripDistance = widgetData.getString("trip_distance", "0.0 mi")
            val tripDuration = widgetData.getString("trip_duration", "00:00")
            val vehicleName = widgetData.getString("vehicle_name", "No Vehicle")
            val isPaused = widgetData.getBoolean("is_paused", false)

            views.setTextViewText(R.id.trip_status, tripStatus)
            views.setTextViewText(R.id.trip_distance, tripDistance)
            views.setTextViewText(R.id.trip_duration, tripDuration)
            views.setTextViewText(R.id.vehicle_name, vehicleName)

            // Update pause/resume button text
            if (isPaused) {
                views.setTextViewText(R.id.pause_resume_button, "Resume")
            } else {
                views.setTextViewText(R.id.pause_resume_button, "Pause")
            }

            // Set up button click intents
            val startIntent = Intent(context, TripWidgetProvider::class.java).apply {
                action = "WIDGET_CLICK"
                data = Uri.parse("widget://click?action=start_trip")
            }
            val startPendingIntent = PendingIntent.getBroadcast(
                context, 0, startIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.start_button, startPendingIntent)

            val stopIntent = Intent(context, TripWidgetProvider::class.java).apply {
                action = "WIDGET_CLICK"
                data = Uri.parse("widget://click?action=stop_trip")
            }
            val stopPendingIntent = PendingIntent.getBroadcast(
                context, 1, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.stop_button, stopPendingIntent)

            val pauseResumeAction = if (isPaused) "resume_trip" else "pause_trip"
            val pauseResumeIntent = Intent(context, TripWidgetProvider::class.java).apply {
                action = "WIDGET_CLICK"
                data = Uri.parse("widget://click?action=$pauseResumeAction")
            }
            val pauseResumePendingIntent = PendingIntent.getBroadcast(
                context, 2, pauseResumeIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.pause_resume_button, pauseResumePendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        if (intent.action == "WIDGET_CLICK") {
            val uri = intent.data
            if (uri != null) {
                HomeWidgetPlugin.widgetClicked(context, uri)
            }
        }
    }
} 