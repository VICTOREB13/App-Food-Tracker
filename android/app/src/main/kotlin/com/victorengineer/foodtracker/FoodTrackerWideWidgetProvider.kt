package com.victorengineer.foodtracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import com.victorengineer.foodtracker.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FoodTrackerWideWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.food_tracker_widget_wide).apply {
                val caloriesLeft = widgetData.getInt("calories_left", 0)
                val caloriesConsumed = widgetData.getInt("calories_consumed", 0)
                val caloriesTarget = widgetData.getInt("calories_target", 2000)
                val proteinConsumed = widgetData.getInt("protein_consumed", 0)
                val proteinLeft = widgetData.getInt("protein_left", 0)
                val carbsConsumed = widgetData.getInt("carbs_consumed", 0)
                val carbsLeft = widgetData.getInt("carbs_left", 0)
                val fatConsumed = widgetData.getInt("fat_consumed", 0)
                val fatLeft = widgetData.getInt("fat_left", 0)

                setTextViewText(R.id.widget_calories_left, "$caloriesLeft")
                setTextViewText(R.id.widget_calories_summary, "$caloriesConsumed / $caloriesTarget kcal")
                setTextViewText(R.id.widget_protein_val, "${proteinConsumed}g (${proteinLeft}g rest)")
                setTextViewText(R.id.widget_carbs_val, "${carbsConsumed}g (${carbsLeft}g rest)")
                setTextViewText(R.id.widget_fat_val, "${fatConsumed}g (${fatLeft}g rest)")

                // Deep links for interactive touch targets
                val scanFoodIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://scan_food")
                )
                setOnClickPendingIntent(R.id.widget_btn_scan_food, scanFoodIntent)

                val scanBarcodeIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://scan_barcode")
                )
                setOnClickPendingIntent(R.id.widget_btn_scan_barcode, scanBarcodeIntent)

                val defaultIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://new_meal")
                )
                setOnClickPendingIntent(R.id.widget_wide_root, defaultIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
