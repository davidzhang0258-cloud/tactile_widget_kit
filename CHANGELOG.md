# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and adheres to
[Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-10-14

### Added

- Native Android `AppWidgetProvider` bridge (`WonderCalendarWidgetProvider`) with
  `MethodChannel` round-trip via `home_widget` and the `qualifiedAndroidName` fix.
- Off-screen `Canvas` renderer (`WonderCalendarRenderer`) producing a Binder-safe
  400×400 transparent overlay.
- Self-contained 5×7 bitmap pixel-font engine (`PixelFont`) with no `.ttf`
  dependency and cached sprite bitmaps.
- Repository + Hive architecture (`TickRepository` / `HiveTickRepository`).
- Tactile skeuomorphic console UI with a three-layer `Stack` and a four-stage
  serial insertion animation with haptics and keyboard-focus choreography.
- Widget deep-linking into a specific in-app screen.

### Changed

- Project renamed and re-scoped from a proprietary diary app to a generic
  starter kit (`tactile_widget_kit`, `com.tactile.widgetkit`).
- Removed proprietary assets and restored standard Gradle repositories.

## [0.5.0] - 2026-09-13

### Added

- Two-page tactile console UI (`WonderCalendarHomePage`,
  `WonderDaySlotPage`).
- Chained four-stage cartridge insertion choreography (560 ms) with differential
  multi-card motion and haptic feedback.

## [0.1.0] - 2026-06-27

### Added

- Flutter project skeleton with repository contract and Hive-backed persistence.
- Off-screen pixel rendering pipeline and bitmap font engine.
- Native AppWidget bridge and widget deep-link routing.

[1.0.0]: https://github.com/davidzhang0258-cloud/tactile_widget_kit/releases/tag/v1.0.0
[0.5.0]: https://github.com/davidzhang0258-cloud/tactile_widget_kit/releases/tag/v0.5.0
[0.1.0]: https://github.com/davidzhang0258-cloud/tactile_widget_kit/releases/tag/v0.1.0
