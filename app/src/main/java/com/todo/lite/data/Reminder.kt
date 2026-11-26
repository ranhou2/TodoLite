package com.todo.lite.data

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.todo.lite.MainActivity
import com.todo.lite.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/** 截止前提醒的可选提前量（分钟），0 表示不提醒。 */
val RemindLeadOptions = listOf(0L, 30L, 60L, 360L, 1440L, 2880L)

/** 提前量对应的展示文案。 */
fun remindLabel(minutes: Long): String = when (minutes) {
    0L -> "不提醒"
    30L -> "提前 30 分钟"
    60L -> "提前 1 小时"
    360L -> "提前 6 小时"
    1440L -> "提前 1 天"
    2880L -> "提前 2 天"
    else -> "提前 $minutes 分钟"
}

private const val EXTRA_TODO_ID = "todo_id"
private const val CHANNEL_ID = "due_reminders"
private const val DAY_MILLIS = 86_400_000L

/**
 * 截止提醒调度：截止日当天结束（24:00）前提前量时刻用 AlarmManager 唤醒发通知。
 * 每次数据或设置变化都整体重排；重启后由 BootReceiver 补排。
 */
object ReminderScheduler {
    private const val REMIND_PREF = "todo_remind"
    private const val KEY_SCHEDULED = "scheduled_v1"

    fun rescheduleAll(context: Context) {
        val app = context.applicationContext
        val lead = SettingsStore(app).loadRemindLead()
        val todos = TodoStore(app).load()
        val wanted = HashMap<Long, Long>()
        if (lead > 0L) {
            val now = System.currentTimeMillis()
            todos.forEach { todo ->
                if (todo.done) return@forEach
                // 截止按「当天结束」计算：11月27日 → 27 日 24:00
                val dayEnd = Due.dayOf(todo.due)?.plus(DAY_MILLIS) ?: return@forEach
                val remindAt = dayEnd - lead * 60_000L
                if (remindAt > now) wanted[todo.id] = remindAt
            }
        }
        val prefs = app.getSharedPreferences(REMIND_PREF, Context.MODE_PRIVATE)
        val previous = prefs.getStringSet(KEY_SCHEDULED, emptySet())
            ?.mapNotNull { it.toLongOrNull() }
            ?.toSet()
            ?: emptySet()
        val am = app.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // 先取消已不在列表里的旧闹钟，再排新的
        previous.filterNot { it in wanted }.forEach { id -> am.cancel(pendingIntent(app, id)) }
        wanted.forEach { (id, at) -> schedule(app, am, id, at) }
        prefs.edit()
            .putStringSet(KEY_SCHEDULED, wanted.keys.map { it.toString() }.toSet())
            .apply()
    }

    private fun pendingIntent(context: Context, id: Long): PendingIntent {
        val intent = Intent(context, ReminderAlarmReceiver::class.java)
            .putExtra(EXTRA_TODO_ID, id)
        return PendingIntent.getBroadcast(
            context,
            (id and 0x7FFFFFFFL).toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun schedule(context: Context, am: AlarmManager, id: Long, at: Long) {
        val pi = pendingIntent(context, id)
        // 未授予精确闹钟权限时退化为非精确（最多延迟十几分钟），不申请额外特权
        val exact = Build.VERSION.SDK_INT < 31 || am.canScheduleExactAlarms()
        if (exact) am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
        else am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
    }
}

/** 到点弹通知：按 id 找回待办内容，发一条高优先级横幅通知。 */
class ReminderAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getLongExtra(EXTRA_TODO_ID, 0L)
        if (id <= 0L) return
        val todo = TodoStore(context).load().firstOrNull { it.id == id } ?: return
        if (todo.done) return
        notifyDue(context, todo)
    }
}

/** 开机完成后按当前设置重排提醒。 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val pending = goAsync()
        CoroutineScope(Dispatchers.Default).launch {
            try {
                ReminderScheduler.rescheduleAll(context)
            } finally {
                pending.finish()
            }
        }
    }
}

/** 发截止提醒通知；未授予通知权限时静默跳过。 */
private fun notifyDue(context: Context, todo: Todo) {
    if (Build.VERSION.SDK_INT >= 33 &&
        ContextCompat.checkSelfPermission(
            context, android.Manifest.permission.POST_NOTIFICATIONS,
        ) != PackageManager.PERMISSION_GRANTED
    ) {
        return
    }
    val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    manager.createNotificationChannel(
        NotificationChannel(CHANNEL_ID, "截止提醒", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "待办截止前的弹窗提醒"
        },
    )
    val contentIntent = PendingIntent.getActivity(
        context,
        0,
        Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
    val notification = NotificationCompat.Builder(context, CHANNEL_ID)
        .setSmallIcon(R.drawable.ic_notification)
        .setContentTitle("待办即将截止")
        .setContentText("「${todo.title}」· 截止：${todo.due}")
        .setAutoCancel(true)
        .setContentIntent(contentIntent)
        .setPriority(NotificationCompat.PRIORITY_HIGH)
        .setCategory(NotificationCompat.CATEGORY_REMINDER)
        .build()
    manager.notify((todo.id and 0x7FFFFFFFL).toInt(), notification)
}
