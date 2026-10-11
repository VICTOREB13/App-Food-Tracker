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
                val scanFoodText = widgetData.getString("label_action_scan_food", null)
                    ?: widgetData.getString("widget_action_scan_food", null)
                    ?: context.getString(R.string.widget_action_scan_food)
                val barcodeText = widgetData.getString("label_action_barcode", null)
                    ?: widgetData.getString("widget_action_barcode", null)
                    ?: context.getString(R.string.widget_action_barcode)
                val quickMealText = widgetData.getString("label_action_quick_meal", null)
                    ?: widgetData.getString("widget_action_quick_meal", null)
                    ?: context.getString(R.string.widget_action_quick_meal)
                val waterText = widgetData.getString("label_action_water", null)
                    ?: widgetData.getString("widget_action_water", null)
                    ?: context.getString(R.string.widget_action_water)

                setTextViewText(R.id.widget_action_scan_food_text, scanFoodText)
                setTextViewText(R.id.widget_action_barcode_text, barcodeText)
                setTextViewText(R.id.widget_action_quick_meal_text, quickMealText)
                setTextViewText(R.id.widget_action_water_text, waterText)

                // Deep link 1: Camera AI
                val scanFoodIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://scan_food")
                )
                setOnClickPendingIntent(R.id.widget_action_scan_food, scanFoodIntent)

                // Deep link 2: Barcode scanner
                val barcodeIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://scan_barcode")
                )
                setOnClickPendingIntent(R.id.widget_action_barcode, barcodeIntent)

                // Deep link 3: Quick meal dialog
                val quickMealIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://quick_meal")
                )
                setOnClickPendingIntent(R.id.widget_action_quick_meal, quickMealIntent)

                // Deep link 4: Add 250ml water
                val waterIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://add_water")
                )
                setOnClickPendingIntent(R.id.widget_action_water, waterIntent)

                // Default root tap
                setOnClickPendingIntent(R.id.widget_actions_root, quickMealIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
