package com.tactile.widgetkit.wonder

import android.content.Context
import android.widget.Toast

/**
 * 预留接口：快记桥接。
 * 现阶段仅弹 Toast 提示触发成功，供真机测试按键热区；后续接入真实快记流程。
 */
object QuickNoteBridge {
    fun triggerQuickNote(context: Context, targetDateIso: String?) {
        val date = targetDateIso ?: "今天"
        Toast.makeText(context, "快记触发成功（目标日期 $date）", Toast.LENGTH_SHORT).show()
    }
}
