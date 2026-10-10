package com.victorengineer.foodtracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import com.victorengineer.foodtracker.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FoodTrackerStreakWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.food_tracker_widget_streak).apply {
                val streak = widgetData.getInt("streak_count", 0)
                val daySuffix = if (streak == 1) "DÍA" else "DÍAS"
                setTextViewText(R.id.widget_streak_count, "🔥 $streak $daySuffix")

                val dotIds = intArrayOf(
                    R.id.widget_dot_1, R.id.widget_dot_2, R.id.widget_dot_3,
                    R.id.widget_dot_4, R.id.widget_dot_5, R.id.widget_dot_6, R.id.widget_dot_7
                )
                val activeDots = streak.coerceIn(0, 7)
                for (i in dotIds.indices) {
                    if (i < activeDots) {
                        setInt(dotIds[i], "setBackgroundResource", R.drawable.widget_dot_active)
                    } else {
                        setInt(dotIds[i], "setBackgroundResource", R.drawable.widget_dot_inactive)
                    }
                }

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://metrics")
                )
                setOnClickPendingIntent(R.id.widget_streak_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
