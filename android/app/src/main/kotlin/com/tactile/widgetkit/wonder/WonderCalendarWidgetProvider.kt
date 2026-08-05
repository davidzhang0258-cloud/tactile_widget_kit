package com.tactile.widgetkit.wonder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.widget.RemoteViews
import com.tactile.widgetkit.MainActivity
import com.tactile.widgetkit.R
import java.time.LocalDate
import java.time.YearMonth

/**
 * Wonder Calendar 4×4 桌面小组件 Provider。
 *
 * 双层 ImageView：底层 iv_wonder_shell 加载外壳底板，上层 iv_wonder_canvas 传 400×400 透明
 * 覆盖层。单击屏幕区/＋QUICK 直接进 App；翻月/返回用局部刷新提速。
 */
class WonderCalendarWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_PREV_MONTH = "com.tactile.widgetkit.wonder.ACTION_PREV_MONTH"
        const val ACTION_NEXT_MONTH = "com.tactile.widgetkit.wonder.ACTION_NEXT_MONTH"
        const val ACTION_BACK_TO_TODAY = "com.tactile.widgetkit.wonder.ACTION_BACK_TO_TODAY"

        // Activity PendingIntent（单击进 App）
        private const val REQ_CARD_BODY = 1001
        private const val REQ_QUICK = 1002

        // 广播 PendingIntent（翻月/返回）
        private const val REQ_PREV = 2001
        private const val REQ_NEXT = 2002
        private const val REQ_BACK = 2003

        fun updateAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = ids(context)
            if (ids.isNotEmpty()) {
                fullUpdate(context, mgr, ids)
            }
        }

        private fun ids(context: Context): IntArray =
            AppWidgetManager.getInstance(context).getAppWidgetIds(
                ComponentName(context, WonderCalendarWidgetProvider::class.java)
            )

        private fun currentOverlay(context: Context): Bitmap {
            val now = LocalDate.now()
            val offset = WonderCalendarState.getMonthOffset(context)
            val display = YearMonth.of(now.year, now.monthValue).plusMonths(offset.toLong())
            val events = WonderMockData.eventsFor(display.year, display.monthValue)
            return WonderCalendarRenderer.render(context, display.year, display.monthValue, now, events)
        }

        private fun fullUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
            val overlay = currentOverlay(context)
            val now = LocalDate.now()
            val todayIso = "%04d-%02d-%02d".format(now.year, now.monthValue, now.dayOfMonth)

            for (id in ids) {
                val views = RemoteViews(context.packageName, R.layout.widget_wonder_calendar)
                views.setImageViewResource(R.id.iv_wonder_shell, R.drawable.wonder_calendar_shell)
                views.setImageViewBitmap(R.id.iv_wonder_canvas, overlay)
                views.setOnClickPendingIntent(R.id.zone_card_body, activityIntent(context, REQ_CARD_BODY, null, null))
                views.setOnClickPendingIntent(R.id.btn_prev_month, broadcast(context, ACTION_PREV_MONTH, REQ_PREV))
                views.setOnClickPendingIntent(R.id.btn_next_month, broadcast(context, ACTION_NEXT_MONTH, REQ_NEXT))
                views.setOnClickPendingIntent(R.id.btn_back_today, broadcast(context, ACTION_BACK_TO_TODAY, REQ_BACK))
                views.setOnClickPendingIntent(R.id.btn_quick_note, activityIntent(context, REQ_QUICK, "day_slot_quick_add", todayIso))
                mgr.updateAppWidget(id, views)
            }
        }

        /** 局部刷新：只更新上层透明日历覆盖层，外壳/热区保持不变。 */
        private fun refreshCanvas(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = ids(context)
            if (ids.isEmpty()) return
            val overlay = currentOverlay(context)
            val partial = RemoteViews(context.packageName, R.layout.widget_wonder_calendar)
            partial.setImageViewBitmap(R.id.iv_wonder_canvas, overlay)
            mgr.partiallyUpdateAppWidget(ids, partial)
        }

        private fun broadcast(context: Context, action: String, reqCode: Int): PendingIntent {
            val intent = Intent(context, WonderCalendarWidgetProvider::class.java).apply {
                this.action = action
                // 前台高优标志，避免被 OPPO ColorOS 塞进后台广播队列延迟
                addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
            }
            return PendingIntent.getBroadcast(
                context,
                reqCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun activityIntent(
            context: Context,
            reqCode: Int,
            route: String?,
            targetDate: String?,
        ): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                if (route != null) {
                    action = "ACTION_QUICK_ADD"
                    putExtra("route", route)
                }
                if (targetDate != null) putExtra("target_date", targetDate)
            }
            return PendingIntent.getActivity(
                context,
                reqCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        fullUpdate(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_PREV_MONTH -> {
                val o = WonderCalendarState.getMonthOffset(context)
                WonderCalendarState.setMonthOffset(context, o - 1)
                refreshCanvas(context)
            }
            ACTION_NEXT_MONTH -> {
                val o = WonderCalendarState.getMonthOffset(context)
                WonderCalendarState.setMonthOffset(context, o + 1)
                refreshCanvas(context)
            }
            ACTION_BACK_TO_TODAY -> {
                WonderCalendarState.resetToToday(context)
                refreshCanvas(context)
            }
        }
    }
}
