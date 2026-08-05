package com.tactile.widgetkit

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * 小卡片（2×2）的 Provider。
 * 三个规格共享同一套更新逻辑（见 [BaseWidgetProvider]），仅布局不同。
 */
class TestWidgetProvider : BaseWidgetProvider() {
    override val layoutId: Int = R.layout.widget_test_small
}

/**
 * 三个规格的公共基类：读 home_widget 写入的数据、刷新文字、绑定拉起按钮。
 * 三套布局里的 tv_data / btn_open_app id 完全一致，所以逻辑可复用。
 */
abstract class BaseWidgetProvider : AppWidgetProvider() {
    protected abstract val layoutId: Int

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutId)

            // 1. 读取 Flutter (home_widget) 写入的共享数据
            // home_widget 默认使用的 SharedPreferences 名字就是 "HomeWidgetPreferences"
            val prefs = context.getSharedPreferences(
                "HomeWidgetPreferences",
                Context.MODE_PRIVATE,
            )
            val flutterData = prefs.getString("test_data", "没收到数据！")

            // 更新卡片上的文字
            views.setTextViewText(R.id.tv_data, flutterData)

            // 2. 绑定按钮点击事件，拉起主应用 MainActivity
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("from_widget", true)
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.btn_open_app, pendingIntent)

            // 提交更新
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
