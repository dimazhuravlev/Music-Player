# Music Player App Structure

## Overview
This SwiftUI music player app has been organized into a clean, modular structure for better maintainability and code organization.

## Folder Structure

### 📱 Screens/
Contains the main screen views of the application:
- **Showcase.swift** - Main home screen with playlist carousels and mini player
- **Player.swift** - Swipe-based full-screen player experience

### 🧩 Features/
Contains reusable UI components and features:
- **PlaylistCarousel.swift** - Horizontal scrolling playlist carousel component
- **PlayPauseButton.swift** - Animated play/pause button with background effects
- **AnimatedIconButton.swift** - Reusable animated icon button with state transitions
- **HeartExplosionView.swift** - Heart explosion animation effect for like interactions

### 📄 Root Files
- **MusicApp.swift** - Main app entry point and configuration
- **MusicPlayer.entitlements** - App entitlements and permissions
- **Assets.xcassets/** - Image assets and app icons

## Dependencies
- All components are designed to work together within the same SwiftUI module
- No external dependencies required
- Components are self-contained and reusable

## Usage
The app follows a standard SwiftUI architecture where:
1. `MusicApp.swift` serves as the entry point
2. `Showcase.swift` is the main home screen
3. `Player.swift` provides the swipe-based player experience
4. All UI components in `Features/` are used across different screens
