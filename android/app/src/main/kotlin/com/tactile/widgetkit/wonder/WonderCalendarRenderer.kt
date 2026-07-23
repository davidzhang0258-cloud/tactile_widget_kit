package com.tactile.widgetkit.wonder

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import com.tactile.widgetkit.R
import java.time.LocalDate
import java.time.YearMonth
import kotlin.math.roundToInt

/**
 * Wonder Calendar 的透明覆盖层渲染器。
 *
 * 底板由 XML 中的 iv_wonder_shell 加载 @drawable/wonder_calendar_shell（透明外壳，已放宽
 * 裁切到 (64,80,936,920)）。这里渲染 400×400 全透明 Bitmap，通过 mapX/mapY 把原 1000 坐标
 * 映射到 400 画布，叠加：年月、双线内凹日历格、今日 RPG 四角护角金框、日期数字、像素刀/红心。
 */
object WonderCalendarRenderer {
    @Volatile private var swordIcon: Bitmap? = null
    @Volatile private var heartIcon: Bitmap? = null

    private fun sword(context: Context): Bitmap? {
        var b = swordIcon
        if (b == null || b.isRecycled) {
            b = BitmapFactory.decodeResource(context.resources, R.drawable.ic_pixel_sword)
            swordIcon = b
        }
        return b
    }

    private fun heart(context: Context): Bitmap? {
        var b = heartIcon
        if (b == null || b.isRecycled) {
            b = BitmapFactory.decodeResource(context.resources, R.drawable.ic_pixel_heart)
            heartIcon = b
        }
        return b
    }

    private const val COLOR_YEAR_MONTH = 0xFF0D3B8C.toInt()
    private const val COLOR_GRID_LINE = 0xFF1A2226.toInt()    // 深黑外框
    private const val COLOR_GRID_SHADOW = 0xFF9BA8A6.toInt()  // 内阴影
    private const val COLOR_DAY_NUM = 0xFF11181C.toInt()
    private const val COLOR_TODAY_OUTER = 0xFF3A2605.toInt()  // 深褐黑外描边
    private const val COLOR_TODAY_MAIN = 0xFFF5C438.toInt()   // 亮金主框
    private const val COLOR_TODAY_HI = 0xFFFFF29C.toInt()     // 内侧高光

    // 覆盖层画布 400×400；底板裁切到 (64,80,936,920)，宽 872 高 840
    private const val CANVAS = 400
    private const val CROP_LEFT = 64f
    private const val CROP_TOP = 80f
    private const val CROP_W = 872f
    private const val CROP_H = 840f

    private fun mapX(oldX: Float) = ((oldX - CROP_LEFT) / CROP_W) * CANVAS
    private fun mapY(oldY: Float) = ((oldY - CROP_TOP) / CROP_H) * CANVAS

    private val YEAR_X = mapX(595f)
    private val YEAR_Y = mapY(232f)

    private val GRID_LEFT = mapX(270f)
    private val GRID_TOP = mapY(374f)
    private val GRID_RIGHT = mapX(730f)
    private val GRID_BOTTOM = mapY(694f)

    private const val COLS = 7

    fun render(
        context: Context,
        displayYear: Int,
        displayMonth: Int,
        today: LocalDate,
        eventsByDay: Map<Int, List<WonderEvent>>,
    ): Bitmap {
        val bmp = Bitmap.createBitmap(CANVAS, CANVAS, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)

        drawYearMonth(canvas, displayYear, displayMonth)
        drawGrid(canvas, context, displayYear, displayMonth, today, eventsByDay)

        return bmp
    }

    private fun drawYearMonth(canvas: Canvas, year: Int, month: Int) {
        val ym = "%04d.%02d".format(year, month)
        PixelFont.drawText(canvas, ym, YEAR_X, YEAR_Y, 2f, COLOR_YEAR_MONTH)
    }

    private fun drawGrid(
        canvas: Canvas,
        context: Context,
        displayYear: Int,
        displayMonth: Int,
        today: LocalDate,
        eventsByDay: Map<Int, List<WonderEvent>>,
    ) {
        val gx = GRID_LEFT
        val gy = GRID_TOP
        val gw = GRID_RIGHT - GRID_LEFT
        val gh = GRID_BOTTOM - GRID_TOP

        val ym = YearMonth.of(displayYear, displayMonth)
        val leading = ym.atDay(1).dayOfWeek.value - 1
        val daysInMonth = ym.lengthOfMonth()
        val rows = kotlin.math.ceil((leading + daysInMonth) / 7.0).toInt()

        val colW = gw / COLS
        val rowH = gh / rows

        // 1px 实线填充（整数坐标，单次绘制，避免浮点重叠导致线条粗细不一）
        val black = Paint().apply { color = COLOR_GRID_LINE; style = Paint.Style.FILL; isAntiAlias = false }
        val shadow = Paint().apply { color = COLOR_GRID_SHADOW; style = Paint.Style.FILL; isAntiAlias = false }

        for (day in 1..daysInMonth) {
            val idx = leading + (day - 1)
            val col = idx % COLS
            val row = idx / COLS

            // 整数像素坐标 + 向内缩进 1px 画独立内凹框
            val l = (gx + col * colW).roundToInt()
            val t = (gy + row * rowH).roundToInt()
            val r = (gx + (col + 1) * colW).roundToInt()
            val b = (gy + (row + 1) * rowH).roundToInt()

            val il = l + 1
            val it = t + 1
            val ir = r - 1
            val ib = b - 1

            // 深黑外框（上下左右 4 条 1px）
            canvas.drawRect(il.toFloat(), it.toFloat(), ir.toFloat(), (it + 1).toFloat(), black)
            canvas.drawRect(il.toFloat(), (ib - 1).toFloat(), ir.toFloat(), ib.toFloat(), black)
            canvas.drawRect(il.toFloat(), it.toFloat(), (il + 1).toFloat(), ib.toFloat(), black)
            canvas.drawRect((ir - 1).toFloat(), it.toFloat(), ir.toFloat(), ib.toFloat(), black)

            // 内阴影线（上边 + 左边 1px）
            canvas.drawRect((il + 1).toFloat(), (it + 1).toFloat(), (ir - 1).toFloat(), (it + 2).toFloat(), shadow)
            canvas.drawRect((il + 1).toFloat(), (it + 1).toFloat(), (il + 2).toFloat(), (ib - 1).toFloat(), shadow)

            val fl = l.toFloat()
            val ft = t.toFloat()
            val fr = r.toFloat()
            val fb = b.toFloat()

            if (LocalDate.of(displayYear, displayMonth, day) == today) {
                drawTodayCursor(canvas, fl, ft, fr, fb)
            }
            drawCell(canvas, context, day, fl, ft, fr, fb, eventsByDay[day].orEmpty())
        }
    }

    /** 当天：RPG 四角护角立体金框（深褐外描边 + 亮金主框 + 浅黄内高光 + 四角 L 型护角）。 */
    private fun drawTodayCursor(canvas: Canvas, l: Float, t: Float, r: Float, b: Float) {
        val outer = Paint().apply {
            color = COLOR_TODAY_OUTER
            style = Paint.Style.STROKE
            strokeWidth = 3.5f
            isAntiAlias = false
        }
        canvas.drawRect(l - 1f, t - 1f, r + 1f, b + 1f, outer)

        val main = Paint().apply {
            color = COLOR_TODAY_MAIN
            style = Paint.Style.STROKE
            strokeWidth = 2.2f
            isAntiAlias = false
        }
        canvas.drawRect(l, t, r, b, main)

        val hi = Paint().apply {
            color = COLOR_TODAY_HI
            style = Paint.Style.STROKE
            strokeWidth = 0.8f
            isAntiAlias = false
        }
        canvas.drawRect(l + 2f, t + 2f, r - 2f, b - 2f, hi)

        // 四角 L 型凸出金色护角（带深褐黑 1px 描边）
        drawCornerL(canvas, l - 1f, t - 1f, 1f, 1f)
        drawCornerL(canvas, r + 1f, t - 1f, -1f, 1f)
        drawCornerL(canvas, l - 1f, b + 1f, 1f, -1f)
        drawCornerL(canvas, r + 1f, b + 1f, -1f, -1f)
    }

    private fun drawCornerL(canvas: Canvas, ex: Float, ey: Float, hDir: Float, vDir: Float) {
        val len = 4f
        val th = 2f
        val gold = Paint().apply { color = COLOR_TODAY_MAIN; style = Paint.Style.FILL; isAntiAlias = false }
        val dark = Paint().apply { color = COLOR_TODAY_OUTER; style = Paint.Style.FILL; isAntiAlias = false }

        val hL = if (hDir > 0) ex else ex - len
        val hT = if (vDir > 0) ey else ey - th
        val vL = if (hDir > 0) ex else ex - th
        val vT = if (vDir > 0) ey else ey - len

        // 深褐黑 1px 描边（先画略大的暗底）
        canvas.drawRect(hL - 1f, hT - 1f, hL + len + 1f, hT + th + 1f, dark)
        canvas.drawRect(vL - 1f, vT - 1f, vL + th + 1f, vT + len + 1f, dark)
        // 亮金填充
        canvas.drawRect(hL, hT, hL + len, hT + th, gold)
        canvas.drawRect(vL, vT, vL + th, vT + len, gold)
    }

    private fun drawCell(
        canvas: Canvas,
        context: Context,
        day: Int,
        l: Float,
        t: Float,
        r: Float,
        b: Float,
        events: List<WonderEvent>,
    ) {
        val cw = r - l
        val ch = b - t

        // 左上角日期数字：顶部 12% / 左侧 10% 内边距，字号 = 格高 25%
        val dayScale = ch * 0.25f / 7f
        PixelFont.drawText(canvas, day.toString(), l + cw * 0.10f, t + ch * 0.12f, dayScale, COLOR_DAY_NUM)

        val slotSize = cw * 0.35f
        val sorted = events.sortedBy { it.createdAt }
        // 优先顺序：左下 → 右下 → 右上（仅满 3 个事件才用右上）
        val slots = listOf(
            Slot(l + cw * 0.08f, t + ch * 0.52f, l + cw * 0.08f + slotSize, t + ch * 0.52f + slotSize),
            Slot(l + cw * 0.54f, t + ch * 0.52f, l + cw * 0.54f + slotSize, t + ch * 0.52f + slotSize),
            Slot(l + cw * 0.58f, t + ch * 0.10f, l + cw * 0.58f + slotSize, t + ch * 0.10f + slotSize),
        )
        for (i in 0 until minOf(3, sorted.size)) {
            drawIconForEvent(canvas, context, sorted[i], slots[i])
        }
    }

    private data class Slot(val l: Float, val t: Float, val r: Float, val b: Float)

    private fun drawIconForEvent(canvas: Canvas, context: Context, event: WonderEvent, slot: Slot) {
        if (event.type == WonderEventType.CUSTOM) return
        val icon = (if (event.type == WonderEventType.TODO) sword(context) else heart(context)) ?: return

        val paint = Paint().apply {
            isFilterBitmap = false
            isAntiAlias = false
        }
        canvas.drawBitmap(icon, null, RectF(slot.l, slot.t, slot.r, slot.b), paint)
    }
}
