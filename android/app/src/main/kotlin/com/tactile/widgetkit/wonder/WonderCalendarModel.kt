package com.tactile.widgetkit.wonder

/**
 * Wonder Calendar 事件模型与 Mock 数据。
 */
enum class WonderEventType { TODO, DONE, CUSTOM }

data class WonderEvent(
    val type: WonderEventType,
    val payload: String? = null,
    val createdAt: Long, // 毫秒时间戳，升序排序用
)

/**
 * Mock 测试数据：当月 1、2、4、13、21、28 号填入不同顺序的 TODO 刀 / DONE 心。
 * [relativeDay] 为"相对当月 1 号"的偏移（0 = 1 号）。
 */
object WonderMockData {
    fun eventsFor(year: Int, month: Int): Map<Int, List<WonderEvent>> {
        // 用 (year, month) 生成稳定递增的时间戳，保证 createdAt 升序与「槽位填入顺序」一致。
        val base = java.time.LocalDate.of(year, month, 1).toEpochDay() * 86400_000L

        fun ts(day: Int, seq: Int): Long = base + (day - 1) * 86400_000L + seq * 1000L

        return mapOf(
            // 1 号：两个 TODO 刀 + 一个 DONE 心（测试三槽占满）
            1 to listOf(
                WonderEvent(WonderEventType.TODO, createdAt = ts(1, 1)),
                WonderEvent(WonderEventType.DONE, createdAt = ts(1, 2)),
                WonderEvent(WonderEventType.TODO, createdAt = ts(1, 3)),
            ),
            // 2 号：一个 DONE 心（只占第 1 槽）
            2 to listOf(
                WonderEvent(WonderEventType.DONE, createdAt = ts(2, 1)),
            ),
            // 4 号：一个 TODO 刀 + 一个 DONE 心
            4 to listOf(
                WonderEvent(WonderEventType.TODO, createdAt = ts(4, 1)),
                WonderEvent(WonderEventType.DONE, createdAt = ts(4, 2)),
            ),
            // 13 号：三个 DONE 心（测试同类型三槽）
            13 to listOf(
                WonderEvent(WonderEventType.DONE, createdAt = ts(13, 1)),
                WonderEvent(WonderEventType.DONE, createdAt = ts(13, 2)),
                WonderEvent(WonderEventType.DONE, createdAt = ts(13, 3)),
            ),
            // 21 号：一个 TODO 刀
            21 to listOf(
                WonderEvent(WonderEventType.TODO, createdAt = ts(21, 1)),
            ),
            // 28 号：TODO + DONE + TODO
            28 to listOf(
                WonderEvent(WonderEventType.TODO, createdAt = ts(28, 1)),
                WonderEvent(WonderEventType.DONE, createdAt = ts(28, 2)),
                WonderEvent(WonderEventType.TODO, createdAt = ts(28, 3)),
            ),
        )
    }
}
