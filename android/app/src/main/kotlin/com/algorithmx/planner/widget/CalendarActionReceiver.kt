package com.algorithmx.planner.widget

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin

class CalendarActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_PREV_MONTH = "com.algorithmx.planner.ACTION_PREV_MONTH"
        const val ACTION_NEXT_MONTH = "com.algorithmx.planner.ACTION_NEXT_MONTH"
        const val ACTION_RESET_MONTH = "com.algorithmx.planner.ACTION_RESET_MONTH"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = HomeWidgetPlugin.getData(context)
        val currentOffset = prefs.safeGetInt("calendar_month_offset", 0)

        when (intent.action) {
            ACTION_PREV_MONTH -> {
                prefs.edit().putInt("calendar_month_offset", currentOffset - 1).apply()
            }
            ACTION_NEXT_MONTH -> {
                prefs.edit().putInt("calendar_month_offset", currentOffset + 1).apply()
            }
            ACTION_RESET_MONTH -> {
                prefs.edit().putInt("calendar_month_offset", 0).apply()
            }
            else -> return
        }

        val appWidgetManager = AppWidgetManager.getInstance(context)
        val ids = appWidgetManager.getAppWidgetIds(
            ComponentName(context, CalendarWidgetProvider::class.java)
        )
        for (id in ids) {
            CalendarWidgetProvider.updateWidget(context, appWidgetManager, id, prefs)
        }
    }
}
