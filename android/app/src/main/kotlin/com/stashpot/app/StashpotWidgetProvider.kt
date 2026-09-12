package com.stashpot.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Home-screen quick-add widget. Displays the "to buy" count (localized text
/// pushed from the app) and, on tap, opens the app straight to the shopping
/// add sheet via the stashpot://quickadd launch URI.
class StashpotWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.stashpot_widget)

            // Strings are formatted + localized by the app; fall back to the
            // layout defaults (English) before the app has run once.
            widgetData.getString("count_text", null)?.let {
                views.setTextViewText(R.id.widget_count, it)
            }
            widgetData.getString("add_label", null)?.let {
                views.setTextViewText(R.id.widget_add_label, it)
            }

            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("stashpot://quickadd"),
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
