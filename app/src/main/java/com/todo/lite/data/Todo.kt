package com.todo.lite.data

import android.content.Context
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone

/** 一条待办。 */
data class Todo(
    val id: Long,
    val title: String,
    val note: String = "",
    val due: String = "",
    val done: Boolean = false,
    val createdAt: Long = 0L,
    val doneAt: Long = 0L,
)

/** 用 SharedPreferences + JSON 做本地持久化，不引入额外依赖。 */
class TodoStore(context: Context) {
    private val prefs = context.getSharedPreferences("todo_lite", Context.MODE_PRIVATE)

    fun load(): List<Todo> {
        val raw = prefs.getString(KEY, null) ?: return emptyList()
        return TodoJson.decode(raw)
    }

    fun save(items: List<Todo>) {
        // 本地存储用紧凑格式，减少每次写入的耗时
        prefs.edit().putString(KEY, TodoJson.encode(items, pretty = false)).apply()
    }

    private companion object {
        const val KEY = "items_v1"
    }
}

/** 本地存储与导入导出共用的 JSON 编解码。 */
object TodoJson {

    fun encode(items: List<Todo>, pretty: Boolean = true): String {
        val array = JSONArray()
        items.forEach { todo ->
            array.put(
                JSONObject().apply {
                    put("id", todo.id)
                    put("title", todo.title)
                    put("note", todo.note)
                    put("due", todo.due)
                    put("done", todo.done)
                    put("createdAt", todo.createdAt)
                    put("doneAt", todo.doneAt)
                }
            )
        }
        return if (pretty) array.toString(2) else array.toString()
    }

    /** 解析失败或结构不对时直接抛异常，由调用方提示。 */
    fun decode(raw: String): List<Todo> {
        val array = JSONArray(raw)
        return (0 until array.length()).map { index ->
            val o = array.getJSONObject(index)
            val id = o.optLong("id", 0L)
            require(id > 0L) { "缺少有效的 id" }
            Todo(
                id = id,
                title = o.optString("title"),
                note = o.optString("note"),
                due = o.optString("due"),
                done = o.optBoolean("done"),
                createdAt = o.optLong("createdAt"),
                doneAt = o.optLong("doneAt"),
            )
        }
    }
}

/**
 * 截止日期的解析：兼容「今天 / 明天 / 后天 / 11月29日」这几种本地写法。
 * 解析结果按日期文本做缓存，列表滚动时不会反复创建 Calendar 和正则。
 */
object Due {
    private const val DAY_MILLIS = 86_400_000L
    private val PATTERN = Regex("""(\d{1,2})月(\d{1,2})日""")

    private var cachedTodayKey = Long.MIN_VALUE
    private var cachedToday = 0L

    /** 缓存文本 → 当天零点时间戳；跨天时整体失效。 */
    private val cache = HashMap<String, Long?>()

    /** 换算成当天零点的时间戳，用于排序和逾期判断；无法识别时返回 null。
     *  主线程（列表排序）和 IO 线程（提醒重排）都会调用，加锁保护解析缓存。 */
    @Synchronized
    fun dayOf(text: String): Long? {
        val value = text.trim()
        if (value.isEmpty()) return null
        ensureToday()
        cache[value]?.let { return it }
        val result = parse(value)
        cache[value] = result
        return result
    }

    /** 距离今天还有几天，负数表示已逾期。 */
    fun daysUntil(text: String): Int? =
        dayOf(text)?.let { ((it - startOfToday()) / DAY_MILLIS).toInt() }

    private fun parse(value: String): Long? {
        val calendar = Calendar.getInstance()
        when (value) {
            "今天" -> Unit
            "明天" -> calendar.add(Calendar.DAY_OF_YEAR, 1)
            "后天" -> calendar.add(Calendar.DAY_OF_YEAR, 2)
            else -> {
                val match = PATTERN.find(value) ?: return null
                val month = match.groupValues[1].toIntOrNull() ?: return null
                val day = match.groupValues[2].toIntOrNull() ?: return null
                if (month !in 1..12 || day !in 1..31) return null
                calendar.set(Calendar.MONTH, month - 1)
                calendar.set(Calendar.DAY_OF_MONTH, day)
                // 跨年场景：「1月3日」写在年底时按明年算
                if (calendar.timeInMillis < startOfToday() - 180 * DAY_MILLIS) {
                    calendar.add(Calendar.YEAR, 1)
                }
            }
        }
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }

    private fun startOfToday(): Long {
        ensureToday()
        return cachedToday
    }

    /** 日期变化时刷新「今天」并清空解析缓存；key 用本地日序号，不创建对象。 */
    private fun ensureToday() {
        val now = System.currentTimeMillis()
        val key = (now + TimeZone.getDefault().getOffset(now)) / DAY_MILLIS
        if (key != cachedTodayKey) {
            cachedTodayKey = key
            cachedToday = parseStartOfToday()
            cache.clear()
        }
    }

    private fun parseStartOfToday(): Long {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }
}

/** 待办数据的唯一状态源，任何修改都会立即写入本地。 */
class TodoState(private val store: TodoStore, private val appContext: Context) {
    var items by mutableStateOf(store.load())
        private set

    /** 写盘放到单线程后台，避免主线程做 JSON 编码造成掉帧。 */
    private val saveScope = CoroutineScope(SupervisorJob() + Dispatchers.IO.limitedParallelism(1))

    /** 未完成：有截止日期的按到期先后排前面，其余按创建时间倒序。 */
    val pending: List<Todo> by derivedStateOf {
        items.filter { !it.done }
            .sortedWith(
                compareBy<Todo> { Due.dayOf(it.due) ?: Long.MAX_VALUE }
                    .thenByDescending { it.createdAt }
            )
    }

    val done: List<Todo> by derivedStateOf {
        items.filter { it.done }.sortedByDescending { it.doneAt }
    }

    fun add(title: String, note: String, due: String) {
        val now = System.currentTimeMillis()
        val todo = Todo(
            id = now,
            title = title.trim(),
            note = note.trim(),
            due = due,
            createdAt = now,
        )
        commit(items + todo)
    }

    fun update(id: Long, title: String, note: String, due: String) {
        commit(
            items.map {
                if (it.id == id) it.copy(title = title.trim(), note = note.trim(), due = due) else it
            }
        )
    }

    fun toggle(id: Long) {
        val now = System.currentTimeMillis()
        commit(
            items.map {
                if (it.id != id) it else {
                    val next = !it.done
                    it.copy(done = next, doneAt = if (next) now else 0L)
                }
            }
        )
    }

    fun remove(id: Long) {
        commit(items.filterNot { it.id == id })
    }

    /** 撤销删除：同 id 不存在时放回，返回是否恢复成功。 */
    fun restore(todo: Todo): Boolean {
        if (items.any { it.id == todo.id }) return false
        commit(items + todo)
        return true
    }

    fun clearDone() {
        commit(items.filterNot { it.done })
    }

    fun clearAll() {
        commit(emptyList())
    }

    /** 导出为 JSON 文本，供「导出数据」写文件使用。 */
    fun exportJson(): String = TodoJson.encode(items)

    /** 合并导入：按 id 去重，保留本地已有记录，返回新增条数。 */
    fun importJson(raw: String): Int {
        val incoming = TodoJson.decode(raw)
        val merged = LinkedHashMap<Long, Todo>()
        items.forEach { merged[it.id] = it }
        var added = 0
        incoming.forEach { todo ->
            if (!merged.containsKey(todo.id)) {
                merged[todo.id] = todo
                added++
            }
        }
        if (added > 0) {
            commit(merged.values.sortedByDescending { it.createdAt })
        }
        return added
    }

    private fun commit(next: List<Todo>) {
        items = next
        saveScope.launch {
            store.save(next)
            // 数据变化后按新列表重排截止提醒
            ReminderScheduler.rescheduleAll(appContext)
        }
    }
}
