package com.algorithmx.planner.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import com.algorithmx.planner.MainActivity
import com.algorithmx.planner.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class CalendarWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    companion object {
        private val CELL_IDS = arrayOf(
            intArrayOf(R.id.day_0_0, R.id.day_0_1, R.id.day_0_2, R.id.day_0_3, R.id.day_0_4, R.id.day_0_5, R.id.day_0_6),
            intArrayOf(R.id.day_1_0, R.id.day_1_1, R.id.day_1_2, R.id.day_1_3, R.id.day_1_4, R.id.day_1_5, R.id.day_1_6),
            intArrayOf(R.id.day_2_0, R.id.day_2_1, R.id.day_2_2, R.id.day_2_3, R.id.day_2_4, R.id.day_2_5, R.id.day_2_6),
            intArrayOf(R.id.day_3_0, R.id.day_3_1, R.id.day_3_2, R.id.day_3_3, R.id.day_3_4, R.id.day_3_5, R.id.day_3_6),
            intArrayOf(R.id.day_4_0, R.id.day_4_1, R.id.day_4_2, R.id.day_4_3, R.id.day_4_4, R.id.day_4_5, R.id.day_4_6),
            intArrayOf(R.id.day_5_0, R.id.day_5_1, R.id.day_5_2, R.id.day_5_3, R.id.day_5_4, R.id.day_5_5, R.id.day_5_6)
        )

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            widgetData: SharedPreferences
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_calendar)

            try {
                val monthOffset = widgetData.safeGetInt("calendar_month_offset", 0)
                val cal = Calendar.getInstance()
                if (monthOffset != 0) {
                    cal.add(Calendar.MONTH, monthOffset)
                }

                val displayYear = cal.get(Calendar.YEAR)
                val displayMonth = cal.get(Calendar.MONTH) // 0-based

                // Month header: e.g. "October 2026"
                val monthFormat = SimpleDateFormat("MMMM yyyy", Locale.getDefault())
                views.setTextViewText(R.id.tv_calendar_month_year, monthFormat.format(cal.time))

                // Navigation PendingIntents
                val flags = if (Build.VERSION.SDK_INT >= 31) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                val prevIntent = Intent(context, CalendarActionReceiver::class.java).apply {
                    action = CalendarActionReceiver.ACTION_PREV_MONTH
                }
                views.setOnClickPendingIntent(
                    R.id.btn_calendar_prev,
                    PendingIntent.getBroadcast(context, 2001, prevIntent, flags)
                )

                val nextIntent = Intent(context, CalendarActionReceiver::class.java).apply {
                    action = CalendarActionReceiver.ACTION_NEXT_MONTH
                }
                views.setOnClickPendingIntent(
                    R.id.btn_calendar_next,
                    PendingIntent.getBroadcast(context, 2002, nextIntent, flags)
                )

                val todayIntent = Intent(context, CalendarActionReceiver::class.java).apply {
                    action = CalendarActionReceiver.ACTION_RESET_MONTH
                }
                views.setOnClickPendingIntent(
                    R.id.btn_calendar_today,
                    PendingIntent.getBroadcast(context, 2003, todayIntent, flags)
                )

                // Setup Calendar Grid
                cal.set(Calendar.DAY_OF_MONTH, 1)
                val firstDayOfWeek = cal.get(Calendar.DAY_OF_WEEK) // 1 = Sunday
                val daysInCurrentMonth = cal.getActualMaximum(Calendar.DAY_OF_MONTH)

                cal.add(Calendar.MONTH, -1)
                val daysInPrevMonth = cal.getActualMaximum(Calendar.DAY_OF_MONTH)
                cal.add(Calendar.MONTH, 1) // restore to display month

                val todayCal = Calendar.getInstance()
                val todayYear = todayCal.get(Calendar.YEAR)
                val todayMonth = todayCal.get(Calendar.MONTH)
                val todayDay = todayCal.get(Calendar.DAY_OF_MONTH)

                val taskDaysStr = widgetData.getString("calendar_task_days", "") ?: ""
                val taskDaysSet = taskDaysStr.split(",").filter { it.isNotEmpty() }.toSet()

                val startOffset = firstDayOfWeek - 1 // Sunday = 0

                for (i in 0 until 42) {
                    val row = i / 7
                    val col = i % 7
                    val cellId = CELL_IDS[row][col]

                    if (i < startOffset) {
                        // Day from previous month
                        val dayNum = daysInPrevMonth - startOffset + 1 + i
                        views.setTextViewText(cellId, dayNum.toString())
                        views.setTextColor(cellId, context.getColor(R.color.narwhal_text_muted))
                        views.setInt(cellId, "setBackgroundResource", 0)
                    } else if (i < startOffset + daysInCurrentMonth) {
                        // Day in current display month
                        val dayNum = i - startOffset + 1
                        views.setTextViewText(cellId, dayNum.toString())

                        val dateKey = String.format(Locale.US, "%04d-%02d-%02d", displayYear, displayMonth + 1, dayNum)
                        val isToday = (displayYear == todayYear && displayMonth == todayMonth && dayNum == todayDay)

                        if (isToday) {
                            views.setTextColor(cellId, context.getColor(R.color.narwhal_surface))
                            views.setInt(cellId, "setBackgroundResource", R.drawable.widget_today_circle)
                        } else if (taskDaysSet.contains(dateKey)) {
                            views.setTextColor(cellId, context.getColor(R.color.narwhal_primary))
                            views.setInt(cellId, "setBackgroundResource", R.drawable.widget_cell_has_tasks)
                        } else {
                            views.setTextColor(cellId, context.getColor(R.color.narwhal_text_primary))
                            views.setInt(cellId, "setBackgroundResource", 0)
                        }
                    } else {
                        // Day from next month
                        val dayNum = i - (startOffset + daysInCurrentMonth) + 1
                        views.setTextViewText(cellId, dayNum.toString())
                        views.setTextColor(cellId, context.getColor(R.color.narwhal_text_muted))
                        views.setInt(cellId, "setBackgroundResource", 0)
                    }
                }

                // Bottom bar
                val agendaSummary = widgetData.getString(
                    "calendar_agenda_summary",
                    "Tap to view Calendar"
                ) ?: "Tap to view Calendar"
                views.setTextViewText(R.id.tv_calendar_agenda_summary, agendaSummary)

                val openCalendarIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("planner://calendar")
                )
                views.setOnClickPendingIntent(R.id.widget_calendar_root, openCalendarIntent)
                views.setOnClickPendingIntent(R.id.tv_calendar_month_year, openCalendarIntent)
                views.setOnClickPendingIntent(R.id.layout_calendar_bottom, openCalendarIntent)
                views.setOnClickPendingIntent(R.id.btn_open_calendar, openCalendarIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
                try {
                    val fallbackViews = RemoteViews(context.packageName, R.layout.widget_calendar)
                    val openCalendarIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("planner://calendar")
                    )
                    fallbackViews.setOnClickPendingIntent(R.id.widget_calendar_root, openCalendarIntent)
                    appWidgetManager.updateAppWidget(appWidgetId, fallbackViews)
                } catch (_: Exception) {}
            }
        }
    }
}
