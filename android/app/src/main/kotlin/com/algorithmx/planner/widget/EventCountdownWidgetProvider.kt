package com.algorithmx.planner.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import com.algorithmx.planner.MainActivity
import com.algorithmx.planner.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class EventCountdownWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
        scheduleNextUpdate(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            scheduleNextUpdate(context)
        }
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelNextUpdate(context)
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            widgetData: SharedPreferences
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_event_countdown)

            try {
                val timestamp = widgetData.safeGetLong("countdown_event_timestamp", 0L)
                val title = widgetData.getString("countdown_event_title", "") ?: ""
                val hasEventFlag = widgetData.safeGetBoolean("countdown_has_event", false)
                val hasEvent = hasEventFlag && timestamp > 0L && title.isNotEmpty()

                if (!hasEvent) {
                    // Show empty state
                    views.setViewVisibility(R.id.ll_countdown_content, View.GONE)
                    views.setViewVisibility(R.id.ll_countdown_empty, View.VISIBLE)

                    val addEventIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("planner://action/quick_add")
                    )
                    views.setOnClickPendingIntent(R.id.btn_empty_add_event, addEventIntent)
                    views.setOnClickPendingIntent(R.id.widget_countdown_root, addEventIntent)
                } else {
                    // Show content state
                    views.setViewVisibility(R.id.ll_countdown_content, View.VISIBLE)
                    views.setViewVisibility(R.id.ll_countdown_empty, View.GONE)

                    val now = System.currentTimeMillis()
                    val diffMillis = timestamp - now

                    val totalMinutes = (diffMillis / (1000 * 60)).toInt()
                    val totalHours = (diffMillis / (1000 * 60 * 60)).toInt()
                    val totalDays = totalHours / 24
                    val remainingHoursInDay = totalHours % 24
                    val remainingMinutesInHour = totalMinutes % 60

                    if (diffMillis <= 0) {
                        views.setTextViewText(R.id.tv_counter_number, "NOW")
                        views.setTextViewText(R.id.tv_counter_label, "EVENT DUE")
                        views.setTextViewText(R.id.tv_counter_detail, "Event is happening now")
                        views.setTextColor(R.id.tv_counter_number, context.getColor(R.color.priority_high))
                    } else if (totalHours >= 1) {
                        views.setTextViewText(R.id.tv_counter_number, totalHours.toString())
                        views.setTextViewText(
                            R.id.tv_counter_label,
                            if (totalHours == 1) "HOUR LEFT" else "HOURS LEFT"
                        )
                        val detailText = if (totalDays >= 1) {
                            "${totalDays}d ${remainingHoursInDay}h remaining"
                        } else {
                            "${totalHours}h ${remainingMinutesInHour}m remaining"
                        }
                        views.setTextViewText(R.id.tv_counter_detail, detailText)
                        views.setTextColor(R.id.tv_counter_number, context.getColor(R.color.narwhal_primary))
                    } else {
                        // Less than 1 hour remaining
                        val mins = totalMinutes.coerceAtLeast(1)
                        views.setTextViewText(R.id.tv_counter_number, mins.toString())
                        views.setTextViewText(
                            R.id.tv_counter_label,
                            if (mins == 1) "MIN LEFT" else "MINS LEFT"
                        )
                        views.setTextViewText(R.id.tv_counter_detail, "Starts in $mins minutes")
                        views.setTextColor(R.id.tv_counter_number, context.getColor(R.color.priority_high))
                    }

                    views.setTextViewText(R.id.tv_event_title, title)

                    val formattedDate = widgetData.getString("countdown_event_date_formatted", "")
                    val dateText = if (!formattedDate.isNullOrEmpty()) {
                        formattedDate
                    } else {
                        val sdf = SimpleDateFormat("EEE, MMM d • h:mm a", Locale.getDefault())
                        sdf.format(Date(timestamp))
                    }
                    views.setTextViewText(R.id.tv_event_time, dateText)

                    val category = widgetData.getString("countdown_event_category", "EVENT") ?: "EVENT"
                    views.setTextViewText(R.id.tv_event_category, category)

                    // Indicator & Category accent color
                    val colorHex = widgetData.getString("countdown_event_color", "")
                    if (!colorHex.isNullOrEmpty()) {
                        try {
                            val parsedColor = Color.parseColor(
                                if (colorHex.startsWith("#")) colorHex else "#$colorHex"
                            )
                            views.setInt(R.id.v_event_indicator, "setBackgroundColor", parsedColor)
                        } catch (_: Exception) {
                            views.setInt(R.id.v_event_indicator, "setBackgroundColor", context.getColor(R.color.narwhal_primary))
                        }
                    } else {
                        views.setInt(R.id.v_event_indicator, "setBackgroundColor", context.getColor(R.color.narwhal_primary))
                    }

                    // Multiple events cycle indicator
                    val upcomingCount = widgetData.safeGetInt("countdown_upcoming_count", 1)
                    val selectedIndex = widgetData.safeGetInt("countdown_selected_index", 0)
                    if (upcomingCount > 1) {
                        views.setViewVisibility(R.id.btn_cycle_event, View.VISIBLE)
                        views.setTextViewText(R.id.tv_cycle_count, "${selectedIndex + 1}/$upcomingCount ›")

                        val cycleIntent = Intent(context, EventCountdownActionReceiver::class.java).apply {
                            action = EventCountdownActionReceiver.ACTION_CYCLE_EVENT
                        }
                        val flags = if (Build.VERSION.SDK_INT >= 31) {
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        } else {
                            PendingIntent.FLAG_UPDATE_CURRENT
                        }
                        val cyclePendingIntent = PendingIntent.getBroadcast(
                            context,
                            appWidgetId,
                            cycleIntent,
                            flags
                        )
                        views.setOnClickPendingIntent(R.id.btn_cycle_event, cyclePendingIntent)
                    } else {
                        views.setViewVisibility(R.id.btn_cycle_event, View.GONE)
                    }

                    // Click on widget to open the specific event
                    val eventId = widgetData.getString("countdown_event_id", "") ?: ""
                    val openUri = if (eventId.isNotEmpty()) {
                        Uri.parse("planner://task/open?id=$eventId")
                    } else {
                        Uri.parse("planner://calendar")
                    }
                    val openEventIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        openUri
                    )
                    views.setOnClickPendingIntent(R.id.widget_countdown_root, openEventIntent)
                    views.setOnClickPendingIntent(R.id.ll_countdown_content, openEventIntent)
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
                try {
                    val fallbackViews = RemoteViews(context.packageName, R.layout.widget_event_countdown)
                    fallbackViews.setViewVisibility(R.id.ll_countdown_content, View.GONE)
                    fallbackViews.setViewVisibility(R.id.ll_countdown_empty, View.VISIBLE)
                    val addIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("planner://action/quick_add")
                    )
                    fallbackViews.setOnClickPendingIntent(R.id.widget_countdown_root, addIntent)
                    fallbackViews.setOnClickPendingIntent(R.id.btn_empty_add_event, addIntent)
                    appWidgetManager.updateAppWidget(appWidgetId, fallbackViews)
                } catch (_: Exception) {}
            }
        }

        fun scheduleNextUpdate(context: Context) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                val intent = Intent(context, EventCountdownWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val ids = appWidgetManager.getAppWidgetIds(
                        ComponentName(context, EventCountdownWidgetProvider::class.java)
                    )
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                val flags = if (Build.VERSION.SDK_INT >= 31) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getBroadcast(context, 1002, intent, flags)

                // Refresh every 15 minutes to keep countdown hours fresh
                val nextUpdateMillis = System.currentTimeMillis() + 15 * 60 * 1000L
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC, nextUpdateMillis, pendingIntent)
                } else {
                    alarmManager.set(AlarmManager.RTC, nextUpdateMillis, pendingIntent)
                }
            } catch (_: Exception) {}
        }

        fun cancelNextUpdate(context: Context) {
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
                val intent = Intent(context, EventCountdownWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                }
                val flags = if (Build.VERSION.SDK_INT >= 31) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getBroadcast(context, 1002, intent, flags)
                alarmManager.cancel(pendingIntent)
            } catch (_: Exception) {}
        }
    }
}
