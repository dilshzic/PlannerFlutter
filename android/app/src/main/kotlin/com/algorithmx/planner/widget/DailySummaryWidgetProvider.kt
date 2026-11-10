package com.algorithmx.planner.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import com.algorithmx.planner.MainActivity
import com.algorithmx.planner.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class DailySummaryWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_daily_summary)

                val total = widgetData.safeGetInt("today_total_tasks", 0)
                val completed = widgetData.safeGetInt("today_completed_tasks", 0)
                val totalMinutes = widgetData.safeGetInt("today_total_minutes", 0)
                val workload = widgetData.getString("today_workload", "GRIND") ?: "GRIND"

                val percent = if (total > 0) ((completed.toDouble() / total.toDouble()) * 100).toInt() else 0

                views.setTextViewText(R.id.tv_summary_workload, workload)
                views.setTextViewText(R.id.tv_summary_percent, "$percent%")
                views.setTextViewText(R.id.tv_summary_counts, "$completed/$total Done")

                val hours = totalMinutes / 60
                val mins = totalMinutes % 60
                val focusText = if (hours > 0) "${hours}h ${mins}m Total Focus" else "${mins}m Total Focus"
                views.setTextViewText(R.id.tv_summary_focus_time, focusText)

                val workloadColor = when (workload.uppercase()) {
                    "CASUALTY" -> context.getColor(R.color.workload_casualty)
                    "RECOVERY" -> context.getColor(R.color.workload_recovery)
                    else -> context.getColor(R.color.workload_grind)
                }
                views.setTextColor(R.id.tv_summary_workload, workloadColor)

                // Tapping opens the dashboard
                val openDashboardIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("planner://dashboard")
                )
                views.setOnClickPendingIntent(R.id.widget_summary_root, openDashboardIntent)
                views.setOnClickPendingIntent(R.id.btn_open_dashboard, openDashboardIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
