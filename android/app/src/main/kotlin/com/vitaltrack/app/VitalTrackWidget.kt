package com.vitaltrack.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class VitalTrackWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.vitaltrack_widget)
            val widgetData = HomeWidgetPlugin.getData(context)

            val bp = widgetData.getString("latest_bp", "-- / --")
            val pulse = widgetData.getString("latest_pulse", "--")

            views.setTextViewText(R.id.widget_bp, bp)
            views.setTextViewText(R.id.widget_pulse, "$pulse BPM")

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
