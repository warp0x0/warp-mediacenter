# Player Prototype Notes

This document records the Android TV playback experiments so we can park the player work, continue UI/performance work, and return later without losing context.

## Current Decision

- Keep the existing media-kit/mpv playback path for full movie/episode playback for now.
- Keep the patched `better_player_enhanced` path for `TrailerDialog` only.
- Do not move `PlaybackPage` to BetterPlayer texture rendering yet.
- Next real playback prototype should be native Android Media3/ExoPlayer using `SurfaceView`, controlled from Flutter through platform channels or a native activity.

## Baseline: media-kit/mpv

### Setup

- Existing full playback uses media-kit/mpv from Flutter.
- `PlaybackPage` remains on the media-kit path.
- Trailer playback previously also used the media-kit path.

### Observations

- Full UI flow and existing controls work.
- Trailer playback on Android TV was noticeably worse than expected.
- Playback felt laggy/stuttery and had A/V sync concerns.
- The TV UI remained usable, but media-kit did not look like native Android TV media-center playback.

### Result

- Keep as fallback/current full playback path.
- Do not invest heavily in mpv tuning until native Media3/SurfaceView prototype is tested.

## BetterPlayer / Media3 Texture Trial

### Goal

- Test whether AndroidX Media3/ExoPlayer performs better than media-kit on Android TV.
- Limit blast radius by wiring it only into trailers first.
- Preserve existing `TrailerDialog` D-pad controls and selector UX.

### Setup

- Added `better_player_enhanced: ^1.0.4` initially.
- Added `flutter_client/lib/player/better_trailer_player.dart`.
- Wired `flutter_client/lib/widgets/media/trailer_dialog.dart` to use BetterPlayer for trailers.
- Left `flutter_client/lib/pages/playback_page.dart` unchanged.
- Trailer path uses muxed YouTube streams first, because BetterPlayer/ExoPlayer cannot pair separate YouTube video-only and audio-only URLs the same way media-kit attempted.

### Build Issues

- `better_player_enhanced` hardcoded Android `compileSdkVersion 34`.
- Project build uses newer Android SDK requirements.
- Added a root Gradle override in `flutter_client/android/build.gradle.kts` to force Android library subprojects to `compileSdk = 36`.
- Release APK then built successfully.

### Runtime Failures

- First installed BetterPlayer build crashed before Flutter launched.
- Crash source was AndroidX Startup / WorkManager database initialization.
- Error was around `androidx.startup.InitializationProvider` and failing to create the WorkManager database.
- We disabled `androidx.work.WorkManagerInitializer` in `AndroidManifest.xml` to avoid startup DB initialization.
- That fixed app launch but trailer playback then failed at runtime.
- Runtime error: WorkManager was not initialized because the initializer had been disabled and the app did not provide manual configuration.
- Tried adding a custom `WarpApplication : FlutterApplication(), Configuration.Provider` and setting `android:name=".WarpApplication"`.
- That required adding a direct app WorkManager dependency to compile.
- Even with manual configuration, the user still saw DB crash behavior and trailer playback failed.

### Root Cause Found

- `better_player_enhanced` touches WorkManager eagerly when constructing a normal player.
- In `BetterPlayer.kt`, the plugin called `WorkManager.getInstance(context)` during player initialization.
- We are not using BetterPlayer pre-cache for trailers, so this WorkManager access is unnecessary for our path.
- BetterPlayer also uses WorkManager only in pre-cache and stop-pre-cache APIs, which we are not calling.

### Final Patch

- Vendored `better_player_enhanced` into `flutter_client/third_party/better_player_enhanced`.
- Patched its Android code to remove eager `WorkManager.getInstance(context)` from normal player construction.
- Kept the app manifest override that disables WorkManager auto-startup.
- Removed the custom `WarpApplication` and app-level WorkManager dependency/configuration path.
- Updated `pubspec.yaml` to use the local patched BetterPlayer package:

```yaml
better_player_enhanced:
  path: third_party/better_player_enhanced
```

- Excluded `third_party/**` from app analyzer because the vendored package example app is incomplete/noisy.
- Pruned unused vendored sample/docs/media/test content.

### Verification

- `flutter pub get` succeeded.
- `flutter test` passed.
- `flutter analyze` passed after excluding `third_party/**`.
- `flutter build apk --release` passed.
- APK installed successfully on the Android TV.
- User confirmed trailer playback now works.

### Result

- BetterPlayer/ExoPlayer trailer playback is clearly better than the media-kit trailer version.
- It is still not as smooth as normal Android TV media-center apps.
- It feels possibly around 30fps or otherwise frame-paced poorly.
- It is acceptable/manageable for trailers.
- It is not good enough to trust for full movie/episode playback.

## SurfaceView Investigation

### Finding

- `better_player_enhanced` 1.0.4 does not expose a SurfaceView/TextureView selection option.
- Android implementation uses Flutter `TextureRegistry.createSurfaceTexture()` plus ExoPlayer `Surface`.
- That means video is still rendered through Flutter texture composition.
- This likely explains why BetterPlayer improves decode/player behavior but still does not reach native Android TV smoothness.

### Implication

- BetterPlayer texture rendering should stay trailer-only.
- Full movie/episode playback likely needs a native Android player screen using Media3/ExoPlayer with `SurfaceView`.

## Important Playback UX Constraints

- Root D-pad Back remains disabled in the Flutter app wrapper.
- Pages/dialogs own Back/Escape/goBack/browserBack.
- Existing playback Back behavior must remain:
  - If controls are visible, Back should focus seek/progress and hide controls.
  - If controls are hidden, Back should stop/exit through scrobble/cleanup.
- TrailerDialog D-pad controls and selector UX should remain unchanged.
- Do not delete the existing media-kit playback module yet.

## Next Prototype Plan: Native Media3 SurfaceView Player

### Goal

- Build an Android TV-native fullscreen player path using Media3/ExoPlayer with `SurfaceView`.
- Use Flutter for browsing/catalog UI.
- Hand off full playback to native Android for movies/episodes.
- Keep media-kit as fallback while the native prototype is validated.

### Proposed Architecture

- Add a native Android `Activity` or platform-owned fullscreen player screen.
- Use Media3 `ExoPlayer` with a native `PlayerView` configured for `SurfaceView`.
- Start playback from Flutter via `MethodChannel` or route intent data.
- Pass playback request fields from Flutter:
  - media URL
  - title/subtitle
  - poster/backdrop if needed
  - start position
  - headers if needed
  - media type/id for scrobble callbacks
- Native side owns:
  - play/pause
  - seek
  - D-pad handling
  - subtitles/audio tracks
  - buffering state
  - back/exit behavior
  - optional refresh-rate matching
- Flutter receives final playback state on exit:
  - stopped/completed/error
  - final position
  - duration
  - progress for resume/scrobble

### Prototype Milestones

1. Create minimal native Android Media3 player activity with a hardcoded test URL.
2. Confirm it uses `SurfaceView`, not Flutter texture rendering.
3. Verify smoothness/frame pacing on the Sony/BRAVIA Android TV.
4. Add Flutter method to launch the native player with a URL.
5. Add native Back handling matching current playback semantics.
6. Return final position/result to Flutter.
7. Wire one temporary test action from the app to launch native playback.
8. Only after validation, consider replacing Android TV `PlaybackPage` with native player launch.

### Open Questions

- Whether to implement as a full native `Activity` or as an Android platform view.
- Whether overlays/controls should be fully native or mixed Flutter/native.
- Whether Media3 refresh-rate switching should be enabled immediately or after basic playback works.
- How subtitles/audio track selection maps to current app metadata.
- Whether scrobble/progress updates should stream during playback or only return on exit for the prototype.

## Recommendation When We Return

- Do not spend more time trying to make BetterPlayer texture rendering into the full playback solution.
- Use the working BetterPlayer trailer path as proof that ExoPlayer is better on this TV.
- Prototype native Media3/SurfaceView next.
- If native playback is smooth, make it the Android TV full playback path and keep media-kit for desktop/non-TV fallback.
