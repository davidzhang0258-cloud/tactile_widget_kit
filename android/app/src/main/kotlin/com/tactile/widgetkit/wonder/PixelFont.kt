package com.tactile.widgetkit.wonder

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint

/**
 * 5×7 像素点阵字体（bitmap font）。
 * 没有依赖任何 .ttf 字体文件，全部用点阵自绘，配合 Paint.isFilterBitmap=false 保持像素锐度。
 *
 * 位序约定：每行一个 Int，bit4（0b10000）是最左像素，bit0（0b00001）是最右像素。
 */
object PixelFont {
    const val CHAR_W = 5
    const val CHAR_H = 7

    private val glyphs: Map<Char, IntArray> = mapOf(
        // 数字
        '0' to intArrayOf(0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110),
        '1' to intArrayOf(0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110),
        '2' to intArrayOf(0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111),
        '3' to intArrayOf(0b11111, 0b00010, 0b00100, 0b00010, 0b00001, 0b10001, 0b01110),
        '4' to intArrayOf(0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010),
        '5' to intArrayOf(0b11111, 0b10000, 0b11110, 0b00001, 0b00001, 0b10001, 0b01110),
        '6' to intArrayOf(0b00110, 0b01000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110),
        '7' to intArrayOf(0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000),
        '8' to intArrayOf(0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110),
        '9' to intArrayOf(0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00010, 0b01100),
        // 大写字母（星期 MON TUE WED THU FRI SAT SUN）
        'A' to intArrayOf(0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001),
        'B' to intArrayOf(0b11110, 0b10001, 0b10001, 0b11110, 0b10001, 0b10001, 0b11110),
        'C' to intArrayOf(0b01110, 0b10001, 0b10000, 0b10000, 0b10000, 0b10001, 0b01110),
        'D' to intArrayOf(0b11100, 0b10010, 0b10001, 0b10001, 0b10001, 0b10010, 0b11100),
        'E' to intArrayOf(0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b11111),
        'F' to intArrayOf(0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b10000),
        'G' to intArrayOf(0b01110, 0b10001, 0b10000, 0b10111, 0b10001, 0b10001, 0b01111),
        'H' to intArrayOf(0b10001, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001),
        'I' to intArrayOf(0b01110, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110),
        'J' to intArrayOf(0b00111, 0b00010, 0b00010, 0b00010, 0b00010, 0b10010, 0b01100),
        'K' to intArrayOf(0b10001, 0b10010, 0b10100, 0b11000, 0b10100, 0b10010, 0b10001),
        'L' to intArrayOf(0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11111),
        'M' to intArrayOf(0b10001, 0b11011, 0b10101, 0b10101, 0b10001, 0b10001, 0b10001),
        'N' to intArrayOf(0b10001, 0b11001, 0b10101, 0b10011, 0b10001, 0b10001, 0b10001),
        'O' to intArrayOf(0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110),
        'P' to intArrayOf(0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000),
        'Q' to intArrayOf(0b01110, 0b10001, 0b10001, 0b10001, 0b10101, 0b10010, 0b01101),
        'R' to intArrayOf(0b11110, 0b10001, 0b10001, 0b11110, 0b10100, 0b10010, 0b10001),
        'S' to intArrayOf(0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110),
        'T' to intArrayOf(0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100),
        'U' to intArrayOf(0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110),
        'V' to intArrayOf(0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01010, 0b00100),
        'W' to intArrayOf(0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b10101, 0b01010),
        'X' to intArrayOf(0b10001, 0b10001, 0b01010, 0b00100, 0b01010, 0b10001, 0b10001),
        'Y' to intArrayOf(0b10001, 0b10001, 0b01010, 0b00100, 0b00100, 0b00100, 0b00100),
        'Z' to intArrayOf(0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0b11111),
        // 符号
        '.' to intArrayOf(0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b01100, 0b01100),
        '-' to intArrayOf(0b00000, 0b00000, 0b00000, 0b11111, 0b00000, 0b00000, 0b00000),
        ':' to intArrayOf(0b00000, 0b01100, 0b01100, 0b00000, 0b01100, 0b01100, 0b00000),
        '/' to intArrayOf(0b00001, 0b00010, 0b00010, 0b00100, 0b01000, 0b01000, 0b10000),
        ' ' to intArrayOf(0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000, 0b00000),
    )

    /** 绘制一段文字（不含换行），左上角为 (x, y)，[scale] 为每个点阵像素的边长。 */
    fun drawText(canvas: Canvas, text: String, x: Float, y: Float, scale: Float, color: Int) {
        val paint = Paint().apply {
            this.color = color
            isAntiAlias = false
            isFilterBitmap = false
            style = Paint.Style.FILL
        }
        var cx = x
        for (ch in text) {
            val glyph = glyphs[ch] ?: glyphs[' ']!!
            for (row in 0 until CHAR_H) {
                val bits = glyph[row]
                for (col in 0 until CHAR_W) {
                    if ((bits and (1 shl (CHAR_W - 1 - col))) != 0) {
                        canvas.drawRect(
                            cx + col * scale,
                            y + row * scale,
                            cx + (col + 1) * scale,
                            y + (row + 1) * scale,
                            paint,
                        )
                    }
                }
            }
            cx += (CHAR_W + 1) * scale
        }
    }

    /** 文字渲染后的总宽度（含字符间距），用于右对齐。 */
    fun measureText(text: String, scale: Float): Float =
        text.length * (CHAR_W + 1) * scale - scale

    /**
     * 绘制一张任意像素位图（用于刀/心图标）。
     * [bitmap] 为 7 行字符串，每行等长；'#' 或 '1' 表示实心像素。
     */
    fun drawBitmap(
        canvas: Canvas,
        bitmap: Array<String>,
        x: Float,
        y: Float,
        scale: Float,
        color: Int,
    ) {
        val paint = Paint().apply {
            this.color = color
            isAntiAlias = false
            isFilterBitmap = false
            style = Paint.Style.FILL
        }
        for (row in bitmap.indices) {
            val line = bitmap[row]
            for (col in line.indices) {
                val c = line[col]
                if (c == '#' || c == '1') {
                    canvas.drawRect(
                        x + col * scale,
                        y + row * scale,
                        x + (col + 1) * scale,
                        y + (row + 1) * scale,
                        paint,
                    )
                }
            }
        }
    }

    /** 白色像素文字的便捷方法。 */
    fun drawTextWhite(canvas: Canvas, text: String, x: Float, y: Float, scale: Float) =
        drawText(canvas, text, x, y, scale, Color.WHITE)
}
