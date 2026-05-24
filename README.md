# 家庭健康 (Family Health Care)

全平台家庭健康管理 App

## 技术栈

- **前端**: Flutter（Android / iOS / macOS / Windows / Linux）
- **后端**: Go + SQLite
- **部署**: 百度云 (106.12.8.123)
- **域名**: api.fhc-ai.com

## 后端部署

后端自动运行于百度云服务器，API 地址：

```
https://api.fhc-ai.com/api/v1
```

## 本地开发

```bash
# 后端
cd backend
go build -o server ./cmd/server
./server

# 前端
cd app
flutter run -d macos
```

## 通过 GitHub Actions 编译

将代码推送至 GitHub 后，Actions 会自动编译：

1. **Push 到 main 分支** → 自动触发
2. 到 Actions 页面下载编译产物
3. Android APK 和 macOS 包均可下载

## 编译产物

| 平台 | 工作流 | 产物 |
|------|--------|------|
| Android | `android.yml` | `app-release.apk` |
| macOS | `macos.yml` | `family-health-macos.zip` |
