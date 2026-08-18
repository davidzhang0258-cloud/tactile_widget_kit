package com.tactile.widgetkit.wonder

/**
 * 预留接口：CUSTOM 类型事件的图标解析。
 * 现阶段默认返回 null（即不绘制），留待后续调试接入个性化图标。
 */
object CustomSlotIconProvider {
    /**
     * 返回该 payload 对应的像素位图（7 行等宽字符串，'#' 为实心），
     * 或返回 null 表示暂不绘制。
     */
    fun resolveCustomIcon(payload: String?): Array<String>? = null
}
