# 今日事 · iOS 移植版

TodoLite（今日事）的 iOS 原生移植版本。原版是 Android 上的 Kotlin + Jetpack Compose 应用，本工程用 **Objective-C + UIKit 逐屏重写**，不使用 WebView、不依赖任何第三方库，在 Linux 上交叉编译产出 arm64 IPA。

> **非官方移植声明**
>
> 本项目由社区爱好者独立制作，与 Android 原版作者**没有隶属或授权关系**，未获得原作者正式授权，仅供学习交流，**禁止商业使用**。
>
> - 原版作者：GitHub [@ranhou2](https://github.com/ranhou2) ／ 酷安 @然后啊然后
> - iOS 移植与适配：Jacky（GitHub [Jacky2277](https://github.com/Jacky2277)）
>
> 原项目仓库未附带开源许可证，因此本移植版不适用任何开源许可证，相关权利归各自作者所有。原作者如对本项目有异议，将立即停止分发并删除相关内容。

## 这是什么

- 原版：Android，Kotlin + Jetpack Compose，完全离线，无登录无广告。
- 本版：iOS 14.0+，Objective-C + UIKit，arm64 真机，可执行文件约 340 KB，无 Swift 运行时依赖。
- 不是套壳：没有 WebView、没有复用原版二进制，列表、编辑器、提醒、主题、导入导出全部按原版行为重写。
- 备份格式与原版完全一致，**可与 Android 版互导数据**。

## 功能

- 待办 / 完成 / 我的三个标签页，底部白色胶囊标签栏，右下角悬浮新建按钮
- 新建与编辑：标题（最多 60 字）、备注（最多 300 字）、截止日期（无截止 / 今天 / 明天 / 本周末 / 自定义日历）
- 列表排序：未完成按截止日升序、无截止排后；已完成按完成时间倒序
- 逾期标红、今天与明天标橙，右侧显示「截止 M月d日 · 备注」
- 圆形勾选框完成 / 放回，完成项标题自动加删除线
- 左滑删除 + 撤销提示
- 截止提醒六档：不提醒 / 提前 30 分钟 / 1 小时 / 6 小时 / 1 天 / 2 天，按「截止日 24:00 − 提前量」计算，使用本地通知
- 七种浅色主题：天蓝、湖蓝、薄荷、藕紫、蜜橘、樱粉、石墨，切换后全局生效
- 我的页：完成情况三栏统计与进度条、提醒档位、外观主题、数据管理、关于
- 数据管理：导出 JSON 备份、导入合并（按 id 去重，不覆盖本地）、清空已完成、清空全部
- 全部数据存放在本机 NSUserDefaults，应用不联网、无统计、无账号

## 数据格式

导出的备份是一个 JSON 数组，字段与 Android 版一致：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 待办唯一标识 |
| `title` | string | 标题 |
| `note` | string | 备注，可为空 |
| `due` | number \| null | 截止时间，毫秒时间戳 |
| `done` | bool | 是否完成 |
| `createdAt` | number | 创建时间，毫秒时间戳 |
| `doneAt` | number \| null | 完成时间，毫秒时间戳 |

导入时按 `id` 去重合并，只新增本地没有的记录，不会覆盖已有数据。

## 构建（无需 Mac）

工程在 Linux 上用 clang 交叉编译到 `arm64-apple-ios14.0`，再由 `ld64.lld` 链接、`ldid` 临时签名、`zip` 打包成 IPA。

### 依赖

```bash
sudo apt-get install -y clang lld llvm zip git libplist-dev libssl-dev python3-pip
pip3 install pillow
```

iPhoneOS SDK（二选一，脚本会自动在 `./sdks`、`~/sdks`、`/opt/theos/sdks` 下查找）：

```bash
git clone --depth 1 --filter=blob:none --sparse https://github.com/theos/sdks
cd sdks && git sparse-checkout set iPhoneOS16.5.sdk
```

`ldid`（用于临时签名，可选）：

```bash
git clone https://github.com/ProcursusTeam/ldid
cd ldid && make          # 需要 libplist-dev 与 libssl-dev
```

### 编译

```bash
SDK=/path/to/iPhoneOS16.5.sdk LDID=/path/to/ldid ./build.sh
```

产物：`build/今日事-iOS-v2.0.0-unsigned.ipa`（可用 `VERSION=2.0.1 ./build.sh` 指定版本号）。

## 安装

- 要求 iOS 14.0 及以上，仅 arm64 真机。
- IPA 是 ad-hoc 临时签名，**不能直接双击安装**，需要用轻松签 / ESign / Sideloadly / TrollStore 等工具用自己的证书重签。
- Bundle ID 为 `com.jacky.todolite`，自签时可改成自己的；首次启动会请求通知权限，拒绝后提醒不会弹出。

## 目录结构

```
src/          Objective-C 源码
  TLTheme            主题与配色
  TLTodoStore        数据存储与 JSON 导入导出
  TLReminders        本地通知调度
  TLMainViewController   标签栏容器
  TLListViewController   待办 / 完成列表
  TLEditorViewController 新建与编辑
  TLProfileViewController 我的页
  TLUIKitAdditions   通用控件
tools/        图标生成脚本（Pillow 绘制，无需原版素材）
Info.plist    App 配置
build.sh      交叉编译与打包脚本
```

## 已知限制

- 只做 iPhone 竖屏、强制浅色模式，与原版浅色设计保持一致
- 未上架 App Store（无开发者账号，且属于非官方衍生作品）
- 仅提供真机 arm64 版本，没有模拟器 slice
- 界面文案为中文硬编码，暂未做多语言

## 更新日志

见 [CHANGELOG.md](CHANGELOG.md)。

## 致谢

- 原版设计与功能：ranhou2（酷安 @然后啊然后）
- iOS 移植、适配与图标重绘：Jacky（GitHub Jacky2277）
- iOS SDK 来源：[theos/sdks](https://github.com/theos/sdks)；签名工具：[ldid](https://github.com/ProcursusTeam/ldid)
