package com.algorithmx.planner.widget

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.algorithmx.planner.R
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

class TodayTasksViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodayTasksViewsFactory(applicationContext, intent)
    }
}

class TodayTasksViewsFactory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val tasks = mutableListOf<JSONObject>()

    override fun onCreate() {
        loadTasks()
    }

    override fun onDataSetChanged() {
        loadTasks()
    }

    private fun loadTasks() {
        tasks.clear()
        val prefs = HomeWidgetPlugin.getData(context)
        val jsonStr = prefs.getString("today_tasks_json", "[]") ?: "[]"
        try {
            val array = JSONArray(jsonStr)
            for (i in 0 until array.length()) {
                tasks.add(array.getJSONObject(i))
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        tasks.clear()
    }

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews? {
        if (position < 0 || position >= tasks.size) return null

        val task = tasks[position]
        val views = RemoteViews(context.packageName, R.layout.widget_task_item)

        val id = task.optString("id", "")
        val title = task.optString("title", "Untitled")
        val isCompleted = task.optBoolean("isCompleted", false)
        val priority = task.optInt("priority", 1)
        val duration = task.optInt("durationMinutes", 0)
        val project = task.optString("projectTitle", "")
        val colorHex = task.optString("projectColorHex", "")

        views.setTextViewText(R.id.task_item_title, title)

        // Checkbox state
        if (isCompleted) {
            views.setImageViewResource(R.id.task_item_checkbox, R.drawable.ic_check_box_checked)
            views.setTextColor(R.id.task_item_title, context.getColor(R.color.narwhal_text_muted))
        } else {
            views.setImageViewResource(R.id.task_item_checkbox, R.drawable.ic_check_box_outline)
            views.setTextColor(R.id.task_item_title, context.getColor(R.color.narwhal_text_primary))
        }

        // Project tag
        if (project.isNotEmpty()) {
            views.setViewVisibility(R.id.task_item_project, View.VISIBLE)
            views.setTextViewText(R.id.task_item_project, project)
            if (colorHex.isNotEmpty()) {
                try {
                    views.setTextColor(R.id.task_item_project, Color.parseColor(colorHex))
                } catch (e: Exception) {}
            }
        } else {
            views.setViewVisibility(R.id.task_item_project, View.GONE)
        }

        // Duration
        if (duration > 0) {
            views.setViewVisibility(R.id.task_item_duration, View.VISIBLE)
            val durationText = if (duration >= 60) "${duration / 60}h ${duration % 60}m" else "${duration}m"
            views.setTextViewText(R.id.task_item_duration, durationText)
        } else {
            views.setViewVisibility(R.id.task_item_duration, View.GONE)
        }

        // Priority indicator
        views.setViewVisibility(R.id.task_item_priority, View.VISIBLE)
        when (priority) {
            2 -> views.setInt(R.id.task_item_priority, "setBackgroundColor", context.getColor(R.color.priority_high))
            1 -> views.setInt(R.id.task_item_priority, "setBackgroundColor", context.getColor(R.color.priority_medium))
            else -> views.setInt(R.id.task_item_priority, "setBackgroundColor", context.getColor(R.color.priority_low))
        }

        // FillInIntent for Checkbox Toggle (Direct background toggle)
        val toggleFillInIntent = Intent().apply {
            action = TodayTasksActionReceiver.ACTION_TOGGLE_TASK
            putExtra("taskId", id)
            putExtra("currentStatus", isCompleted)
        }
        views.setOnClickFillInIntent(R.id.task_item_checkbox, toggleFillInIntent)

        // FillInIntent for Task Content click (Opens app to that task)
        val openFillInIntent = Intent().apply {
            action = TodayTasksActionReceiver.ACTION_OPEN_TASK
            putExtra("taskId", id)
        }
        views.setOnClickFillInIntent(R.id.task_item_click_area, openFillInIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}
