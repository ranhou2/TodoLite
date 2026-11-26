package com.todo.lite.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.todo.lite.data.Todo
import ui.feice.mochi.basic.MochiBarIconButton
import ui.feice.mochi.basic.MochiChip
import ui.feice.mochi.basic.MochiSheetContent
import ui.feice.mochi.basic.MochiSheetHeader
import ui.feice.mochi.basic.MochiTextField
import ui.feice.mochi.icons.MochiIonicon
import ui.feice.mochi.picker.MochiCalendar
import ui.feice.mochi.picker.MochiDate
import ui.feice.mochi.picker.MochiDateSelection
import ui.feice.mochi.picker.toLocalDate
import java.time.LocalDate
import java.util.Calendar

/** 打开编辑页的请求：新建或者编辑某一条。 */
sealed interface EditorRequest {
    data object New : EditorRequest
    data class Edit(val todo: Todo) : EditorRequest
}

/** 新建/编辑表单，作为 MochiSheet 的内容使用。 */
@Composable
fun TodoEditorContent(
    request: EditorRequest,
    onClose: () -> Unit,
    onSubmit: (title: String, note: String, due: String) -> Unit,
    onDelete: () -> Unit,
) {
    val original = (request as? EditorRequest.Edit)?.todo
    var title by remember { mutableStateOf(original?.title.orEmpty()) }
    var note by remember { mutableStateOf(original?.note.orEmpty()) }
    var due by remember { mutableStateOf(original?.due.orEmpty()) }
    var confirmDelete by remember { mutableStateOf(false) }
    var showCalendar by remember { mutableStateOf(false) }
    val canSave = title.isNotBlank()

    LaunchedEffect(confirmDelete) {
        if (confirmDelete) {
            kotlinx.coroutines.delay(3000)
            confirmDelete = false
        }
    }

    MochiSheetHeader(
        if (original == null) "新建待办" else "编辑待办",
        navigationIcon = {
            MochiBarIconButton(onClick = onClose) {
                MochiIonicon("close", size = 20.dp)
            }
        },
    )

    MochiSheetContent {
        Column(modifier = Modifier.fillMaxWidth()) {
            GroupTitle("标题", topPadding = 0.dp)
            Spacer(Modifier.height(8.dp))
            FieldBox(
                value = title,
                onValueChange = { if (it.length <= 60) title = it },
                placeholder = "要做什么？",
            )

            Spacer(Modifier.height(18.dp))
            GroupTitle("备注", topPadding = 0.dp)
            Spacer(Modifier.height(8.dp))
            FieldBox(
                value = note,
                onValueChange = { if (it.length <= 300) note = it },
                placeholder = "补充说明（可选）",
                singleLine = false,
            )

            Spacer(Modifier.height(18.dp))
            GroupTitle("截止日期", topPadding = 0.dp)
            Spacer(Modifier.height(10.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                val weekend = weekendDue()
                val presetValues = listOf("", "今天", "明天", weekend)
                val presets = listOf(
                    "" to "无截止",
                    "今天" to "今天",
                    "明天" to "明天",
                    weekend to "本周末",
                )
                presets.forEach { (value, label) ->
                    DueChip(label, due == value) { due = value }
                }
                // 自定义日期：选中预设以外的日期时直接显示该日期
                val isCustom = due.isNotEmpty() && due !in presetValues
                DueChip(if (isCustom) due else "自定义", isCustom) {
                    showCalendar = !showCalendar
                }
            }

            // 麻薯日历：选择自定义截止日期，展开/收起带弹簧动画
            AnimatedVisibility(
                visible = showCalendar,
                enter = expandVertically(
                    animationSpec = spring(dampingRatio = 0.85f, stiffness = 380f),
                ) + fadeIn(tween(180)),
                exit = shrinkVertically(
                    animationSpec = spring(dampingRatio = 0.85f, stiffness = 380f),
                ) + fadeOut(tween(140)),
            ) {
                var selection by remember(showCalendar) {
                    mutableStateOf<MochiDateSelection>(initialSelection(due))
                }
                // 只有用户真正点选了日期才写入，避免初始选中项（今天）立刻触发收起
                var userPicked by remember(showCalendar) { mutableStateOf(false) }
                LaunchedEffect(selection) {
                    if (!userPicked) return@LaunchedEffect
                    val picked = (selection as? MochiDateSelection.Single)?.date ?: return@LaunchedEffect
                    val date = picked.toLocalDate()
                    due = "${date.monthValue}月${date.dayOfMonth}日"
                    showCalendar = false
                }
                MochiCalendar(
                    selection = selection,
                    onSelectionChange = {
                        userPicked = true
                        selection = it
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 12.dp),
                )
            }

            Spacer(Modifier.height(26.dp))
            PillButton(
                text = "保存",
                modifier = Modifier.fillMaxWidth(),
                enabled = canSave,
                onClick = { onSubmit(title, note, due) },
            )

            if (original != null) {
                Spacer(Modifier.height(12.dp))
                DeleteButton(
                    confirming = confirmDelete,
                    onClick = {
                        if (confirmDelete) onDelete() else confirmDelete = true
                    },
                )
            }
            Spacer(Modifier.height(10.dp))
        }
    }
}

/** 删除按钮：第一次点击变成红色确认态，3 秒内再次点击才执行删除。 */
@Composable
private fun DeleteButton(confirming: Boolean, onClick: () -> Unit) {
    val bg by animateColorAsState(
        targetValue = if (confirming) Ink.Red else Ink.Red.copy(alpha = 0.12f),
        animationSpec = spring(dampingRatio = 0.8f, stiffness = 600f),
        label = "deleteBg",
    )
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .clip(RoundedCornerShape(26.dp))
            .background(bg)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        T(
            if (confirming) "再次点击确认删除" else "删除这条待办",
            size = 17,
            weight = FontWeight.SemiBold,
            color = if (confirming) Color.White else Ink.Red,
        )
    }
}

/** 输入框，使用 Mochi 的 MochiTextField（单行 48dp 胶囊，多行自动增高）。 */
@Composable
private fun FieldBox(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    singleLine: Boolean = true,
) {
    MochiTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = Modifier.fillMaxWidth(),
        placeholder = placeholder,
        singleLine = singleLine,
        maxLines = if (singleLine) 1 else 4,
    )
}

@Composable
private fun DueChip(label: String, selected: Boolean, onClick: () -> Unit) {
    MochiChip(
        label = label,
        selected = selected,
        onClick = onClick,
    )
}

/** 最近的周日，返回 “11月29日” 这样的文案。 */
private fun weekendDue(): String {
    val now = Calendar.getInstance()
    val dow = now.get(Calendar.DAY_OF_WEEK)
    val daysToSunday = if (dow == Calendar.SUNDAY) 0 else 8 - dow
    val target = now.clone() as Calendar
    target.add(Calendar.DAY_OF_YEAR, daysToSunday)
    return "${target.get(Calendar.MONTH) + 1}月${target.get(Calendar.DAY_OF_MONTH)}日"
}

/** 把已有 due 文案（“11月29日”）解析为日历初始选中项，无法识别时定位到今天。 */
private fun initialSelection(due: String): MochiDateSelection {
    val match = Regex("""(\d{1,2})月(\d{1,2})日""").find(due)
    val month = match?.groupValues?.get(1)?.toIntOrNull()
    val day = match?.groupValues?.get(2)?.toIntOrNull()
    val date = if (month != null && day != null && month in 1..12 && day in 1..31) {
        runCatching {
            MochiDate.fromLocalDate(LocalDate.of(LocalDate.now().year, month, day))
        }.getOrElse { MochiDate.today() }
    } else {
        MochiDate.today()
    }
    return MochiDateSelection.Single(date)
}
