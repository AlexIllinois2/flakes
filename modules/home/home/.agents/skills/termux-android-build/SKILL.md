---
name: termux-android-build
description: 在 Android 手机 Termux 上构建 Android 工程的完整流程（SSH 接入、JDK/SDK、ARM64 aapt2、内存调优）。当用户要求"用手机 Termux 构建/编译 APK"时使用。
agent_created: true
---

# 在手机 Termux 上构建 Android 工程

## 前提
- 手机通过 adb 连接，设备序列号 $SER；Termux 已安装（GitHub 版 0.118.x）
- 电脑有完整可构建的 Android SDK + Gradle 依赖缓存（用于离线推送）

## 1. 建立 SSH 通道（Termux 默认无 sshd）
Termux 未运行时用 run-as（需 ROM 允许）操作，注意 adb 传参引号会被吃掉：
`adb -s $SER shell "run-as com.termux sh -c '...'"`（内层再套单引号）
```sh
adb -s $SER forward tcp:8022 tcp:8022
# 换国内镜像: $PREFIX/etc/apt/sources.list → mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main
# 环境变量: HOME=$PREFIX/..(/data/data/com.termux/files/home) PREFIX TMPDIR LD_PRELOAD=$PREFIX/lib/libtermux-exec.so PATH
apt install -y openssh
mkdir -p ~/.ssh; cat 本机id_*.pub >> ~/.ssh/authorized_keys; chmod 600
sshd   # 监听 8022
```
验证：`ssh -p 8022 -o StrictHostKeyChecking=no localhost 'uname -m'`（应为 aarch64）

## 2. JDK / SDK
- `apt install -y openjdk-25`（仓库有 17/21/25，按项目 toolchain 选）
- SDK 从电脑推：tar 打包 `$SDK/platforms/<platform>` + `$SDK/build-tools/<ver>` + `licenses/`，adb push 到 /sdcard，Termux 解压到 ~/android-sdk
- Termux 写 `local.properties`: sdk.dir=/data/data/com.termux/files/home/android-sdk

## 3. ARM64 aapt2（关键）
AGP 的 Maven aapt2 是 x86_64 Linux 版，手机跑不了：
```sh
apt install -y aapt2 libc++   # libc++ 缺失会报 cannot locate symbol _ZNSt6__ndk1...
gradle.properties 加: android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2
```

## 4. 依赖缓存与 Gradle 发行版离线推送
- 电脑 `tar -czf` ~/.gradle/caches/modules-2 → 手机 ~/.gradle/caches/（省去手机网络下载）
- gradle 发行目录（~/.gradle/wrapper/dists/<dist>/<hash>/gradle-x.y）打包推送后直接用 `~/gradle-x.y/bin/gradle`，不走 wrapper

## 5. 内存/稳定性调优（LMK 会杀低优先级大内存 Java 进程）
gradle.properties 覆盖：
```
org.gradle.jvmargs=-Xms512m -Xmx2048m -XX:MaxMetaspaceSize=384m -XX:+ExitOnOutOfMemoryError
kotlin.daemon.jvmargs=-Xmx1280m -XX:MaxMetaspaceSize=384m
org.gradle.workers.max=2
org.gradle.vfs.watch=false
org.gradle.priority=normal        # 项目若设 low，LMK 优先杀 → "daemon disappeared unexpectedly"
```
6GB 机型参考：Gradle 2G + Kotlin 1.3G 可稳定跑完多模块 Compose 工程。

## 6. 只出一个 universal 包（测试用）
手机端副本把 app 模块 `splits { abi { isEnable = true } }` 改为 false（sed）。

## 7. 构建 / 取包
```sh
ssh -p 8022 localhost 'cd ~/proj && nohup ~/gradle-x.y/bin/gradle :app:assembleDebug --console=plain > ~/build.log 2>&1 &'
# 轮询: tail ~/build.log；完成后:
cp app/build/outputs/apk/.../app-*.apk /sdcard/ && adb -s $SER pull /sdcard/xxx.apk
```
注意：`pkill -f gradle` 会匹配到自身 ssh shell（命令行含关键字）导致 ssh 断连 exit 255，用精确进程名或 kill pid。

## 常见坑
- adb shell 多层引号：本地 shell 先吃一层，必须 `adb shell "..."` 内含单引号
- Android 7 (SDK 25)：Termux 0.118.3 可用；新版包需 API 24+，清华镜像正常
- 首次 `gradle help` 验证配置再跑 assemble；AGP 可能自动下载 platform-tools（需网络）
- 项目未设 voice.versionCode 时 versionCode=Int.MAX_VALUE，装后无法再装低版本（先卸载）
