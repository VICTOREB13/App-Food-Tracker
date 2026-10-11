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

                val labelCalories = widgetData.getString("label_calories", null)
                    ?: widgetData.getString("widget_label_calories", null)
                    ?: context.getString(R.string.widget_label_calories)
                val caloriesSubtitle = widgetData.getString("label_calories_subtitle", null)
                    ?: widgetData.getString("widget_calories_subtitle", null)
                    ?: context.getString(R.string.widget_calories_subtitle)
                val actionAdd = widgetData.getString("label_action_add", null)
                    ?: widgetData.getString("widget_action_add", null)
                    ?: context.getString(R.string.widget_action_add)

                setTextViewText(R.id.widget_label_calories, labelCalories)
                setTextViewText(R.id.widget_calories_left, "$caloriesLeft")
                setTextViewText(R.id.widget_calories_subtitle, caloriesSubtitle)
                setTextViewText(R.id.widget_calories_summary, "$caloriesConsumed / $caloriesTarget kcal")
                setTextViewText(R.id.widget_btn_add_text, actionAdd)

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
