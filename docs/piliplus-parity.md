# PiliPlus parity backlog

This document records the feature gap between the current SwiftUI base and the inspected PiliPlus source tree. Existing cilicili functionality is intentionally preserved; this is an implementation backlog, not a claim that every item is already complete.

## Implemented in bili-Pro

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
- Streaming offline download progress, queue pause/resume/retry, local muxing and offline playback
- System-managed background video downloads through background URLSession callbacks
- WebDAV encrypted/safe backup and restore with credentials kept in Keychain
- DLNA renderer discovery and playback handoff
- Follow list, follow groups, watch later and history search
- Dynamic text/image publishing, repost, like synchronization and vote publishing
- Dynamic reservation-card creation and publishing, including server-issued reservation IDs
- Ranking, article search and audio search routes
- Native audio detail and AVPlayer playback from audio search results
- Popular series browsing (list and selected issue)
- Precious popular video feed
- Full account notification center: replies, mentions, likes, system notices, unread badges, pagination and private-message routing

## Priority parity work

### Verification notes

- Dynamic video投稿/upload pipeline (preupload, UPOS multipart upload, completion and稿件 submission)
- PiliPlus 2.1.0's dynamic composer publishes text/images, polls and links or attaches existing archive cards. Its `upload_bfs` endpoint is image upload for dynamic cards, not a video-archive preupload/UPOS submission pipeline; no unsupported video-archive uploader is claimed here.
- PGC season/episode playback and browsing routes are implemented in `VideoDetailPgcEpisodeSection` and `PgcSeasonPlaybackRouteView`.

## Implementation rules

Each feature is implemented as Swift/SwiftUI code on top of the existing `BiliAPIClient`, `SessionStore`, `LibraryStore`, feature ViewModels and design system. API DTOs are mapped into domain models; views do not parse response JSON or hold credentials. Remaining network features must follow the same loading/empty/error-state and focused-test requirements before being enabled in root navigation.
