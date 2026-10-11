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
        val localeCode = widgetData.getString("app_locale_code", null)
        val locale = if (!localeCode.isNullOrEmpty()) Locale(localeCode) else Locale.getDefault()
        val dateFormat = SimpleDateFormat("dd EEE MMM", locale)
        val todayStr = dateFormat.format(Date()).uppercase(locale)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.food_tracker_widget_fasting).apply {
                setTextViewText(R.id.widget_fasting_date, todayStr)

                val isActive = widgetData.getBoolean("fasting_active", false)
                val timeFormatted = widgetData.getString("fasting_time_formatted", null) ?: "0h 0m"
                val targetHours = widgetData.getInt("fasting_target_hours", 16)

                if (isActive) {
                    val statusActive = widgetData.getString("label_fasting_status_active", null)
                        ?: widgetData.getString("widget_fasting_status_active", null)
                        ?: context.getString(R.string.widget_fasting_status_active)
                    val targetPrefix = widgetData.getString("label_fasting_target_active_prefix", null)
                        ?: widgetData.getString("widget_fasting_target_active_prefix", null)
                        ?: context.getString(R.string.widget_fasting_target_active_prefix)
                    val btnEnd = widgetData.getString("label_btn_fasting_end", null)
                        ?: widgetData.getString("widget_btn_fasting_end", null)
                        ?: context.getString(R.string.widget_btn_fasting_end)

                    setTextViewText(R.id.widget_fasting_status, statusActive)
                    setTextViewText(R.id.widget_fasting_time, timeFormatted)
                    setTextViewText(R.id.widget_fasting_target, "$targetPrefix ${targetHours}h")
                    setTextViewText(R.id.widget_btn_fasting_text, btnEnd)
                } else {
                    val statusInactive = widgetData.getString("label_fasting_status_inactive", null)
                        ?: widgetData.getString("widget_fasting_status_inactive", null)
                        ?: context.getString(R.string.widget_fasting_status_inactive)
                    val inactiveText = widgetData.getString("label_fasting_inactive", null)
                        ?: widgetData.getString("widget_fasting_inactive", null)
                        ?: context.getString(R.string.widget_fasting_inactive)
                    val targetPrefix = widgetData.getString("label_fasting_target_inactive_prefix", null)
                        ?: widgetData.getString("widget_fasting_target_inactive_prefix", null)
                        ?: context.getString(R.string.widget_fasting_target_inactive_prefix)
                    val btnStart = widgetData.getString("label_btn_fasting_start", null)
                        ?: widgetData.getString("widget_btn_fasting_start", null)
                        ?: context.getString(R.string.widget_btn_fasting_start)

                    setTextViewText(R.id.widget_fasting_status, statusInactive)
                    setTextViewText(R.id.widget_fasting_time, inactiveText)
                    setTextViewText(R.id.widget_fasting_target, "$targetPrefix ${targetHours}h")
                    setTextViewText(R.id.widget_btn_fasting_text, btnStart)
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
