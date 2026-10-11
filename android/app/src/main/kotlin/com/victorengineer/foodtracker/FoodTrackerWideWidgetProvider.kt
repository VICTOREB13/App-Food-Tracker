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

                val labelCalories = widgetData.getString("label_calories", null)
                    ?: widgetData.getString("widget_label_calories", null)
                    ?: context.getString(R.string.widget_label_calories)
                val kcalRemaining = widgetData.getString("label_kcal_remaining", null)
                    ?: widgetData.getString("widget_kcal_remaining", null)
                    ?: context.getString(R.string.widget_kcal_remaining)
                val leftSuffix = widgetData.getString("label_suffix_left", null)
                    ?: widgetData.getString("widget_suffix_left", null)
                    ?: context.getString(R.string.widget_suffix_left)
                val labelProt = widgetData.getString("label_protein", null)
                    ?: widgetData.getString("widget_label_protein", null)
                    ?: context.getString(R.string.widget_label_protein)
                val labelCarb = widgetData.getString("label_carbs", null)
                    ?: widgetData.getString("widget_label_carbs", null)
                    ?: context.getString(R.string.widget_label_carbs)
                val labelFat = widgetData.getString("label_fat", null)
                    ?: widgetData.getString("widget_label_fat", null)
                    ?: context.getString(R.string.widget_label_fat)

                val scanTitle = widgetData.getString("label_scan_camera_title", null)
                    ?: widgetData.getString("widget_scan_camera_title", null)
                    ?: context.getString(R.string.widget_scan_camera_title)
                val scanSubtitle = widgetData.getString("label_scan_camera_subtitle", null)
                    ?: widgetData.getString("widget_scan_camera_subtitle", null)
                    ?: context.getString(R.string.widget_scan_camera_subtitle)
                val barcodeTitle = widgetData.getString("label_scan_barcode_title", null)
                    ?: widgetData.getString("widget_scan_barcode_title", null)
                    ?: context.getString(R.string.widget_scan_barcode_title)
                val barcodeSubtitle = widgetData.getString("label_scan_barcode_subtitle", null)
                    ?: widgetData.getString("widget_scan_barcode_subtitle", null)
                    ?: context.getString(R.string.widget_scan_barcode_subtitle)

                setTextViewText(R.id.widget_label_calories, labelCalories)
                setTextViewText(R.id.widget_calories_left, "$caloriesLeft")
                setTextViewText(R.id.widget_label_kcal_left, kcalRemaining)
                setTextViewText(R.id.widget_calories_summary, "$caloriesConsumed / $caloriesTarget kcal")

                setTextViewText(R.id.widget_label_protein, labelProt)
                setTextViewText(R.id.widget_protein_val, "${proteinConsumed}g (${proteinLeft}g $leftSuffix)")

                setTextViewText(R.id.widget_label_carbs, labelCarb)
                setTextViewText(R.id.widget_carbs_val, "${carbsConsumed}g (${carbsLeft}g $leftSuffix)")

                setTextViewText(R.id.widget_label_fat, labelFat)
                setTextViewText(R.id.widget_fat_val, "${fatConsumed}g (${fatLeft}g $leftSuffix)")

                setTextViewText(R.id.widget_btn_scan_title, scanTitle)
                setTextViewText(R.id.widget_btn_scan_subtitle, scanSubtitle)
                setTextViewText(R.id.widget_btn_barcode_title, barcodeTitle)
                setTextViewText(R.id.widget_btn_barcode_subtitle, barcodeSubtitle)

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
