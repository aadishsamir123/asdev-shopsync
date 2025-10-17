package com.aadishsamir.shopsync

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class ShopSyncWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val isDarkMode = widgetData.getBoolean("isDarkMode", false)
            
            // Get colors from shared data or use defaults
            val primaryColorStr = widgetData.getString("primaryColor", if (isDarkMode) "#2E7D32" else "#388E3C")
            val backgroundColorStr = widgetData.getString("backgroundColor", if (isDarkMode) "#2E2E2E" else "#FFFFFF")
            val textColorStr = widgetData.getString("textColor", if (isDarkMode) "#FFFFFF" else "#000000")
            val subtitleColorStr = widgetData.getString("subtitleColor", if (isDarkMode) "#B0BEC5" else "#757575")
            
            val textColor = try { 
                Color.parseColor(textColorStr) 
            } catch (e: Exception) { 
                if (isDarkMode) Color.WHITE else Color.BLACK 
            }
            val subtitleColor = try { 
                Color.parseColor(subtitleColorStr) 
            } catch (e: Exception) { 
                if (isDarkMode) Color.parseColor("#B0BEC5") else Color.parseColor("#757575")
            }
            
            // Choose appropriate layout based on widget size
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
            
            val layoutRes = when {
                minWidth >= 250 && minHeight >= 180 -> R.layout.shopsync_widget_large
                minWidth >= 180 && minHeight >= 110 -> R.layout.shopsync_widget_medium
                minWidth >= 110 && minHeight >= 80 -> R.layout.shopsync_widget_small
                else -> R.layout.shopsync_widget_default
            }
            
            val views = RemoteViews(context.packageName, layoutRes).apply {
                setTextViewText(R.id.widget_title, "ShopSync")
                setTextViewText(R.id.widget_subtitle, "Your Shopping Companion")
                setTextColor(R.id.widget_title, textColor)
                setTextColor(R.id.widget_subtitle, subtitleColor)
                
                // Update background based on theme
                setInt(R.id.widget_container, "setBackgroundResource", 
                    if (isDarkMode) R.drawable.widget_background_dark else R.drawable.widget_background_light)
                
                // Create intent to launch the app when widget is clicked
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 
                    0, 
                    intent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
