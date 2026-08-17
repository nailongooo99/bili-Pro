# bili-Pro

基于 [cilicili](https://github.com/Rone89/cilicili) 的 Swift 6 + SwiftUI Bilibili 第三方 iOS 客户端。项目保留 cilicili 的原生 UI、播放器和交互基础，并以 [PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus) 的功能覆盖作为后续补齐目标。

## 当前基线

- Swift 6 / SwiftUI
- iOS 26.4+
- AVPlayer + HLS Bridge 播放链路
- Keychain 登录态存储
- 首页推荐、搜索、UP 主空间、动态、视频详情、评论、弹幕和视频互动
- `.github/workflows/unsigned-ipa.yml` 自动构建未签名 IPA

## 开发原则

所有新增功能使用 Swift 原生实现，不移植 Flutter/Dart 代码；业务逻辑通过 `BiliAPIClient`、领域模型和 Feature ViewModel 接入现有架构。敏感登录凭据不得提交到仓库，普通偏好使用 UserDefaults，凭据使用 Keychain。

## 本地构建

需要 macOS、Xcode 26.4+ 和 iOS 26.4 SDK。Windows 环境不能运行 Xcode，本地可通过 GitHub Actions 构建。

```bash
xcodebuild -project bili.xcodeproj -scheme bili -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

## 构建未签名 IPA

推送到 `main` 或在 Actions 中手动运行 `Build unsigned IPA`，构建产物会作为 `bili-pro-release-unsigned-ipa` artifact 上传。未签名 IPA 不能直接安装到 iPhone，也不能用于 App Store/TestFlight 发布，仍需后续签名。

## 许可证与致谢

本项目遵循 GPLv3，并保留上游 cilicili 及其他第三方项目的版权和许可证声明。Bilibili 是其权利人的商标和服务，项目与 Bilibili 官方没有隶属关系。
