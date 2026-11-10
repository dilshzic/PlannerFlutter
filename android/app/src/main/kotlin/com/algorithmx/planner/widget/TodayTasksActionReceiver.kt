package com.algorithmx.planner.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.algorithmx.planner.MainActivity
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class TodayTasksActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_TOGGLE_TASK = "com.algorithmx.planner.ACTION_TOGGLE_TASK"
        const val ACTION_OPEN_TASK = "com.algorithmx.planner.ACTION_OPEN_TASK"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val taskId = intent.getStringExtra("taskId") ?: return

        when (intent.action) {
            ACTION_TOGGLE_TASK -> {
                // Background toggle without opening the app
                val toggleUri = Uri.parse("planner://toggle?id=$taskId")
                val backgroundPendingIntent = HomeWidgetBackgroundIntent.getBroadcast(context, toggleUri)
                try {
                    backgroundPendingIntent.send()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
            ACTION_OPEN_TASK -> {
                // Open the task in app
                val openUri = Uri.parse("planner://task/open?id=$taskId")
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
                    data = openUri
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                context.startActivity(launchIntent)
            }
        }
    }
}
