package ai.aandccreative.prakriya

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

/**
 * The Prakriyā home-screen widget — shows whichever of today's habits
 * checklist / top priority / mantra the user turned on in Settings > Home
 * screen widget. Data is written by [ai.aandccreative.prakriya's Flutter
 * side] (lib/services/home_widget_service.dart) via the home_widget plugin,
 * which lands in the SharedPreferences file this class reads.
 */
class HabitsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.habits_widget)

            val mantra = widgetData.getString("widget_mantra", "") ?: ""
            if (mantra.isEmpty()) {
                views.setViewVisibility(R.id.widget_mantra, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_mantra, View.VISIBLE)
                views.setTextViewText(R.id.widget_mantra, mantra)
            }

            val priority = widgetData.getString("widget_top_priority", "") ?: ""
            if (priority.isEmpty()) {
                views.setViewVisibility(R.id.widget_priority, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_priority, View.VISIBLE)
                views.setTextViewText(R.id.widget_priority, "• $priority")
            }

            val habitsJson = widgetData.getString("widget_habits", "[]") ?: "[]"
            val habitsText = try {
                val arr = JSONArray(habitsJson)
                val lines = StringBuilder()
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    val mark = if (obj.optBoolean("done", false)) "✓" else "○"
                    if (lines.isNotEmpty()) lines.append("\n")
                    lines.append("$mark ${obj.optString("name")}")
                }
                lines.toString()
            } catch (e: Exception) {
                ""
            }
            if (habitsText.isEmpty()) {
                views.setViewVisibility(R.id.widget_habits, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_habits, View.VISIBLE)
                views.setTextViewText(R.id.widget_habits, habitsText)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
