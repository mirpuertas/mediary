package com.mirpuertas.mediary

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import java.util.Calendar

class WaterWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val ACTION_INC = "com.mirpuertas.mediary.WATER_INC"
        private const val ACTION_DEC = "com.mirpuertas.mediary.WATER_DEC"

        // Must match Flutter's shared_preferences format: "flutter." prefix + key
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_PREFIX = "flutter.water_"

        private fun todayKey(): String {
            val cal = Calendar.getInstance()
            val y = cal.get(Calendar.YEAR)
            val m = cal.get(Calendar.MONTH) + 1
            val d = cal.get(Calendar.DAY_OF_MONTH)
            return String.format("%s%04d-%02d-%02d", KEY_PREFIX, y, m, d)
        }

        private fun getPrefs(context: Context): SharedPreferences {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }

        private fun getWater(prefs: SharedPreferences, key: String): Int {
            // shared_preferences stores ints as Long in Android
            return prefs.getLong(key, 0L).toInt().coerceIn(0, 10)
        }

        private fun setWater(prefs: SharedPreferences, key: String, value: Int) {
            prefs.edit().putLong(key, value.toLong().coerceIn(0, 10)).apply()
        }

        private fun pendingIntent(
            context: Context,
            action: String,
            appWidgetId: Int
        ): PendingIntent {
            val intent = Intent(context, WaterWidgetProvider::class.java)
            intent.action = action
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            // Use simple unique request codes: widgetId*2 for INC, widgetId*2+1 for DEC
            val requestCode = if (action == ACTION_INC) appWidgetId * 2 else appWidgetId * 2 + 1
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            return PendingIntent.getBroadcast(context, requestCode, intent, flags)
        }

        private fun updateOne(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.water_widget)

            val prefs = getPrefs(context)
            val key = todayKey()
            val water = getWater(prefs, key)

            views.setTextViewText(R.id.water_value, "$water")
            views.setOnClickPendingIntent(R.id.water_inc, pendingIntent(context, ACTION_INC, appWidgetId))
            views.setOnClickPendingIntent(R.id.water_dec, pendingIntent(context, ACTION_DEC, appWidgetId))

            manager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action ?: return
        if (action != ACTION_INC && action != ACTION_DEC) return

        val prefs = getPrefs(context)
        val key = todayKey()
        val current = getWater(prefs, key)
        val next = when (action) {
            ACTION_INC -> (current + 1).coerceAtMost(10)
            ACTION_DEC -> (current - 1).coerceAtLeast(0)
            else -> current
        }
        setWater(prefs, key, next)

        // Update all widget instances
        val mgr = AppWidgetManager.getInstance(context)
        val ids = mgr.getAppWidgetIds(
            android.content.ComponentName(context, WaterWidgetProvider::class.java)
        )
        for (id in ids) {
            updateOne(context, mgr, id)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateOne(context, appWidgetManager, id)
        }
    }
}

