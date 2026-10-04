package com.victorengineer.foodtracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import com.victorengineer.foodtracker.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FoodTrackerCompactWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.food_tracker_widget_compact).apply {
                val caloriesLeft = widgetData.getInt("calories_left", 0)
                val caloriesConsumed = widgetData.getInt("calories_consumed", 0)
                val caloriesTarget = widgetData.getInt("calories_target", 2000)

                setTextViewText(R.id.widget_calories_left, "$caloriesLeft")
                setTextViewText(R.id.widget_calories_summary, "$caloriesConsumed / $caloriesTarget kcal")

                // PendingIntent to launch app into manual food entry
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://new_meal")
                )
                setOnClickPendingIntent(R.id.widget_btn_add, pendingIntent)
                setOnClickPendingIntent(R.id.widget_compact_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
