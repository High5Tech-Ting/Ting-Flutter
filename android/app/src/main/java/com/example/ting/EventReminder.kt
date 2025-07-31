package com.example.ting

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.util.Log
import android.os.SystemClock

/**
 * Implementation of App Widget functionality.
 */
class EventReminder : AppWidgetProvider() {
    
    companion object {
        private const val ACTION_AUTO_UPDATE = "AUTO_UPDATE"
        private const val UPDATE_INTERVAL = 1000L // 1 second
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        
        // Set up auto-update alarm
        setUpdateAlarm(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        if (ACTION_AUTO_UPDATE == intent.action) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, EventReminder::class.java)
            )
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
        setUpdateAlarm(context)
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
        cancelUpdateAlarm(context)
    }
    
    private fun setUpdateAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, EventReminder::class.java).apply {
            action = ACTION_AUTO_UPDATE
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context, 0, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Cancel any existing alarm
        alarmManager.cancel(pendingIntent)
        
        // Set repeating alarm for every second
        alarmManager.setRepeating(
            AlarmManager.ELAPSED_REALTIME,
            SystemClock.elapsedRealtime() + UPDATE_INTERVAL,
            UPDATE_INTERVAL,
            pendingIntent
        )
    }
    
    private fun cancelUpdateAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, EventReminder::class.java).apply {
            action = ACTION_AUTO_UPDATE
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context, 0, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        alarmManager.cancel(pendingIntent)
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    try {
        // Get shared preferences - try both common locations
        val homeWidgetPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        // Debug: Log all available keys from both preference files
        Log.d("EventReminder", "HomeWidget SharedPreferences keys:")
        val homeWidgetEntries = homeWidgetPrefs.all
        for ((key, value) in homeWidgetEntries) {
            Log.d("EventReminder", "HomeWidget Key: $key, Value: $value")
        }
        
        Log.d("EventReminder", "Flutter SharedPreferences keys:")
        val flutterEntries = flutterPrefs.all
        for ((key, value) in flutterEntries) {
            Log.d("EventReminder", "Flutter Key: $key, Value: $value")
        }
        
        // Try to read from home_widget preferences first (most likely location)
        var eventTitle = homeWidgetPrefs.getString("event_title", null)
            ?: flutterPrefs.getString("flutter.event_title", null)
            ?: flutterPrefs.getString("event_title", null)
            ?: "No Active Event"
            
        var eventDate = homeWidgetPrefs.getString("event_date", null)
            ?: flutterPrefs.getString("flutter.event_date", null)
            ?: flutterPrefs.getString("event_date", null)
            ?: "Select an event"
            
        var daysCount = homeWidgetPrefs.getString("days_count", null)
            ?: flutterPrefs.getString("flutter.days_count", null)
            ?: flutterPrefs.getString("days_count", null)
            ?: "0"
            
        var hoursCount = homeWidgetPrefs.getString("hours_count", null)
            ?: flutterPrefs.getString("flutter.hours_count", null)
            ?: flutterPrefs.getString("hours_count", null)
            ?: "00"
            
        var minutesCount = homeWidgetPrefs.getString("minutes_count", null)
            ?: flutterPrefs.getString("flutter.minutes_count", null)
            ?: flutterPrefs.getString("minutes_count", null)
            ?: "00"
            
        var secondsCount = homeWidgetPrefs.getString("seconds_count", null)
            ?: flutterPrefs.getString("flutter.seconds_count", null)
            ?: flutterPrefs.getString("seconds_count", null)
            ?: "00"
        
        Log.d("EventReminder", "Final values - Title: $eventTitle, Date: $eventDate, Time: $daysCount:$hoursCount:$minutesCount:$secondsCount")
        
        // Construct the RemoteViews object
        val views = RemoteViews(context.packageName, R.layout.event_reminder)
        
        // Set values from shared preferences
        views.setTextViewText(R.id.event_title, eventTitle)
        views.setTextViewText(R.id.event_date, eventDate)
        views.setTextViewText(R.id.days_count, daysCount)
        views.setTextViewText(R.id.hours_count, hoursCount)
        views.setTextViewText(R.id.minutes_count, minutesCount)
        views.setTextViewText(R.id.seconds_count, secondsCount)

        // Instruct the widget manager to update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
        
        Log.d("EventReminder", "Widget updated: $eventTitle - $daysCount:$hoursCount:$minutesCount:$secondsCount")
        
    } catch (e: Exception) {
        // Log the error for debugging
        Log.e("EventReminder", "Error updating widget", e)
        
        // Create a simple fallback widget
        try {
            val views = RemoteViews(context.packageName, R.layout.event_reminder)
            views.setTextViewText(R.id.event_title, "Event Reminder")
            views.setTextViewText(R.id.event_date, "Widget Loading Error")
            views.setTextViewText(R.id.days_count, "0")
            views.setTextViewText(R.id.hours_count, "00")
            views.setTextViewText(R.id.minutes_count, "00")
            views.setTextViewText(R.id.seconds_count, "00")
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (fallbackError: Exception) {
            Log.e("EventReminder", "Failed to create fallback widget", fallbackError)
        }
    }
}