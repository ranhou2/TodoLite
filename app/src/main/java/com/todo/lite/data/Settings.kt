package com.todo.lite.data

import android.content.Context
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb

/** 轻量设置存储：保存主题色和首次启动标记。 */
class SettingsStore(context: Context) {
    private val prefs = context.getSharedPreferences("todo_lite_settings", Context.MODE_PRIVATE)

    fun loadAccent(): Color = Color(prefs.getInt(KEY_ACCENT, DEFAULT_ACCENT))

    fun saveAccent(color: Color) {
        prefs.edit().putInt(KEY_ACCENT, color.toArgb()).apply()
    }

    /** 是否已经看过首次启动的介绍弹窗。 */
    fun hasSeenWelcome(): Boolean = prefs.getBoolean(KEY_WELCOME, false)

    fun markWelcomeSeen() {
        prefs.edit().putBoolean(KEY_WELCOME, true).apply()
    }

    /** 截止前提醒提前量（分钟），0 表示不提醒。 */
    fun loadRemindLead(): Long = prefs.getLong(KEY_REMIND_LEAD, 0L)

    fun saveRemindLead(minutes: Long) {
        prefs.edit().putLong(KEY_REMIND_LEAD, minutes).apply()
    }

    private companion object {
        const val KEY_ACCENT = "accent"
        const val KEY_WELCOME = "welcome_seen_v1"
        const val KEY_REMIND_LEAD = "remind_lead_minutes"
        val DEFAULT_ACCENT = 0xFF0A84FF.toInt()
    }
}
