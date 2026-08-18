# PiliPlus parity backlog

This document records the feature gap between the current SwiftUI base and the inspected PiliPlus source tree. Existing cilicili functionality is intentionally preserved; this is an implementation backlog, not a claim that every item is already complete.

## Already present in the SwiftUI base

- Home recommendation, search, uploader space, video detail and related videos
- Dynamic feed with image/video/repost cards and comments/replies; text and single-image publishing
- AVPlayer/HLS playback, quality selection, playback history and diagnostics
- Danmaku rendering, settings and keyword filtering
- Live feed, live room playback and live danmaku
- Like, coin, favorite, follow and share flows
- PGC playback routes
- Private messages/account messages
- Multi-account session models and Keychain-backed credentials
- SponsorBlock and CDN/playback optimization

## Priority parity work

### P0: download and backup foundations

- Background-aware download task model with pause/resume/retry states and queue rehydration
- Video/audio stream selection and local muxing into a playable local MP4
- Download library and offline playback route
- WebDAV backup/restore for safe app settings and download manifests (credentials/tokens remain local Keychain data)
- Secure credential storage for WebDAV; never persist passwords in UserDefaults

### P1: device and social expansion

- DLNA discovery, renderer selection and playback handoff
- Follow groups and follow-list filtering
- Watch-later list, video-detail save action, and swipe-to-remove management
- Dynamic text publishing, repost, and like synchronization
- Dynamic video publishing, vote and reserve flows
- More complete message/reply notification sections

### P2: content breadth

- Article and audio browsing
- Rank, popular series and precious popular pages
- History search (watch-later management is implemented)
- Expanded PGC review and season browsing

## Implementation rules

Each feature should be implemented as Swift/SwiftUI code on top of the existing `BiliAPIClient`, `SessionStore`, `LibraryStore`, feature ViewModels and design system. API DTOs must be mapped into domain models; views must not parse response JSON or hold credentials. Every network feature needs loading/empty/error states and at least one focused unit test before it is enabled in the root navigation.
