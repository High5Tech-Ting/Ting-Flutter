package com.example.ting

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.util.Log

/**
 * Implementation of App Widget functionality.
 */
class EventReminder : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    try {
        // Construct the RemoteViews object
        val views = RemoteViews(context.packageName, R.layout.event_reminder)
        
        // Set default values for the event reminder widget
        views.setTextViewText(R.id.event_title, "Upcoming Event")
        views.setTextViewText(R.id.event_date, "Loading...")
        views.setTextViewText(R.id.days_count, "0")
        views.setTextViewText(R.id.hours_count, "0")
        views.setTextViewText(R.id.minutes_count, "0")
        views.setTextViewText(R.id.seconds_count, "0")

        // Instruct the widget manager to update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    } catch (e: Exception) {
        // Log the error for debugging
        android.util.Log.e("EventReminder", "Error updating widget", e)
        
        // Create a simple fallback widget using built-in layout
        try {
            val errorViews = RemoteViews(context.packageName, android.R.layout.simple_list_item_2)
            errorViews.setTextViewText(android.R.id.text1, "Event Reminder")
            errorViews.setTextViewText(android.R.id.text2, "Widget Loading Error")
            appWidgetManager.updateAppWidget(appWidgetId, errorViews)
        } catch (fallbackError: Exception) {
            // Last resort fallback - log the error
            android.util.Log.e("EventReminder", "Failed to create fallback widget", fallbackError)
        }
    }
}