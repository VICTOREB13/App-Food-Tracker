package com.victorengineer.foodtracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import com.victorengineer.foodtracker.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class FoodTrackerFastingWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val dateFormat = SimpleDateFormat("dd EEE MMM", Locale.getDefault())
        val todayStr = dateFormat.format(Date()).uppercase(Locale.getDefault())

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.food_tracker_widget_fasting).apply {
                setTextViewText(R.id.widget_fasting_date, todayStr)

                val isActive = widgetData.getBoolean("fasting_active", false)
                val timeFormatted = widgetData.getString("fasting_time_formatted", null) ?: "0h 0m"
                val targetHours = widgetData.getInt("fasting_target_hours", 16)

                if (isActive) {
                    setTextViewText(R.id.widget_fasting_status, "AYUNO EN CURSO")
                    setTextViewText(R.id.widget_fasting_time, timeFormatted)
                    setTextViewText(R.id.widget_fasting_target, "Meta ${targetHours}h")
                    setTextViewText(R.id.widget_btn_fasting_text, "Terminar Ayuno")
                } else {
                    setTextViewText(R.id.widget_fasting_status, "AYUNO INTERMITENTE")
                    setTextViewText(R.id.widget_fasting_time, "INACTIVO")
                    setTextViewText(R.id.widget_fasting_target, "Objetivo: ${targetHours}h")
                    setTextViewText(R.id.widget_btn_fasting_text, "Iniciar Ayuno")
                }

                val fastingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("foodtracker://fasting")
                )
                setOnClickPendingIntent(R.id.widget_btn_fasting, fastingIntent)
                setOnClickPendingIntent(R.id.widget_fasting_root, fastingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
