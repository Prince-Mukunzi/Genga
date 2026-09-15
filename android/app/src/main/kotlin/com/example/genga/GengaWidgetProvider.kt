package com.example.genga

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews

class GengaWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Called when the first widget is placed
    }

    override fun onDisabled(context: Context) {
        // Called when the last widget is removed
    }

    companion object {
        private fun getPrefs(context: Context): SharedPreferences {
            return context.getSharedPreferences(
                "HomeWidgetPreferences",
                Context.MODE_PRIVATE
            )
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = getPrefs(context)

            val balance = prefs.getString("total_balance_formatted", "RWF 0") ?: "RWF 0"
            val spent = prefs.getString("spent_this_month_formatted", "RWF 0") ?: "RWF 0"

            val views = RemoteViews(context.packageName, R.layout.genga_widget)
            views.setTextViewText(R.id.widget_balance, balance)
            views.setTextViewText(R.id.widget_spent, spent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
