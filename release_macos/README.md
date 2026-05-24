# 家庭健康 App - 全平台发布包

## 已编译好的版本（在 release/ 目录下）

```
release/
├── macos/
│   ├── family_health.app     ← macOS App (48MB)
│   ├── server                ← 后端 (macOS ARM64, 33MB)
│   └── start.command         ← 一键启动脚本
│
├── ios/
│   └── family_health.app     ← iOS App (19MB，需签名)
│
└── backend_source/            ← 后端源码（Windows/Linux 自行编译）
    ├── main.go
    ├── internal/
    └── go.mod
```

## 各平台使用方式

### ✅ macOS (Intel + Apple Silicon)
```bash
# 方式一：双击 start.command
# 方式二：手动
cd backend && ./bin/server &
open family_health.app
```

### ✅ iOS (iPhone/iPad)
需要 Apple Developer 账号签名：
```bash
# 在 Xcode 中打开项目
open app/ios/Runner.xcworkspace

# 选择你的开发者团队签名
# Product → Archive → Distribute App
```

### ⚠️ Windows
需要安装 Go 环境：
```powershell
# 1. 安装 Go (https://go.dev/dl)
# 2. 编译后端
cd backend
go build -o server.exe ./cmd/server

# 3. 运行后端 + 打开 App
.\server.exe
# 打开 family_health_app.exe（需要 Flutter 编译 Windows 版本）
```

### ⚠️ Linux
```bash
# 1. 安装 Go
sudo apt install golang-go

# 2. 编译后端
cd backend
go build -o server ./cmd/server

# 3. 运行
./server &
# 打开 App（需要 Flutter 编译 Linux 版本）
```

### ⚠️ Android
需要 Android SDK + Java：
```bash
# 1. 安装 JDK
brew install --cask zulu

# 2. 安装 Android SDK
sdkmanager "platforms;android-35" "build-tools;35.0.0"

# 3. 编译 APK
cd app
flutter build apk --release

# APK 位于: build/app/outputs/flutter-apk/app-release.apk
```

## 📊 项目总览

| 组件 | 技术 | 数量 |
|------|------|------|
| Go 后端 | Go + SQLite | 15 个 .go 文件 |
| Flutter App | Dart + Flutter | 41 个 .dart 文件 |
| 数据库 | SQLite（自动建表） | 17 张表 |
| API 端点 | RESTful | 40+ |
| 登录方式 | 手机号 / 邮箱 / 微信 / QQ | 4 种 |

## 分享给伙伴

```bash
# 直接分享 release/ 目录给朋友
# macOS 用户：双击 start.command
# 其他平台：参考上方对应平台的说明
```
