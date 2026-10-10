package com.victorengineer.foodtracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import com.victorengineer.foodtracker.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FoodTrackerActionsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.food_tracker_widget_actions).apply {
                val scanFoodIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://scan_food")
                )
                setOnClickPendingIntent(R.id.widget_action_scan_food, scanFoodIntent)

                val barcodeIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://scan_barcode")
                )
                setOnClickPendingIntent(R.id.widget_action_barcode, barcodeIntent)

                val quickMealIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://quick_meal")
                )
                setOnClickPendingIntent(R.id.widget_action_quick_meal, quickMealIntent)

                val waterIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://add_water")
                )
                setOnClickPendingIntent(R.id.widget_action_water, waterIntent)

                setOnClickPendingIntent(R.id.widget_actions_root, quickMealIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
