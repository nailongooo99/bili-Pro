# bili-Pro

An open-source iOS Bilibili client based on [cilicili](https://github.com/Rone89/cilicili), built with Swift 6 and SwiftUI. bili-Pro preserves the original cilicili visual language, AVPlayer/HLS playback pipeline, and interaction foundation while adding feature parity work inspired by [PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus).

## Current capabilities

- Swift 6, SwiftUI, iOS 26.4+
- AVPlayer/HLS playback with quality selection, danmaku, subtitles, playback history, and local playback
- Recommendation home, search, uploader spaces, dynamic feed, video details, related videos, live rooms, and PGC playback
- Comments and replies, like, coin, favorite, follow, share, private messages, account messages, and multi-account sessions
- Keychain-backed credentials, offline download queue, WebDAV manifest backup, DLNA discovery and playback handoff
- Follow-list filtering and follow-group management
- SponsorBlock and playback/CDN diagnostics

## Architecture

Network requests are isolated in `BiliAPIClient`; response DTOs are mapped into domain models before reaching feature view models and SwiftUI views. Credentials are stored in Keychain. Ordinary preferences use UserDefaults. Offline download metadata is persisted as a JSON manifest under Application Support and media files remain local to the device.

New functionality is implemented in Swift/SwiftUI. Flutter/Dart source is not copied into this project.

## Build

Xcode 26.4+ and the iOS 26.4 SDK are required. Windows cannot run Xcode locally; pushes to `main` start the GitHub Actions workflow `Build unsigned IPA`.

```bash
xcodebuild -project bili.xcodeproj -scheme bili -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

The workflow builds `bili-pro-release-unsigned.ipa` and uploads it as `bili-pro-release-unsigned-ipa`. An unsigned IPA is an intermediate artifact and requires signing before ordinary device installation or distribution.

## License

GPLv3. Bilibili is a trademark and service of its respective owner. This project is not affiliated with Bilibili.
