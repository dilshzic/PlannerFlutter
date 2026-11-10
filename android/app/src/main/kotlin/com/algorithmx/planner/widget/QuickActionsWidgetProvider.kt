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

class QuickActionsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_quick_actions)

                val total = widgetData.safeGetInt("today_total_tasks", 0)
                val completed = widgetData.safeGetInt("today_completed_tasks", 0)
                val pending = (total - completed).coerceAtLeast(0)
                views.setTextViewText(R.id.tv_quick_pending_count, "$pending pending")

                // 1. App launcher (Header)
                val appIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("planner://dashboard")
                )
                views.setOnClickPendingIntent(R.id.btn_quick_open_app, appIntent)

                // 2. Add Task button
                val addTaskIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("planner://action/quick_add")
                )
                views.setOnClickPendingIntent(R.id.btn_action_add_task, addTaskIntent)

                // 3. Note / Scratchpad button
                val noteIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("planner://action/scratchpad")
                )
                views.setOnClickPendingIntent(R.id.btn_action_note, noteIntent)

                // 4. Focus Mode button
                val focusIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("planner://action/focus")
                )
                views.setOnClickPendingIntent(R.id.btn_action_focus, focusIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
