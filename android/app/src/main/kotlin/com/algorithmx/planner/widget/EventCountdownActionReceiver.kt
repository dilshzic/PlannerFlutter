package com.algorithmx.planner.widget

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class EventCountdownActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_CYCLE_EVENT = "com.algorithmx.planner.ACTION_CYCLE_EVENT"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_CYCLE_EVENT) {
            val prefs = HomeWidgetPlugin.getData(context)
            val jsonStr = prefs.getString("countdown_events_json", "[]") ?: "[]"
            try {
                val array = JSONArray(jsonStr)
                if (array.length() > 1) {
                    val currentIndex = prefs.safeGetInt("countdown_selected_index", 0)
                    val nextIndex = (currentIndex + 1) % array.length()
                    val event = array.getJSONObject(nextIndex)
                    val timestamp = event.optLong("timestamp")

                    prefs.edit()
                        .putInt("countdown_selected_index", nextIndex)
                        .putString("countdown_event_id", event.optString("id"))
                        .putString("countdown_event_title", event.optString("title"))
                        .putLong("countdown_event_timestamp", timestamp)
                        .putString("countdown_event_timestamp_str", timestamp.toString())
                        .putString("countdown_event_date_formatted", event.optString("dateFormatted"))
                        .putString("countdown_event_category", event.optString("category"))
                        .putString("countdown_event_color", event.optString("colorHex"))
                        .apply()

                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val ids = appWidgetManager.getAppWidgetIds(
                        ComponentName(context, EventCountdownWidgetProvider::class.java)
                    )
                    for (id in ids) {
                        EventCountdownWidgetProvider.updateWidget(context, appWidgetManager, id, prefs)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
