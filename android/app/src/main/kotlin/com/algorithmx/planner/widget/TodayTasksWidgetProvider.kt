package com.algorithmx.planner.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
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

class TodayTasksWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_today_tasks)

                // Header date
                val dateFormat = SimpleDateFormat("EEEE, MMM d", Locale.getDefault())
                views.setTextViewText(R.id.tv_widget_date, dateFormat.format(Date()))

                // Progress text
                val total = widgetData.safeGetInt("today_total_tasks", 0)
                val completed = widgetData.safeGetInt("today_completed_tasks", 0)
                val workload = widgetData.getString("today_workload", "GRIND") ?: "GRIND"

                views.setTextViewText(R.id.tv_widget_progress, "$completed/$total Completed")
                views.setTextViewText(R.id.tv_widget_workload, workload)

                // Workload badge color
                val workloadColor = when (workload.uppercase()) {
                    "CASUALTY" -> context.getColor(R.color.workload_casualty)
                    "RECOVERY" -> context.getColor(R.color.workload_recovery)
                    else -> context.getColor(R.color.workload_grind)
                }
                views.setTextColor(R.id.tv_widget_workload, workloadColor)

                // Quick Add button intent
                val quickAddIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("planner://action/quick_add")
                )
                views.setOnClickPendingIntent(R.id.btn_quick_add, quickAddIntent)

                // Header click to open dashboard
                val openDashboardIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("planner://dashboard")
                )
                views.setOnClickPendingIntent(R.id.widget_header, openDashboardIntent)

                // Empty state vs List
                val tasksJson = widgetData.getString("today_tasks_json", "[]") ?: "[]"
                if (tasksJson == "[]" || tasksJson.isEmpty()) {
                    views.setViewVisibility(R.id.empty_tasks_view, View.VISIBLE)
                    views.setViewVisibility(R.id.task_list_view, View.GONE)
                } else {
                    views.setViewVisibility(R.id.empty_tasks_view, View.GONE)
                    views.setViewVisibility(R.id.task_list_view, View.VISIBLE)
                }

                // Set up RemoteViewsService intent for ListView
                val serviceIntent = Intent(context, TodayTasksViewsService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                views.setRemoteAdapter(R.id.task_list_view, serviceIntent)

                // Pending intent template for ListView items
                val itemClickIntent = Intent(context, TodayTasksActionReceiver::class.java)
                val flags = if (Build.VERSION.SDK_INT >= 31) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val itemClickPendingIntent = PendingIntent.getBroadcast(
                    context,
                    0,
                    itemClickIntent,
                    flags
                )
                views.setPendingIntentTemplate(R.id.task_list_view, itemClickPendingIntent)

                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.task_list_view)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
