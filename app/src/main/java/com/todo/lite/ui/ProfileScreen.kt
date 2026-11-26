package com.todo.lite.ui

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.animateIntAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import com.todo.lite.data.RemindLeadOptions
import com.todo.lite.data.TodoState
import com.todo.lite.data.remindLabel
import ui.feice.mochi.basic.MochiBarIconButton
import ui.feice.mochi.icons.MochiIonicon
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** 可选的浅色主题色。 */
private data class AccentChoice(val name: String, val color: Color)

private val AccentChoices = listOf(
    AccentChoice("天蓝", Color(0xFF0A84FF)),
    AccentChoice("湖蓝", Color(0xFF0EA5B7)),
    AccentChoice("薄荷", Color(0xFF10B981)),
    AccentChoice("藕紫", Color(0xFF8B7BF7)),
    AccentChoice("蜜橘", Color(0xFFF2994A)),
    AccentChoice("樱粉", Color(0xFFF0619E)),
    AccentChoice("石墨", Color(0xFF5B6472)),
)

@Composable
fun ProfileScreen(
    state: TodoState,
    onSelectTab: (Int) -> Unit,
    onMessage: (String) -> Unit,
    accent: Color,
    remindLead: Long,
    onOpenAppearance: () -> Unit,
    onOpenRemind: () -> Unit,
) {
    val context = LocalContext.current
    val total = state.items.size
    val done = state.done.size
    val pending = total - done
    val rate = if (total == 0) 0 else done * 100 / total
    val progress by animateFloatAsState(
        targetValue = if (total == 0) 0f else done / total.toFloat(),
        animationSpec = spring(dampingRatio = 0.8f, stiffness = 260f),
        label = "progress",
    )
    var confirm by remember { mutableIntStateOf(0) }
    var showText by remember { mutableIntStateOf(0) }

    val exportLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument("application/json"),
    ) { uri ->
        if (uri != null) {
            runCatching {
                context.contentResolver.openOutputStream(uri)?.use { out ->
                    out.write(state.exportJson().toByteArray(Charsets.UTF_8))
                } ?: error("无法写入所选文件")
            }.onSuccess {
                onMessage("已导出 $total 条待办")
            }.onFailure {
                onMessage("导出失败：${it.message ?: "未知错误"}")
            }
        }
    }

    val importLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument(),
    ) { uri ->
        if (uri != null) {
            runCatching {
                val text = context.contentResolver.openInputStream(uri)
                    ?.bufferedReader()
                    ?.use { it.readText() }
                    .orEmpty()
                require(text.isNotBlank()) { "文件为空" }
                state.importJson(text)
            }.onSuccess { added ->
                onMessage(if (added > 0) "已导入 $added 条待办" else "没有新的待办可导入")
            }.onFailure {
                onMessage("导入失败：文件格式不正确")
            }
        }
    }

    AppScaffold(
        title = "我的",
        subtitle = "本地存储 · 可导出备份到任意位置",
        selectedTab = 2,
        onSelectTab = onSelectTab,
        showVersion = true,
    ) {
        item { GroupTitle("完成情况") }
        item {
            CardBox(padding = PaddingValues(horizontal = 16.dp, vertical = 20.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Stat("待完成", pending, Ink.Blue, Modifier.weight(1f))
                    VerticalDivider()
                    Stat("已完成", done, Ink.Green, Modifier.weight(1f))
                    VerticalDivider()
                    Stat("完成率", rate, Ink.Purple, Modifier.weight(1f), suffix = "%")
                }
                Spacer(Modifier.height(18.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(CircleShape)
                        .background(Ink.Fill),
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(progress)
                            .fillMaxHeight()
                            .clip(CircleShape)
                            .background(Ink.Blue),
                    )
                }
                Spacer(Modifier.height(10.dp))
                T(
                    if (total == 0) "还没有记录，先去「待办」写一条吧" else "已经完成 $done / $total 项",
                    size = 13,
                    color = Ink.Sub,
                )
            }
        }

        item { GroupTitle("提醒") }
        item {
            CardBox(padding = PaddingValues(0.dp)) {
                ActionRow(
                    icon = "notifications",
                    tint = Ink.Orange,
                    title = "截止前提醒",
                    value = remindLabel(remindLead),
                    onClick = onOpenRemind,
                )
            }
        }

        item { GroupTitle("外观") }
        item {
            CardBox(padding = PaddingValues(0.dp)) {
                ActionRow(
                    icon = "color-palette",
                    tint = Ink.Blue,
                    title = "主题色",
                    value = accentNameOf(accent),
                    onClick = onOpenAppearance,
                )
            }
        }

        item { GroupTitle("数据管理") }
        item {
            CardBox(padding = PaddingValues(0.dp)) {
                ActionRow(
                    icon = "arrow-up-circle",
                    tint = Ink.Blue,
                    title = "导出数据",
                    value = "$total 项",
                    onClick = {
                        if (total == 0) {
                            onMessage("还没有可导出的待办")
                        } else {
                            exportLauncher.launch("todo-backup-${dateStamp()}.json")
                        }
                    },
                )
                RowDivider(inset = 64.dp)
                ActionRow(
                    icon = "arrow-down-circle",
                    tint = Ink.Purple,
                    title = "导入数据",
                    value = "合并",
                    onClick = {
                        importLauncher.launch(
                            arrayOf("application/json", "text/plain", "application/octet-stream")
                        )
                    },
                )
                RowDivider(inset = 64.dp)
                ActionRow(
                    icon = "trash",
                    tint = Ink.Green,
                    title = "清空已完成",
                    value = "$done 项",
                    onClick = {
                        if (done == 0) onMessage("还没有已完成的任务") else confirm = 1
                    },
                )
                RowDivider(inset = 64.dp)
                ActionRow(
                    icon = "trash-bin",
                    tint = Ink.Red,
                    title = "清空全部待办",
                    value = "$total 项",
                    onClick = {
                        if (total == 0) onMessage("列表已经是空的") else confirm = 2
                    },
                )
            }
        }
        item {
            T(
                "导出时可选择任意文件夹；导入会按记录合并，不会覆盖本地数据。",
                size = 13,
                color = Ink.Hint,
                modifier = Modifier
                    .padding(horizontal = 4.dp)
                    .padding(top = 14.dp),
            )
        }

        item { GroupTitle("关于") }
        item {
            CardBox(padding = PaddingValues(0.dp)) {
                InfoRow("应用名称", "今日事")
                RowDivider()
                InfoRow("当前版本", AppVersion)
                RowDivider()
                InfoRow("作者", "酷安 @然后啊然后")
                RowDivider()
                InfoRow("免责声明", "查看", onClick = { showText = 1 })
                RowDivider()
                InfoRow("开源致谢", "查看", onClick = { showText = 2 })
            }
        }

        item {
            T(
                "今日事 · 无需登录，打开即用",
                size = 13,
                color = Ink.Hint,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
                    .padding(top = 14.dp),
            )
        }
    }

    when (confirm) {
        1 -> ConfirmDialog(
            title = "清空已完成",
            desc = "将删除 $done 条已完成的记录，无法恢复。",
            confirmText = "清空",
            danger = true,
            onConfirm = {
                state.clearDone()
                confirm = 0
                onMessage("已清空 $done 条完成记录")
            },
            onDismiss = { confirm = 0 },
        )
        2 -> ConfirmDialog(
            title = "清空全部待办",
            desc = "将删除全部 $total 条记录，包括未完成的任务，无法恢复。",
            confirmText = "全部删除",
            danger = true,
            onConfirm = {
                state.clearAll()
                confirm = 0
                onMessage("已清空全部待办")
            },
            onDismiss = { confirm = 0 },
        )
    }

    when (showText) {
        1 -> TextDialog(
            title = "免责声明",
            body = "1. 「今日事」是一款完全离线的本地待办工具，不会联网，不收集、不上传任何个人信息，" +
                "所有数据仅保存在您的设备上。\n\n" +
                "2. 导出功能生成的备份文件保存在您自行选择的位置，请注意妥善保管，避免隐私泄露。\n\n" +
                "3. 本应用仅供个人学习与日常使用，请勿用于商业用途。\n\n" +
                "4. 开发者不对因使用本应用造成的任何数据丢失或损失承担责任，重要数据请定期导出备份。\n\n" +
                "5. 继续使用本应用即表示您已阅读并同意以上内容。\n\n" +
                "—— 酷安 @然后啊然后",
            onDismiss = { showText = 0 },
        )
        2 -> TextDialog(
            title = "开源致谢",
            body = "「今日事」基于以下优秀的开源项目构建，向开源社区的每一位贡献者致谢：\n\n" +
                "· mochi-compose（MIT License）\n" +
                "  提供全套 UI 组件与动效（github.com/feice11/mochi-compose）\n\n" +
                "· Jetpack Compose / AndroidX（Apache License 2.0）\n" +
                "  Google 现代化 Android UI 框架\n\n" +
                "· Kotlin（Apache License 2.0）\n" +
                "  JetBrains 出品的编程语言\n\n" +
                "作者：酷安 @然后啊然后",
            onDismiss = { showText = 0 },
        )
    }
}

/** 二级选色页：iOS 设置风格的行式列表，点行即切换主题色。 */
@Composable
fun AppearanceScreen(
    accent: Color,
    onAccentChange: (Color) -> Unit,
    onBack: () -> Unit,
    onSelectTab: (Int) -> Unit,
) {
    AppScaffold(
        title = "外观",
        subtitle = "主题色 · 浅色系",
        selectedTab = 2,
        onSelectTab = onSelectTab,
        navIcon = {
            MochiBarIconButton(onClick = onBack) {
                Box(modifier = Modifier.rotate(180f)) {
                    MochiIonicon("chevron-forward", size = 20.dp)
                }
            }
        },
    ) {
        item { GroupTitle("主题色") }
        item {
            CardBox(padding = PaddingValues(0.dp)) {
                AccentChoices.forEachIndexed { index, choice ->
                    val selected = accent.toArgb() == choice.color.toArgb()
                    val checkScale by animateFloatAsState(
                        targetValue = if (selected) 1f else 0f,
                        animationSpec = spring(dampingRatio = 0.6f, stiffness = 550f),
                        label = "accentCheck",
                    )
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(58.dp)
                            .clickable { onAccentChange(choice.color) }
                            .padding(horizontal = 16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Box(
                            modifier = Modifier
                                .size(28.dp)
                                .clip(CircleShape)
                                .background(choice.color),
                        )
                        Spacer(Modifier.width(12.dp))
                        T(choice.name, size = 16, weight = FontWeight.Medium)
                        Spacer(Modifier.weight(1f))
                        Box(
                            modifier = Modifier
                                .size(22.dp)
                                .graphicsLayer {
                                    alpha = checkScale
                                    scaleX = checkScale
                                    scaleY = checkScale
                                },
                            contentAlignment = Alignment.Center,
                        ) {
                            MochiIonicon("checkmark", size = 20.dp, tint = Ink.Blue)
                        }
                    }
                    if (index != AccentChoices.lastIndex) RowDivider(inset = 64.dp)
                }
            }
        }
        item {
            T(
                "选择后立即生效并自动记住，按钮、标签和勾选框会一起变化。",
                size = 13,
                color = Ink.Hint,
                modifier = Modifier
                    .padding(horizontal = 4.dp)
                    .padding(top = 14.dp),
            )
        }
    }
}

/** 当前主题色对应的名称。 */
internal fun accentNameOf(accent: Color): String =
    AccentChoices.firstOrNull { it.color.toArgb() == accent.toArgb() }?.name ?: "自定义"

/** 二级提醒设置页：选择截止前多久弹窗提醒。 */
@Composable
fun RemindScreen(
    lead: Long,
    onLeadChange: (Long) -> Unit,
    onBack: () -> Unit,
    onSelectTab: (Int) -> Unit,
    onMessage: (String) -> Unit,
) {
    val context = LocalContext.current
    var pendingLead by remember { mutableStateOf<Long?>(null) }
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
    ) { granted ->
        val picked = pendingLead
        pendingLead = null
        if (picked != null) {
            onLeadChange(picked)
            if (!granted) onMessage("未授予通知权限，提醒不会弹窗")
        }
    }

    AppScaffold(
        title = "提醒",
        subtitle = "截止前弹窗提醒",
        selectedTab = 2,
        onSelectTab = onSelectTab,
        navIcon = {
            MochiBarIconButton(onClick = onBack) {
                Box(modifier = Modifier.rotate(180f)) {
                    MochiIonicon("chevron-forward", size = 20.dp)
                }
            }
        },
    ) {
        item { GroupTitle("提醒时间") }
        item {
            CardBox(padding = PaddingValues(0.dp)) {
                RemindLeadOptions.forEachIndexed { index, minutes ->
                    val selected = lead == minutes
                    val checkScale by animateFloatAsState(
                        targetValue = if (selected) 1f else 0f,
                        animationSpec = spring(dampingRatio = 0.6f, stiffness = 550f),
                        label = "remindCheck",
                    )
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(58.dp)
                            .clickable {
                                when {
                                    minutes == 0L -> onLeadChange(0L)
                                    Build.VERSION.SDK_INT >= 33 &&
                                        ContextCompat.checkSelfPermission(
                                            context, Manifest.permission.POST_NOTIFICATIONS,
                                        ) != PackageManager.PERMISSION_GRANTED -> {
                                        // 先请求通知权限，授权结果里再保存
                                        pendingLead = minutes
                                        permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                                    }
                                    else -> onLeadChange(minutes)
                                }
                            }
                            .padding(horizontal = 16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        T(remindLabel(minutes), size = 16, weight = FontWeight.Medium)
                        Spacer(Modifier.weight(1f))
                        Box(
                            modifier = Modifier
                                .size(22.dp)
                                .graphicsLayer {
                                    alpha = checkScale
                                    scaleX = checkScale
                                    scaleY = checkScale
                                },
                            contentAlignment = Alignment.Center,
                        ) {
                            MochiIonicon("checkmark", size = 20.dp, tint = Ink.Blue)
                        }
                    }
                    if (index != RemindLeadOptions.lastIndex) RowDivider()
                }
            }
        }
        item {
            T(
                "提醒按截止当天结束时间倒推：截止「11月27日」且提前 1 小时，会在 27 日 23:00 收到弹窗提醒。" +
                    "已逾期或已完成的待办不再提醒。",
                size = 13,
                color = Ink.Hint,
                modifier = Modifier
                    .padding(horizontal = 4.dp)
                    .padding(top = 14.dp),
            )
        }
    }
}

@Composable
private fun Stat(
    label: String,
    value: Int,
    color: Color,
    modifier: Modifier = Modifier,
    suffix: String = "",
) {
    val animated by animateIntAsState(
        targetValue = value,
        animationSpec = spring(dampingRatio = 0.85f, stiffness = 300f),
        label = "stat$label",
    )
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        T("$animated$suffix", size = 26, weight = FontWeight.Black, color = color)
        Spacer(Modifier.height(2.dp))
        T(label, size = 13, color = Ink.Sub)
    }
}

@Composable
private fun VerticalDivider() {
    Box(
        modifier = Modifier
            .width(1.dp)
            .height(34.dp)
            .background(Ink.Divider),
    )
}

private fun dateStamp(): String =
    SimpleDateFormat("yyyyMMdd-HHmm", Locale.getDefault()).format(Date())
