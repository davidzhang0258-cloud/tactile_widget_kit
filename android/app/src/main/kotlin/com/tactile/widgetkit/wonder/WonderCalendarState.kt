package com.tactile.widgetkit.wonder

import android.content.Context

/**
 * 当前显示月份的状态持久化（存「相对系统真实年月的偏移量」）。
 * BACK_TO_TODAY 时重置为 0。
 */
object WonderCalendarState {
    private const val PREFS = "WonderCalendarPrefs"
    private const val KEY_MONTH_OFFSET = "monthOffset"

    fun getMonthOffset(context: Context): Int =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getInt(KEY_MONTH_OFFSET, 0)

    fun setMonthOffset(context: Context, offset: Int) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putInt(KEY_MONTH_OFFSET, offset).apply()
    }

    fun resetToToday(context: Context) = setMonthOffset(context, 0)
}
