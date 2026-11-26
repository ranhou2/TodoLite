package com.todo.lite

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.todo.lite.data.ReminderScheduler
import com.todo.lite.data.SettingsStore
import com.todo.lite.data.Todo
import com.todo.lite.data.TodoState
import com.todo.lite.data.TodoStore
import com.todo.lite.ui.AppearanceScreen
import com.todo.lite.ui.DoneScreen
import com.todo.lite.ui.RemindScreen
import com.todo.lite.ui.WelcomeDialog
import com.todo.lite.ui.EditorRequest
import com.todo.lite.ui.Ink
import com.todo.lite.ui.ProfileScreen
import com.todo.lite.ui.TodoEditorContent
import com.todo.lite.ui.TodoScreen
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import ui.feice.mochi.basic.MochiSheet
import ui.feice.mochi.basic.MochiSheetDetent
import ui.feice.mochi.basic.MochiToastHost
import ui.feice.mochi.basic.mochiSheetBackdrop
import ui.feice.mochi.basic.rememberMochiSheetState
import ui.feice.mochi.basic.rememberMochiToastState
import ui.feice.mochi.effect.overscroll.ProvideMochiOverscroll
import ui.feice.mochi.theme.MochiTheme
import ui.feice.mochi.theme.PaletteStyle
import ui.feice.mochi.theme.lightColorScheme
import ui.feice.mochi.utils.mochiEnableEdgeToEdge

private const val TabTodo = 0
private const val TabDone = 1
private const val TabProfile = 2

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        mochiEnableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent { TodoLiteApp() }
    }
}

@Composable
private fun TodoLiteApp() {
    val appContext = LocalContext.current.applicationContext
    val settings = remember { SettingsStore(appContext) }
    var accent by remember { mutableStateOf(settings.loadAccent()) }
    SideEffect { Ink.Accent = accent }
    // 调色板只在主题色变化时计算一次，避免每次重组都重建 Material 3 配色
    val colorScheme = remember(accent) { lightColorScheme(accent, PaletteStyle.Fidelity) }

    MochiTheme(colors = colorScheme) {
        val toast = rememberMochiToastState()
        val state = remember { TodoState(TodoStore(appContext), appContext) }
        val sheet = rememberMochiSheetState(detents = listOf(MochiSheetDetent.Large))
        var tab by remember { mutableIntStateOf(TabTodo) }
        var sheetRequest by remember { mutableStateOf<EditorRequest>(EditorRequest.New) }
        var editorKey by remember { mutableIntStateOf(0) }
        var showAppearance by remember { mutableStateOf(false) }
        var showRemind by remember { mutableStateOf(false) }
        var remindLead by remember { mutableStateOf(settings.loadRemindLead()) }
        val scope = rememberCoroutineScope()
        var showWelcome by remember { mutableStateOf(!settings.hasSeenWelcome()) }
        val message: (String) -> Unit = remember { { toast.show(it) } }
        val selectTab: (Int) -> Unit = remember { { tab = it } }

        val toggle: (Todo) -> Unit = { todo ->
            state.toggle(todo.id)
            message(if (todo.done) "已放回待办" else "完成了一件，真不错")
        }

        val delete: (Todo) -> Unit = { todo ->
            state.remove(todo.id)
            // 提示条保留 3 秒，点一下即可放回
            toast.show("已删除", "点此撤销", null, 3000L) {
                state.restore(todo)
            }
        }

        val openEditor: (EditorRequest) -> Unit = { request ->
            sheetRequest = request
            editorKey++
            sheet.show()
        }

        // 二级页（外观 / 提醒）打开时，返回手势或返回键先回到「我的」，而不是退出应用
        BackHandler(enabled = showAppearance || showRemind) {
            showAppearance = false
            showRemind = false
        }

        // 启动时按最新设置与数据重排一遍截止提醒
        LaunchedEffect(Unit) {
            withContext(Dispatchers.IO) {
                ReminderScheduler.rescheduleAll(appContext)
            }
        }

        ProvideMochiOverscroll {
            Box(modifier = Modifier.fillMaxSize()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .mochiSheetBackdrop(sheet),
                ) {
                    // 页面瞬时切换（跟手）：切页动画交给底栏指示器的弹簧滑动表达
                    when (tab) {
                        TabDone -> DoneScreen(
                            state = state,
                            onSelectTab = selectTab,
                            onToggle = toggle,
                            onOpen = { openEditor(EditorRequest.Edit(it)) },
                            onDelete = delete,
                        )
                        TabProfile -> ProfileScreen(
                            state = state,
                            onSelectTab = selectTab,
                            onMessage = message,
                            accent = accent,
                            remindLead = remindLead,
                            onOpenAppearance = { showAppearance = true },
                            onOpenRemind = { showRemind = true },
                        )
                        else -> TodoScreen(
                            state = state,
                            onSelectTab = selectTab,
                            onAdd = { openEditor(EditorRequest.New) },
                            onOpen = { openEditor(EditorRequest.Edit(it)) },
                            onToggle = toggle,
                            onDelete = delete,
                        )
                    }
                }

                // 二级选色页：模拟 iOS push，从右侧滑入，返回时滑出
                AnimatedVisibility(
                    visible = showAppearance,
                    enter = slideInHorizontally(
                        animationSpec = tween(320, easing = FastOutSlowInEasing),
                    ) { it } + fadeIn(tween(180)),
                    exit = slideOutHorizontally(
                        animationSpec = tween(300, easing = FastOutSlowInEasing),
                    ) { it } + fadeOut(tween(150)),
                ) {
                    Box(modifier = Modifier.fillMaxSize().background(Ink.Bg)) {
                        AppearanceScreen(
                            accent = accent,
                            onAccentChange = {
                                accent = it
                                settings.saveAccent(it)
                            },
                            onBack = { showAppearance = false },
                            onSelectTab = {
                                tab = it
                                showAppearance = false
                            },
                        )
                    }
                }

                // 二级提醒设置页：与选色页同样的 push 动画
                AnimatedVisibility(
                    visible = showRemind,
                    enter = slideInHorizontally(
                        animationSpec = tween(320, easing = FastOutSlowInEasing),
                    ) { it } + fadeIn(tween(180)),
                    exit = slideOutHorizontally(
                        animationSpec = tween(300, easing = FastOutSlowInEasing),
                    ) { it } + fadeOut(tween(150)),
                ) {
                    Box(modifier = Modifier.fillMaxSize().background(Ink.Bg)) {
                        RemindScreen(
                            lead = remindLead,
                            onLeadChange = { lead ->
                                remindLead = lead
                                settings.saveRemindLead(lead)
                                scope.launch(Dispatchers.IO) {
                                    ReminderScheduler.rescheduleAll(appContext)
                                }
                            },
                            onBack = { showRemind = false },
                            onSelectTab = {
                                tab = it
                                showRemind = false
                            },
                            onMessage = message,
                        )
                    }
                }

                MochiSheet(sheet, onDismiss = { }, color = Ink.Bg) {
                    key(editorKey) {
                        TodoEditorContent(
                            request = sheetRequest,
                            onClose = { sheet.hide() },
                            onSubmit = { title, note, due ->
                                val editing = sheetRequest as? EditorRequest.Edit
                                if (editing == null) {
                                    state.add(title, note, due)
                                    message("已添加：$title")
                                } else {
                                    state.update(editing.todo.id, title, note, due)
                                    message("已保存修改")
                                }
                                sheet.hide()
                            },
                            onDelete = {
                                (sheetRequest as? EditorRequest.Edit)?.let { editing ->
                                    delete(editing.todo)
                                }
                                sheet.hide()
                            },
                        )
                    }
                }

                MochiToastHost(toast)

                if (showWelcome) {
                    WelcomeDialog(
                        onStart = {
                            settings.markWelcomeSeen()
                            showWelcome = false
                        },
                    )
                }
            }
        }
    }
}
