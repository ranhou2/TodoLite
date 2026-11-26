package com.todo.lite.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animate
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.Orientation
import androidx.compose.foundation.gestures.draggable
import androidx.compose.foundation.gestures.rememberDraggableState
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.todo.lite.data.Due
import com.todo.lite.data.Todo
import com.todo.lite.data.TodoState
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt
import ui.feice.mochi.icons.MochiIonicon

@Composable
fun TodoScreen(
    state: TodoState,
    onSelectTab: (Int) -> Unit,
    onAdd: () -> Unit,
    onOpen: (Todo) -> Unit,
    onToggle: (Todo) -> Unit,
    onDelete: (Todo) -> Unit,
) {
    val pending = state.pending
    val done = state.done
    val overdue = pending.count { (Due.daysUntil(it.due) ?: 0) < 0 }
    val subtitle = when {
        state.items.isEmpty() -> "还没有待办，先写下第一件事"
        pending.isEmpty() -> "全部完成，给自己一点奖励"
        overdue > 0 -> "有 $overdue 项已逾期，先处理它们"
        else -> "还有 ${pending.size} 项待完成"
    }

    AppScaffold(
        title = "待办",
        subtitle = subtitle,
        selectedTab = 0,
        onSelectTab = onSelectTab,
        showVersion = true,
        floating = { FabButton(onClick = onAdd) },
    ) {
        when {
            state.items.isEmpty() -> item {
                EmptyCard(
                    icon = "list",
                    tint = Ink.Blue,
                    title = "开始今天的清单",
                    desc = "点右下角的 + 新建一条待办。",
                )
            }
            pending.isEmpty() -> item {
                EmptyCard(
                    icon = "checkmark-done-circle",
                    tint = Ink.Green,
                    title = "任务都完成了",
                    desc = "新增一条，或去「完成」查看记录。",
                )
            }
            else -> {
                item { GroupTitle("待完成 · ${pending.size}") }
                itemsIndexed(
                    items = pending,
                    key = { _, todo -> todo.id },
                ) { index, todo ->
                    TodoRowItem(
                        modifier = Modifier.animateItem(
                            fadeInSpec = spring(dampingRatio = 0.9f, stiffness = 500f),
                            placementSpec = spring(dampingRatio = 0.9f, stiffness = 500f),
                            fadeOutSpec = tween(durationMillis = 140),
                        ),
                        shape = groupShape(index, pending.size),
                        showDivider = index != pending.lastIndex,
                        todo = todo,
                        onToggle = { onToggle(todo) },
                        onClick = { onOpen(todo) },
                        onDelete = { onDelete(todo) },
                    )
                }
            }
        }

        if (done.isNotEmpty()) {
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onSelectTab(1) }
                        .padding(horizontal = 4.dp, vertical = 2.dp)
                        .padding(top = 14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    T("已完成 ${done.size} 项", size = 14, color = Ink.Sub)
                    Spacer(Modifier.weight(1f))
                    MochiIonicon("chevron-forward", size = 16.dp, tint = Ink.Chevron)
                }
            }
        }
    }
}

@Composable
fun DoneScreen(
    state: TodoState,
    onSelectTab: (Int) -> Unit,
    onToggle: (Todo) -> Unit,
    onOpen: (Todo) -> Unit,
    onDelete: (Todo) -> Unit,
) {
    val done = state.done

    AppScaffold(
        title = "完成",
        subtitle = if (done.isEmpty()) "还没有完成的任务" else "共完成 ${done.size} 项，继续保持",
        selectedTab = 1,
        onSelectTab = onSelectTab,
    ) {
        if (done.isEmpty()) {
            item {
                EmptyCard(
                    icon = "checkmark-done-circle",
                    tint = Ink.Green,
                    title = "这里空空的",
                    desc = "勾选待办后，任务会出现在这里。",
                )
            }
        } else {
            item { GroupTitle("已完成 · ${done.size}") }
            itemsIndexed(
                items = done,
                key = { _, todo -> todo.id },
            ) { index, todo ->
                TodoRowItem(
                    modifier = Modifier.animateItem(
                        fadeInSpec = spring(dampingRatio = 0.9f, stiffness = 500f),
                        placementSpec = spring(dampingRatio = 0.9f, stiffness = 500f),
                        fadeOutSpec = tween(durationMillis = 140),
                    ),
                    shape = groupShape(index, done.size),
                    showDivider = index != done.lastIndex,
                    todo = todo,
                    onToggle = { onToggle(todo) },
                    onClick = { onOpen(todo) },
                    onDelete = { onDelete(todo) },
                )
            }
            item {
                T(
                    "轻点圆圈可以把任务放回待办",
                    size = 13,
                    color = Ink.Hint,
                    modifier = Modifier
                        .padding(horizontal = 4.dp)
                        .padding(top = 14.dp),
                )
            }
        }
    }
}

/**
 * 单条列表行：作为 LazyColumn 的独立 item，由 animateItem 负责
 * 出现、移动和移除的动画（与 iOS / Mochi 列表一致的顺滑手感）。
 */
@Composable
private fun TodoRowItem(
    modifier: Modifier = Modifier,
    shape: Shape,
    showDivider: Boolean,
    todo: Todo,
    onToggle: () -> Unit,
    onClick: () -> Unit,
    onDelete: () -> Unit,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(Ink.Card),
    ) {
        SwipeToDelete(onDelete = onDelete) {
            TodoRow(todo = todo, onToggle = onToggle, onClick = onClick)
        }
        if (showDivider) RowDivider(inset = 56.dp)
    }
}

/** 分组行圆角：首行带上圆角、末行带下圆角，中间直角，拼成一张完整卡片。 */
private fun groupShape(index: Int, count: Int): Shape {
    val r = 26.dp
    return when {
        count == 1 -> RoundedCornerShape(r)
        index == 0 -> RoundedCornerShape(topStart = r, topEnd = r)
        index == count - 1 -> RoundedCornerShape(bottomStart = r, bottomEnd = r)
        else -> RoundedCornerShape(0.dp)
    }
}

/** 左滑露出红色删除区，滑过阈值或快速左滑即删除。 */
@Composable
private fun SwipeToDelete(onDelete: () -> Unit, content: @Composable () -> Unit) {
    val haptics = LocalHapticFeedback.current
    val revealPx = with(LocalDensity.current) { 88.dp.toPx() }
    var offset by remember { mutableFloatStateOf(0f) }
    var width by remember { mutableIntStateOf(0) }
    val maxDrag = if (width > 0) width.toFloat() else revealPx * 3

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .onSizeChanged { width = it.width },
    ) {
        Box(
            modifier = Modifier
                .matchParentSize()
                .background(Ink.Red),
            contentAlignment = Alignment.CenterEnd,
        ) {
            val progress = (-offset / revealPx).coerceIn(0f, 1f)
            Box(
                modifier = Modifier
                    .padding(end = 24.dp)
                    .graphicsLayer {
                        alpha = progress
                        scaleX = 0.75f + 0.25f * progress
                        scaleY = 0.75f + 0.25f * progress
                    },
            ) {
                MochiIonicon("trash", size = 20.dp, tint = Color.White)
            }
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .offset { IntOffset(offset.roundToInt(), 0) }
                .background(Ink.Card)
                .draggable(
                    state = rememberDraggableState { delta ->
                        offset = (offset + delta).coerceIn(-maxDrag, 0f)
                    },
                    orientation = Orientation.Horizontal,
                    onDragStopped = { velocity ->
                        val shouldDelete = offset < -revealPx || velocity < -900f
                        if (shouldDelete) {
                            haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                            animate(
                                initialValue = offset,
                                targetValue = -maxDrag,
                                animationSpec = tween(durationMillis = 160),
                            ) { value, _ -> offset = value }
                            onDelete()
                        } else {
                            animate(
                                initialValue = offset,
                                targetValue = 0f,
                                animationSpec = spring(dampingRatio = 0.72f, stiffness = 380f),
                            ) { value, _ -> offset = value }
                        }
                    },
                ),
        ) {
            content()
        }
    }
}

@Composable
private fun TodoRow(todo: Todo, onToggle: () -> Unit, onClick: () -> Unit) {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val rowBg by animateColorAsState(
        targetValue = if (pressed) Ink.Divider.copy(alpha = 0.7f) else Color.Transparent,
        animationSpec = tween(120),
        label = "rowPress",
    )
    val rowScale by animateFloatAsState(
        targetValue = if (pressed) 0.985f else 1f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = 600f),
        label = "rowScale",
    )
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .graphicsLayer {
                scaleX = rowScale
                scaleY = rowScale
            }
            .background(rowBg)
            .clickable(
                interactionSource = interaction,
                indication = null,
                onClick = onClick,
            )
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CheckCircle(checked = todo.done, onClick = onToggle)
        Spacer(Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f)) {
            T(
                todo.title,
                size = 16,
                weight = FontWeight.Medium,
                color = if (todo.done) Ink.Sub else Ink.Text,
                maxLines = 2,
                strikethrough = todo.done,
            )
            val meta = remember(todo) { rowMeta(todo) }
            if (meta != null) {
                Spacer(Modifier.height(3.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (meta.dueText != null) {
                        val dueColor = when (meta.dueLevel) {
                            -1 -> Ink.Red
                            0, 1 -> Ink.Orange
                            else -> Ink.Blue
                        }
                        T(meta.dueText, size = 13, color = dueColor)
                        if (meta.note.isNotEmpty()) T(" · ", size = 13, color = Ink.Hint)
                    }
                    if (meta.note.isNotEmpty()) {
                        T(meta.note, size = 13, color = Ink.Sub, maxLines = 1)
                    }
                }
            }
        }
        Spacer(Modifier.width(8.dp))
        MochiIonicon("chevron-forward", size = 16.dp, tint = Ink.Chevron)
    }
}

/** 行内次级信息：截止日期（按紧迫程度着色）加上备注，已完成显示完成时间。 */
private class RowMeta(val dueText: String?, val dueLevel: Int, val note: String)

/** 紧迫程度：-1 逾期，0 今天，1 明天，2 普通。 */
private fun rowMeta(todo: Todo): RowMeta? {
    val dueText: String?
    val dueLevel: Int
    if (todo.done || todo.due.isEmpty()) {
        dueText = null
        dueLevel = 2
    } else {
        val days = Due.daysUntil(todo.due)
        when {
            days == null -> {
                dueText = "截止 ${todo.due}"
                dueLevel = 2
            }
            days < 0 -> {
                dueText = "已逾期"
                dueLevel = -1
            }
            days == 0 -> {
                dueText = "今天到期"
                dueLevel = 0
            }
            days == 1 -> {
                dueText = "明天到期"
                dueLevel = 1
            }
            else -> {
                dueText = "截止 ${todo.due}"
                dueLevel = 2
            }
        }
    }
    val note = when {
        todo.note.isNotEmpty() -> todo.note
        todo.done && todo.doneAt > 0L -> "完成于 ${formatDay(todo.doneAt)}"
        else -> ""
    }
    if (dueText == null && note.isEmpty()) return null
    return RowMeta(dueText, dueLevel, note)
}

/** 只在主线程使用，复用同一个格式化实例，避免每次创建。 */
private val DayFormat = SimpleDateFormat("M月d日", Locale.CHINA)

private fun formatDay(millis: Long): String = DayFormat.format(Date(millis))
