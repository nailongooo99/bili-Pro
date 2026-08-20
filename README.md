# bili-Pro 1.0

一个基于 **Swift 6 + SwiftUI** 的开源哔哩哔哩第三方 iOS 客户端。bili-Pro 以 [cilicili](https://github.com/Rone89/cilicili) 为底座，保留其原有的界面风格、颜色主题、排版、交互动效和 AVPlayer/HLS 播放链路，并参考 [PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus) 补齐跨功能体验。

## 1.0 功能

- 首页推荐、热门、搜索、UP 主空间、视频详情、相关推荐
- AVPlayer/HLS 播放、画质/音质选择、倍速、弹幕、字幕、播放历史和记忆播放
- 动态浏览与发布：文字、图片、投票、转发、预约卡创建/更新/附加
- 评论、楼中楼、点赞、投币、收藏、关注、分享和三连相关交互
- 直播、直播弹幕、PGC 季度/剧集浏览与播放
- 私信和账号消息：回复、提及、点赞、系统通知、未读数和分页
- 多账号、Keychain 登录态、关注分组、稍后再看、观看历史
- 离线下载、后台单流视频下载、本地播放、WebDAV 备份与恢复
- DLNA 投屏、SponsorBlock、CDN/播放诊断、排行榜、专栏和音频搜索

## 与参考项目的区别

| 对比项 | bili-Pro | PiliPlus | cilicili |
| --- | --- | --- | --- |
| 技术栈 | Swift 6 + SwiftUI，原生 iOS | Flutter + Dart，跨 Android/iOS/Windows/Linux | Swift 6 + SwiftUI，原生 iOS |
| UI 基础 | 延续 cilicili 的原生视觉体系，并扩展功能页面 | Flutter 自有组件体系，使用 GetX 响应式状态 | 原生 SwiftUI，强调简洁的 iOS 交互 |
| 播放器 | AVPlayer/HLS，针对 iOS 26+ 优化 | media_kit，支持多平台播放能力 | AVPlayer/HLS Bridge |
| 状态与业务组织 | SwiftUI ViewModel、服务层和 `BiliAPIClient` | GetX Controller、`LoadingState<T>`、分层模块 | SwiftUI 状态模型与服务层 |
| 登录与持久化 | Keychain 保存凭据；UserDefaults 和本地 JSON 保存偏好/下载元数据 | Hive、本地缓存和多账号存储 | Keychain 保存登录态 |
| 功能取向 | 在原生 iOS 体验下融合两者能力，重点强化下载、投屏、消息、多账号和播放器诊断 | 功能覆盖最广、平台最多，包含直播、DLNA、WebDAV、离线等大量模块 | 保持原生 iOS 的轻量和一致性，功能范围相对收敛 |
| 代码复用方式 | 不复制 Flutter/Dart；按业务流程重新用 Swift 实现 | Flutter/Dart 原生实现 | 作为 SwiftUI 原始底座和设计参考 |

### 设计取舍

- bili-Pro 不直接粘贴 PiliPlus 的 Flutter 代码，而是复用其 API 业务流程、状态流转和交互思路。
- PiliPlus 2.1.0 的 `upload_bfs` 是动态图片上传接口，并不包含视频稿件 preupload/UPOS 投稿流程，因此 bili-Pro 不伪造不存在的投稿接口。
- bili-Pro 优先保持 cilicili 的原生 iOS 手感，再加入 PiliPlus 中适合 iOS 的功能模块。

## 架构

网络请求集中在 `BiliAPIClient`，服务层负责认证、请求和响应解码，模型层将 API DTO 转换为领域模型，ViewModel 管理加载/空态/错误态，SwiftUI View 只负责展示和交互。凭据存储在 Keychain，普通偏好使用 UserDefaults，离线下载索引保存在 Application Support 的本地 JSON 清单中。

## 构建与 IPA

需要 Xcode 26.4+ 和 iOS 26.4 SDK。Windows 无法本地运行 Xcode；推送到 `main` 后可通过 GitHub Actions 的 `Build unsigned IPA` 工作流构建未签名 IPA。

未签名 IPA 仅适合测试、研究和后续签名处理，不代表已完成 Apple 签名或 App Store 分发流程。

## 许可证

本项目采用 GPLv3。Bilibili 是其权利人的商标和服务，本项目与 Bilibili 官方无隶属关系。
