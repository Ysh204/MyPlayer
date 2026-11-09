import 'package:media_kit/media_kit.dart';

/// Sets a libmpv property on native media_kit platforms.
class MpvProperties {
  static Future<void> setProperty(
    Player player,
    String key,
    String value,
  ) async {
    final platform = player.platform;
    if (platform is NativePlayer) {
      await platform.setProperty(key, value);
    }
  }
}
