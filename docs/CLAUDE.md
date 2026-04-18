# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Open `MusicPlayer.xcodeproj` in Xcode and run on an iOS simulator or device. There is no CLI build system — all building, testing, and running happens through Xcode.

To build from the command line:
```
xcodebuild -project MusicPlayer.xcodeproj -scheme MusicPlayer -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Architecture

iOS/SwiftUI app with a pure UI prototype structure — no networking, no audio engine, no persistence. All data is static/mock.

### Navigation & State

**Three top-level tabs** managed by `AppTab` enum in [MusicApp.swift](MusicPlayer/MusicApp.swift):
- `.showcase` — content discovery (ForYou / Trends / Religious showcases, switched via `TopNavBar`)
- `.collection` — user's liked items with draggable cards
- `.player` — TikTok-style 2D swipe player

Navigation is handled manually in `MainContentView` using `activeAppTab: AppTab` state + three independent `NavigationStack`s (one per tab). The bottom bar (`BottomBar`) and top nav bar (`TopNavBar`) are overlaid as fixed ZStack layers.

**Global state objects** injected via `environmentObject` from `AppRootView`:
- `NowPlayingState` — current track, play/pause state, grid index
- `CollectionState` — the two most recently liked covers (used for BottomBar animation)
- `GyroManager` — device gyroscope data for parallax effects

`ToastManager` is a singleton accessed directly (`ToastManager.shared.show(...)`), not via environment.

### Player

[Player.swift](MusicPlayer/Screens/Player.swift) implements a TikTok-style infinite 2D grid pager:
- Position is a `GridIndex(x:y:)` — an unbounded integer grid
- Only the current slide and the neighbor in the active drag direction are rendered
- Tracks are deterministically assigned to grid positions using a seeded RNG (`SeededGenerator`) mixed with a per-session random salt — same position always shows the same track within a session
- Track cache is a static `[GridIndex: Track]` dict on the `Player` struct

### Data

- `TrackDataManager.shared` — lazy-cached list of `Track` objects (mock data)
- `AlbumDataManager.shared` — keyed by track title string, returns `AlbumData` with artist bio; cache is a `[String: AlbumData]` dict
- `Track` model: `id`, `title`, `artist`, `albumCover` (asset name string), `releaseYear`

### Design System

**Fonts** ([CustomFonts.swift](MusicPlayer/Fonts/CustomFonts.swift)):
- Headlines: `YangoGroupHeadlineAR-ExtraBold` — accessed as `Font.Headline1`–`Font.Headline5`
- Body: `YangoText-Medium` — accessed as `Font.Title1`, `Font.Title2`, `Font.Text1`–`Font.Text3`

**Colors** ([Colors.swift](MusicPlayer/Colors.swift)):
- `Color.fill1` = white
- `Color.subtitle` = white 50% opacity
- `Color.accent` = purple `#A433FF`

**External dependency**: `VariableBlur` (local Swift package in `/VariableBlur/`) — provides `VariableBlurView` used in `BottomBar` for the frosted gradient effect.

### Toast System

`ToastManager.shared.show(title:cover:)` triggers a pill-shaped toast that slides in from the top. Applied globally via `.toast(isPresented:config:)` view modifier on the root in `AppRootView`.
