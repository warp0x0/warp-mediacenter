<p align="center">
<img src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/logo.png">
</p>

# Better Player Enhanced 🎬

[![pub package](https://img.shields.io/pub/v/better_player_enhanced.svg)](https://pub.dartlang.org/packages/better_player_enhanced)
[![License](https://img.shields.io/github/license/jhomlala/betterplayer.svg?style=flat)](https://github.com/jhomlala/betterplayer)
[![Platform](https://img.shields.io/badge/platform-flutter-blue.svg)](https://github.com/jhomlala/betterplayer)
[![Flutter](https://img.shields.io/badge/Flutter-3.27.0+-02569B?logo=flutter)](https://flutter.dev)
[![AndroidX Media3](https://img.shields.io/badge/AndroidX%20Media3-1.5.0-green?logo=android)](https://developer.android.com/media/media3)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/S6S71S8ARK)

## 🎯 The Most Advanced Flutter Video Player

**Better Player Enhanced** is a production-ready, feature-rich video player for Flutter applications. Built upon the foundation of the original [Better Player](https://pub.dev/packages/better_player) by [jhomlala](https://github.com/jhomlala), this enhanced version brings critical updates, modern architecture, and enterprise-grade features.

The project is updated regularly, and the community around it continues to grow, so you can expect more improvements and releases over time.

> 💡 **Why Choose Better Player Enhanced?**  
> This is the actively maintained fork that keeps your app compatible with the latest Flutter versions and Android ecosystem changes, while preserving all the powerful features you love.

---

## ✨ What's New in Enhanced Version

### 🔥 Latest Updates

- ✅ **AndroidX Media3 Migration** - Upgraded from deprecated ExoPlayer2 to Google's latest Media3 (1.5.0)
- ✅ **Flutter 3.27+ Compatible** - Fixed deprecated `hashValues` → `Object.hash`
- ✅ **Modern Android Build** - AGP 8.6.0, Kotlin 2.1.0, Gradle 8.9.0
- ✅ **Improved Stability** - Fixed Jetifier warnings and build compatibility issues
- ✅ **Active Maintenance** - Regular updates to keep pace with Flutter ecosystem

### 🙏 Credits & Acknowledgments

**Original Creator:** [jhomlala](https://github.com/jhomlala)  
This package builds upon the excellent foundation created by jhomlala. All credit for the original architecture, design, and feature set goes to the original author. We're committed to maintaining and enhancing this package while honoring the original vision.

---

<table>
   <tr>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/1.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/2.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/3.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/4.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/5.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/6.png">
      </td>
   </tr>
   <tr>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/7.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/8.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/9.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/10.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/11.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/12.png">
      </td>
   </tr>
   <tr>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/13.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/14.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/15.png">
      </td>
      <td>
         <img width="250px" src="https://raw.githubusercontent.com/jhomlala/betterplayer/master/media/16.png">
      </td>
    </tr>	
</table>

## 🚀 Why Better Player Enhanced?

### The Problem with Other Video Players

Most Flutter video players are either:

- 📦 **Too Basic** - Missing essential features for production apps
- 🐛 **Unmaintained** - Breaking with new Flutter releases
- 🔧 **Hard to Customize** - Limited configuration options
- 📱 **Platform-Specific Issues** - Poor Android/iOS parity

### The Better Player Enhanced Solution

Built on the proven [Chewie](https://github.com/brianegan/chewie) foundation and enhanced far beyond, this plugin solves real-world video playback challenges with enterprise-grade features.

---

## 🎯 Feature Highlights

### 🎬 Core Playback Features

| Feature                        | Description              |
| ------------------------------ | ------------------------ |
| 🎥 **Multiple Format Support** | HLS, DASH, MP4, and more |

| 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  better_player_enhanced: ^1.0.4
```

### Basic Usage

```dart
import 'package:better_player_enhanced/better_player.dart';

// Simple video player
BetterPlayerController controller = BetterPlayerController(
  BetterPlayerConfiguration(),
);

@override
Widget build(BuildContext context) {
  return BetterPlayer(
    controller: controller,
    betterPlayerDataSource: BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    ),
  );
}
```

### Advanced Example with All Features

```dart
BetterPlayerController controller = BetterPlayerController(
  BetterPlayerConfiguration(
    autoPlay: true,
    looping: false,
    fullScreenByDefault: false,
    aspectRatio: 16 / 9,
    // Subtitle configuration
    subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(
      fontSize: 20,
      fontColor: Colors.white,
    ),
    // Control bar configuration
    controlsConfiguration: BetterPlayerControlsConfiguration(
      enablePlayPause: true,
      enableMute: true,
      enableFullscreen: true,
      enableProgressBar: true,
      enableSubtitles: true,
    ),
  ),
);

BetterPlayerDataSource dataSource = BetterPlayerDataSource(
  BetterPlayerDataSourceType.network,
  "https://your-video-url.com/video.m3u8",
  // HTTP Headers
  headers: {"Custom-Header": "value"},
  // Subtitles
  subtitles: [
    BetterPlayerSubtitlesSource(
      type: BetterPlayerSubtitlesSourceType.network,
      name: "English",
      urls: ["https://example.com/subtitles_en.srt"],
    ),
    BetterPlayerSubtitlesSource(
      type: BetterPlayerSubtitlesSourceType.network,
      name: "Spanish",
      urls: ["https://example.com/subtitles_es.srt"],
    ),
  ],
  // Caching
  useAsmsCache: true,
  cacheConfiguration: BetterPlayerCacheConfiguration(
    maxCacheSize: 100 * 1024 * 1024, // 100MB
    maxCacheFileSize: 50 * 1024 * 1024, // 50MB
  ),
  // DRM
  drmConfiguration: BetterPlayerDrmConfiguration(
    drmType: BetterPlayerDrmType.widevine,
    licenseUrl: "https://your-license-server.com",
  ),
  // Notifications
  notificationConfiguration: BetterPlayerNotificationConfiguration(
    showNotification: true,
    title: "My Video Title",
    author: "Author Name",
  ),
);

controller.setupDataSource(dataSource);
```

---

## 📚 Documentation & Resources

### 📖 Learn More

- **[Official Documentation](https://jhomlala.github.io/betterplayer/)** - Comprehensive guides and tutorials
- **[API Reference](https://pub.dev/documentation/better_player/latest/)** - Complete API documentation
- **[Example Application](https://github.com/jhomlala/betterplayer/tree/master/example)** - 15+ working examples

### 🎓 Detailed Guides

- [Getting Started](https://jhomlala.github.io/betterplayer/#/gettingstarted)
- [Basic Player Usage](https://jhomlala.github.io/betterplayer/#/basicusage)
- [List Player](https://jhomlala.github.io/betterplayer/#/listplayerusage)
- [Playlist Player](https://jhomlala.github.io/betterplayer/#/playlistplayerusage)
- [Configuration Guide](https://jhomlala.github.io/betterplayer/#/generalconfiguration)
- [Subtitles Setup](https://jhomlala.github.io/betterplayer/#/subtitlesconfiguration)
- [DRM Implementation](https://jhomlala.github.io/betterplayer/#/drmconfiguration)
- [Caching Strategy](https://jhomlala.github.io/betterplayer/#/cacheconfiguration)
- [PiP Setup](https://jhomlala.github.io/betterplayer/#/pictureinpictureconfiguration)

---

## 🤝 Contributing

We welcome contributions! Whether it's:

- 🐛 Bug fixes
- ✨ New features
- 📝 Documentation improvements
- 🧪 Test coverage

Please feel free to submit pull requests. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/better_player_enhanced.git

# Install dependencies
flutter pub get

# Run example app
cd example
flutter run
```

---

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

## 🙋 Support

- 📧 **Issues**: [GitHub Issues](https://github.com/yourusername/better_player_enhanced/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/better_player_enhanced/discussions)
- ⭐ **Star**: If this project helped you, please give it a star!

---

## 🔄 Migration from Original Better Player

Switching from `better_player` to `better_player_enhanced` is seamless:

```yaml
# Before
dependencies:
  better_player: ^0.0.83

# After
dependencies:
  better_player_enhanced: ^1.0.0
```

No code changes required! All APIs remain compatible.

---

## ⚠️ Important Notes

- **Active Development**: This package is actively maintained and updated
- **Regular Releases**: The package is updated regularly as the community grows and new fixes land
- **Breaking Changes**: Minor versions may include breaking changes - always check the changelog
- **Platform Support**: Android 21+, iOS 11+
- **Flutter Version**: Requires Flutter 3.0.0 or higher

---

## 🌟 Show Your Support

If Better Player Enhanced makes your video playback easier, please:

- ⭐ Star this repository
- 🐦 Share with the Flutter community
- 💖 Consider sponsoring the project
- 🔗 Link back to this repo in your app

---

<p align="center">
  <strong>Made with ❤️ by the Flutter community</strong><br>
  <sub>Building upon the excellent work of <a href="https://github.com/jhomlala">jhomlala</a></sub>
</p>
| 🌐 **Format Support** | SRT, WEBVTT with full HTML tags support |
| 📡 **HLS Subtitles** | Native support for HLS embedded subtitles (including segmented) |
| 🌍 **Multiple Tracks** | Switch between multiple subtitle languages |
| 🎨 **Customizable Styling** | Full control over subtitle appearance |
| ⚙️ **Subtitle Configuration** | Position, size, color, background customization |

### 🎵 Audio & Video Tracks

| Feature                    | Description                                   |
| -------------------------- | --------------------------------------------- |
| 🔊 **Multi-Audio Support** | Select from multiple audio tracks             |
| 🎬 **Quality Selection**   | Switch between different video quality levels |
| 📊 **HLS Track Selection** | Full control over HLS variant streams         |
| 🎚️ **DASH Adaptation**     | Dynamic adaptive streaming over HTTP          |

### 🔐 Security & DRM

| Feature                     | Description                               |
| --------------------------- | ----------------------------------------- |
| 🔒 **Widevine DRM**         | Android DRM support                       |
| 🍎 **FairPlay DRM**         | iOS DRM support via EZDRM                 |
| 🎫 **Token Authentication** | Custom token-based DRM                    |
| 🔑 **ClearKey Support**     | Open standard DRM solution                |
| 🌐 **HTTP Headers**         | Custom headers for authenticated requests |

### 💾 Advanced Caching

| Feature                  | Description                        |
| ------------------------ | ---------------------------------- |
| 📦 **Smart Caching**     | Intelligent video caching system   |
| ⚙️ **Configurable Size** | Set max cache size and file limits |
| 🗂️ **Cache Management**  | Programmatic cache control         |
| 🚀 **Offline Playback**  | Pre-cache for offline viewing      |

### 📱 Mobile Experience

| Feature                     | Description                          |
| --------------------------- | ------------------------------------ |
| 📺 **Picture-in-Picture**   | Android & iOS PiP support            |
| 🔔 **Media Notifications**  | System-level playback controls       |
| 📋 **ListView Support**     | Optimized for scrollable video lists |
| 🎯 **Auto-Start/Stop**      | Visibility-based playback control    |
| 🔄 **Orientation Handling** | Seamless rotation support            |
| 🎨 **Custom UI**            | Build your own controls from scratch |

### 🎛️ Developer Features

| Feature                  | Description                                     |
| ------------------------ | ----------------------------------------------- |
| 📊 **Event System**      | Rich event callbacks (play, pause, error, etc.) |
| 🐛 **Error Handling**    | Comprehensive error reporting                   |
| ⚙️ **Configuration API** | Fine-grained control over all aspects           |
| 🔧 **Debug Options**     | Built-in debugging capabilities                 |
| 📖 **Well Documented**   | Extensive documentation and examples            |

---

## 📊 Comparison with Other Players

| Feature              | Better Player Enhanced | video_player | chewie | flick_video_player |
| -------------------- | :--------------------: | :----------: | :----: | :----------------: |
| HLS Support          |           ✅           |      ✅      |   ✅   |         ✅         |
| DASH Support         |           ✅           |      ❌      |   ❌   |         ❌         |
| DRM Support          |           ✅           |      ❌      |   ❌   |         ❌         |
| Subtitles (Advanced) |           ✅           |      ❌      |   ⚠️   |         ⚠️         |
| Caching              |           ✅           |      ❌      |   ❌   |         ❌         |
| Notifications        |           ✅           |      ❌      |   ❌   |         ❌         |
| Picture-in-Picture   |           ✅           |      ❌      |   ⚠️   |         ❌         |
| Playlist             |           ✅           |      ❌      |   ❌   |         ❌         |
| ListView Support     |           ✅           |      ❌      |   ⚠️   |         ⚠️         |
| Active Maintenance   |           ✅           |      ✅      |   ❌   |         ❌         |
| AndroidX Media3      |           ✅           |      ❌      |   ❌   |         ❌         |

---

## Documentation

- [Official documentation](https://jhomlala.github.io/betterplayer/)
- [Example application](https://github.com/jhomlala/betterplayer/tree/master/example)
- [API reference](https://pub.dev/documentation/better_player/latest/better_player/better_player-library.html)

## Important information

This plugin development is in progress. You may encounter breaking changes each version. This plugin is developed part-time for free. If you need
some feature which is supported by other players available in pub dev, then feel free to create PR. All valuable contributions are welcome!
