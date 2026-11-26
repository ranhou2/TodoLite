package com.todo.lite.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.heightIn
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.State
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalDensity
import kotlin.math.roundToInt
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import ui.feice.mochi.basic.MochiButton
import ui.feice.mochi.basic.MochiButtonStyle
import ui.feice.mochi.basic.MochiCheckbox
import ui.feice.mochi.basic.MochiEmptyState
import ui.feice.mochi.icons.MochiIconStyle
import ui.feice.mochi.icons.MochiIonicon

/** 参考 App「趣智 Lite」的配色，主色可在「我的 → 外观」里切换。 */
object Ink {
    var Accent by mutableStateOf(Color(0xFF0A84FF))
    val Blue: Color get() = Accent

    val Purple = Color(0xFF6E5BE8)
    val Red = Color(0xFFFF3B30)
    val Green = Color(0xFF34C759)
    val Orange = Color(0xFFF2994A)
    val Bg = Color(0xFFF2F2F7)
    val Card = Color(0xFFFFFFFF)
    val Fill = Color(0xFFE6E6EB)
    val Text = Color(0xFF111114)
    val Sub = Color(0xFF8A8A8E)
    val Hint = Color(0xFFB0B0B6)
    val Chevron = Color(0xFFB7B7BC)
    val Divider = Color(0xFFEFEFF2)
    val TabBg = Color(0xFFF6F6F9)
    val TabSelected = Color(0xFFE4E4E9)
    val IconTint = Color(0xFF6D6D72)
}

val AppVersion = "v0.1.0"

@Composable
fun T(
    text: String,
    size: Int = 15,
    weight: FontWeight = FontWeight.Normal,
    color: Color = Ink.Text,
    modifier: Modifier = Modifier,
    textAlign: TextAlign? = null,
    maxLines: Int = Int.MAX_VALUE,
    strikethrough: Boolean = false,
) {
    BasicText(
        text = text,
        modifier = modifier,
        maxLines = maxLines,
        overflow = TextOverflow.Ellipsis,
        style = TextStyle(
            fontSize = size.sp,
            fontWeight = weight,
            color = color,
            lineHeight = (size * 1.45f).sp,
            textAlign = textAlign ?: TextAlign.Unspecified,
            textDecoration = if (strikethrough) TextDecoration.LineThrough else TextDecoration.None,
        ),
    )
}

@Composable
fun VersionChip() {
    Box(
        modifier = Modifier
            .clip(CircleShape)
            .background(Ink.Fill)
            .padding(horizontal = 12.dp, vertical = 5.dp),
    ) {
        T(AppVersion, size = 13, weight = FontWeight.Medium)
    }
}

/** 页面骨架：浅灰底 + 随滚动收起的大标题 + 可选悬浮操作按钮 + 悬浮胶囊 TabBar。 */
@Composable
fun AppScaffold(
    title: String,
    subtitle: String,
    selectedTab: Int,
    onSelectTab: (Int) -> Unit,
    showVersion: Boolean = false,
    navIcon: (@Composable () -> Unit)? = null,
    floating: (@Composable BoxScope.() -> Unit)? = null,
    content: LazyListScope.() -> Unit,
) {
    val listState = rememberLazyListState()
    val collapse = remember {
        derivedStateOf {
            if (listState.firstVisibleItemIndex > 0) 1f
            else (listState.firstVisibleItemScrollOffset / 150f).coerceIn(0f, 1f)
        }
    }
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Ink.Bg),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding(),
        ) {
            CollapsingHeader(
                title = title,
                subtitle = subtitle,
                showVersion = showVersion,
                collapse = collapse,
                navIcon = navIcon,
            )
            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                state = listState,
                contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 18.dp, bottom = 150.dp),
                verticalArrangement = Arrangement.spacedBy(0.dp),
                content = content,
            )
        }
        if (floating != null) {
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(end = 20.dp, bottom = 100.dp),
                content = floating,
            )
        }
        BottomTabBar(
            selected = selectedTab,
            onSelect = onSelectTab,
            modifier = Modifier.align(Alignment.BottomCenter),
        )
    }
}

/**
 * 大标题头部：往下滚动时标题平滑缩小，副标题淡出。
 * 缩放和透明度全部走 graphicsLayer，滚动过程零重组，保证丝滑不卡顿。
 */
@Composable
private fun CollapsingHeader(
    title: String,
    subtitle: String,
    showVersion: Boolean,
    collapse: State<Float>,
    navIcon: (@Composable () -> Unit)?,
) {
    // 布局相关的折叠状态只在跨越阈值时重组一次，避免滚动期间每帧重组
    val compact by remember { derivedStateOf { collapse.value > 0.5f } }
    Column(modifier = Modifier.padding(horizontal = 16.dp)) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(34.dp),
        ) {
            if (navIcon != null) {
                Box(modifier = Modifier.align(Alignment.CenterStart)) { navIcon() }
            }
            if (showVersion) {
                Box(
                    modifier = Modifier
                        .align(Alignment.CenterEnd)
                        .graphicsLayer {
                            val c = collapse.value
                            alpha = 1f - (c * 1.6f).coerceIn(0f, 1f)
                            scaleX = 1f - 0.08f * c
                            scaleY = 1f - 0.08f * c
                        },
                ) {
                    VersionChip()
                }
            }
        }
        Spacer(Modifier.height(if (compact) 10.dp else 16.dp))
        Box(
            modifier = Modifier.height(48.dp),
            contentAlignment = Alignment.CenterStart,
        ) {
            T(
                title,
                size = 34,
                weight = FontWeight.Black,
                modifier = Modifier.graphicsLayer {
                    val c = collapse.value
                    val s = 1f - 0.35f * c
                    scaleX = s
                    scaleY = s
                    transformOrigin = TransformOrigin(0f, 0.5f)
                },
            )
        }
        if (subtitle.isNotEmpty()) {
            Box(
                modifier = Modifier
                    .height(if (compact) 0.dp else 24.dp)
                    .clipToBounds(),
            ) {
                T(
                    subtitle,
                    size = 15,
                    color = Ink.Sub,
                    modifier = Modifier.graphicsLayer {
                        alpha = (1f - collapse.value * 2.4f).coerceIn(0f, 1f)
                    },
                )
            }
        }
    }
}

/**
 * 底栏（仿麻薯 demo）：白色胶囊、选中项为「图标 + 文字」横排在浅灰胶囊内，未选中只显示图标。
 * 支持两种切换方式：点按某个 tab；或按住底栏左右拖动，指示器跟手移动，松手停靠到最近的 tab 并切页。
 */
@Composable
fun BottomTabBar(
    selected: Int,
    onSelect: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val items = listOf("待办" to "list", "完成" to "checkmark-done-circle", "我的" to "person")
    val shape = RoundedCornerShape(29.dp)
    var dragging by remember { mutableStateOf(false) }
    var dragOffsetPx by remember { mutableFloatStateOf(0f) }
    var itemWidthPx by remember { mutableFloatStateOf(0f) }
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp)
            .navigationBarsPadding()
            .padding(bottom = 8.dp)
            .height(58.dp)
            .shadow(elevation = 6.dp, shape = shape)
            .clip(shape)
            .background(Ink.Card),
    ) {
        BoxWithConstraints(
            modifier = Modifier
                .fillMaxSize()
                .padding(5.dp)
                // 手势放在父层才能命中：按住底栏左右拖动，指示器跟手，松手停靠最近的 tab
                .pointerInput(Unit) {
                    detectHorizontalDragGestures(
                        onDragStart = {
                            dragging = true
                            dragOffsetPx = 0f
                        },
                        onHorizontalDrag = { change, amount ->
                            dragOffsetPx += amount
                            change.consume()
                        },
                        onDragEnd = {
                            dragging = false
                            val target = (selected + dragOffsetPx / itemWidthPx)
                                .roundToInt()
                                .coerceIn(0, items.size - 1)
                            if (target != selected) onSelect(target)
                            dragOffsetPx = 0f
                        },
                        onDragCancel = {
                            dragging = false
                            dragOffsetPx = 0f
                        },
                    )
                },
        ) {
            val density = LocalDensity.current
            val itemWidth = maxWidth / items.size
            itemWidthPx = with(density) { itemWidth.toPx() }

            // 停靠状态下的弹簧滑动；拖动中改为跟手位移
            val settledX by animateFloatAsState(
                targetValue = selected.toFloat(),
                animationSpec = spring(dampingRatio = 0.78f, stiffness = 420f),
                label = "tabIndicator",
            )
            val indicatorX = if (dragging) {
                (selected + dragOffsetPx / itemWidthPx).coerceIn(0f, (items.size - 1).toFloat())
            } else {
                settledX
            }
            Box(
                modifier = Modifier
                    .offset(x = itemWidth * indicatorX)
                    .width(itemWidth)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(24.dp))
                    .background(Ink.TabSelected),
            )
            Row(modifier = Modifier.fillMaxSize()) {
                items.forEachIndexed { index, item ->
                    val active = index == selected
                    val tint by animateColorAsState(
                        targetValue = if (active) Ink.Blue else Ink.IconTint,
                        animationSpec = tween(180),
                        label = "tabTint",
                    )
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .clickable(
                                interactionSource = remember { MutableInteractionSource() },
                                indication = null,
                            ) { onSelect(index) },
                        contentAlignment = Alignment.Center,
                    ) {
                        if (active) {
                            Row(
                                modifier = Modifier.padding(4.dp),
                                horizontalArrangement = Arrangement.spacedBy(7.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                MochiIonicon(item.second, size = 20.dp, style = MochiIconStyle.Filled, tint = tint)
                                T(item.first, size = 13, weight = FontWeight.SemiBold, color = tint)
                            }
                        } else {
                            MochiIonicon(item.second, size = 22.dp, style = MochiIconStyle.Filled, tint = tint)
                        }
                    }
                }
            }
        }
    }
}

/** 分组标题：列表改为零间距后，由标题自己承担上下留白。 */
@Composable
fun GroupTitle(text: String, topPadding: Dp = 18.dp) {
    T(
        text,
        size = 15,
        weight = FontWeight.SemiBold,
        color = Ink.Sub,
        modifier = Modifier.padding(start = 4.dp, top = topPadding, bottom = 14.dp),
    )
}

@Composable
fun CardBox(
    modifier: Modifier = Modifier,
    padding: PaddingValues = PaddingValues(18.dp),
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(26.dp))
            .background(Ink.Card)
            .padding(padding),
        content = content,
    )
}

@Composable
fun RowDivider(inset: Dp = 16.dp) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = inset)
            .height(1.dp)
            .background(Ink.Divider),
    )
}

/** 胶囊按钮，直接使用 Mochi 的按钮组件：filled 为实心，否则为 tonal。 */
@Composable
fun PillButton(
    text: String,
    modifier: Modifier = Modifier,
    filled: Boolean = true,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    MochiButton(
        onClick = onClick,
        modifier = modifier,
        enabled = enabled,
        style = if (filled) MochiButtonStyle.Filled else MochiButtonStyle.Tonal,
    ) {
        T(
            text,
            size = 17,
            weight = FontWeight.SemiBold,
            color = when {
                filled && enabled -> Color.White
                filled -> Ink.Sub
                else -> Ink.Text
            },
        )
    }
}

@Composable
fun IconSquare(icon: String, tint: Color, size: Dp = 36.dp) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(RoundedCornerShape(size * 0.3f))
            .background(tint),
        contentAlignment = Alignment.Center,
    ) {
        MochiIonicon(icon, size = size * 0.55f, style = MochiIconStyle.Filled, tint = Color.White)
    }
}

/** 带彩色图标和右侧箭头的卡片行。 */
@Composable
fun ActionRow(
    icon: String,
    tint: Color,
    title: String,
    value: String = "",
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(58.dp)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconSquare(icon, tint)
        Spacer(Modifier.width(12.dp))
        T(title, size = 16, weight = FontWeight.Medium)
        Spacer(Modifier.weight(1f))
        if (value.isNotEmpty()) {
            T(value, size = 15, color = Ink.Sub)
            Spacer(Modifier.width(6.dp))
        }
        MochiIonicon("chevron-forward", size = 18.dp, tint = Ink.Chevron)
    }
}

/** 没有图标、只有标题和右侧值的卡片行。 */
@Composable
fun InfoRow(
    title: String,
    value: String,
    onClick: (() -> Unit)? = null,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        T(title, size = 16, weight = FontWeight.Medium)
        Spacer(Modifier.weight(1f))
        T(value, size = 16, color = Ink.Sub)
        if (onClick != null) {
            Spacer(Modifier.width(6.dp))
            MochiIonicon("chevron-forward", size = 16.dp, tint = Ink.Chevron)
        }
    }
}

@Composable
fun SegmentedControl(items: List<String>, selected: Int, onSelect: (Int) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(36.dp)
            .clip(RoundedCornerShape(18.dp))
            .background(Ink.Fill)
            .padding(3.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        items.forEachIndexed { index, label ->
            val active = index == selected
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .shadow(if (active) 3.dp else 0.dp, RoundedCornerShape(18.dp))
                    .clip(RoundedCornerShape(18.dp))
                    .background(if (active) Ink.Card else Color.Transparent)
                    .clickable { onSelect(index) },
                contentAlignment = Alignment.Center,
            ) {
                T(
                    label,
                    size = 15,
                    weight = if (active) FontWeight.SemiBold else FontWeight.Medium,
                    color = if (active) Ink.Text else Ink.Sub,
                )
            }
        }
    }
}

/** 空态卡片，交给 Mochi 的 MochiEmptyState 渲染。 */
@Composable
fun EmptyCard(icon: String, tint: Color, title: String, desc: String) {
    MochiEmptyState(
        title = title,
        message = desc,
        icon = {
            MochiIonicon(icon, size = 44.dp, style = MochiIconStyle.Filled, tint = tint)
        },
    )
}

/** 待办勾选框，使用 Mochi 的 MochiCheckbox（自带弹性勾选动画）。 */
@Composable
fun CheckCircle(checked: Boolean, onClick: () -> Unit) {
    MochiCheckbox(
        checked = checked,
        onCheckedChange = { onClick() },
    )
}

/** 蓝色圆形悬浮按钮，按下时回弹缩小。 */
@Composable
fun FabButton(icon: String = "add", onClick: () -> Unit) {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (pressed) 0.88f else 1f,
        animationSpec = spring(dampingRatio = 0.45f, stiffness = 700f),
        label = "fabPress",
    )
    Box(
        modifier = Modifier
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .size(58.dp)
            .shadow(elevation = if (pressed) 6.dp else 12.dp, shape = CircleShape)
            .clip(CircleShape)
            .background(Ink.Blue)
            .clickable(interactionSource = interaction, indication = null, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        MochiIonicon(icon, size = 28.dp, tint = Color.White)
    }
}

/** 居中的确认弹窗，用于删除、清空等危险操作。 */
@Composable
fun ConfirmDialog(
    title: String,
    desc: String,
    confirmText: String,
    danger: Boolean = false,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    DialogFrame(onDismiss = onDismiss) {
        T(title, size = 18, weight = FontWeight.SemiBold, textAlign = TextAlign.Center)
        Spacer(Modifier.height(8.dp))
        T(desc, size = 14, color = Ink.Sub, textAlign = TextAlign.Center)
        Spacer(Modifier.height(20.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(46.dp)
                    .clip(RoundedCornerShape(23.dp))
                    .background(Ink.Fill)
                    .clickable(onClick = onDismiss),
                contentAlignment = Alignment.Center,
            ) {
                T("取消", size = 16, weight = FontWeight.Medium)
            }
            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(46.dp)
                    .clip(RoundedCornerShape(23.dp))
                    .background(if (danger) Ink.Red else Ink.Blue)
                    .clickable(onClick = onConfirm),
                contentAlignment = Alignment.Center,
            ) {
                T(confirmText, size = 16, weight = FontWeight.SemiBold, color = Color.White)
            }
        }
    }
}

/** 首次启动的介绍弹窗：展示作者与免责声明，倒计时 5 秒结束前无法关闭。 */
@Composable
fun WelcomeDialog(onStart: () -> Unit) {
    var secondsLeft by remember { mutableIntStateOf(5) }
    LaunchedEffect(Unit) {
        while (secondsLeft > 0) {
            kotlinx.coroutines.delay(1000)
            secondsLeft -= 1
        }
    }
    DialogFrame(onDismiss = null) {
        Box(
            modifier = Modifier
                .size(64.dp)
                .clip(CircleShape)
                .background(Ink.Blue.copy(alpha = 0.14f)),
            contentAlignment = Alignment.Center,
        ) {
            MochiIonicon("checkmark-done-circle", size = 38.dp, style = MochiIconStyle.Filled, tint = Ink.Blue)
        }
        Spacer(Modifier.height(14.dp))
        T("欢迎使用 今日事", size = 20, weight = FontWeight.Black, textAlign = TextAlign.Center)
        Spacer(Modifier.height(4.dp))
        T("作者：酷安 @然后啊然后", size = 13, color = Ink.Sub, textAlign = TextAlign.Center)
        Spacer(Modifier.height(16.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(Ink.Bg)
                .padding(horizontal = 14.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            T("免责声明", size = 14, weight = FontWeight.SemiBold)
            T(
                "本应用完全离线运行，不联网、不收集、不上传任何个人信息，所有数据仅保存在您的设备上。" +
                    "本应用仅供个人学习与日常交流使用，请勿用于商业用途。" +
                    "使用本应用即表示您已阅读并同意以上内容，完整免责声明可在「我的 → 关于」中查看。",
                size = 13,
                color = Ink.Sub,
            )
        }
        Spacer(Modifier.height(18.dp))
        val ready = secondsLeft == 0
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(48.dp)
                .clip(RoundedCornerShape(24.dp))
                .background(if (ready) Ink.Blue else Ink.Fill)
                .clickable(enabled = ready, onClick = onStart),
            contentAlignment = Alignment.Center,
        ) {
            T(
                if (ready) "开始使用" else "我已阅读 (${secondsLeft}s)",
                size = 16,
                weight = FontWeight.SemiBold,
                color = if (ready) Color.White else Ink.Sub,
            )
        }
    }
}

/** 免责声明 / 开源致谢等长文本弹窗，内容可滚动。 */
@Composable
fun TextDialog(title: String, body: String, onDismiss: () -> Unit) {
    DialogFrame(onDismiss = onDismiss) {
        T(title, size = 18, weight = FontWeight.SemiBold, textAlign = TextAlign.Center)
        Spacer(Modifier.height(12.dp))
        T(
            body,
            size = 13,
            color = Ink.Sub,
            modifier = Modifier
                .heightIn(max = 360.dp)
                .verticalScroll(rememberScrollState()),
        )
        Spacer(Modifier.height(18.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(46.dp)
                .clip(RoundedCornerShape(23.dp))
                .background(Ink.Blue)
                .clickable(onClick = onDismiss),
            contentAlignment = Alignment.Center,
        ) {
            T("我知道了", size = 16, weight = FontWeight.SemiBold, color = Color.White)
        }
    }
}

/** 弹窗统一外框：半透明遮罩 + 白色圆角卡片，onDismiss 为 null 时点遮罩不关闭。 */
@Composable
private fun DialogFrame(onDismiss: (() -> Unit)?, content: @Composable ColumnScope.() -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.45f))
            .clickable(enabled = onDismiss != null, onClick = { onDismiss?.invoke() }),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            modifier = Modifier
                .padding(horizontal = 30.dp)
                .clip(RoundedCornerShape(28.dp))
                .background(Ink.Card)
                .clickable(enabled = false) {}
                .padding(horizontal = 20.dp, vertical = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            content = content,
        )
    }
}

