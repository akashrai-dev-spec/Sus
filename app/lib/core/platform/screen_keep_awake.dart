import 'package:flutter/foundation.dart';

abstract class ScreenKeepAwake {
  static void enable() {
    // Desktop Linux / Windows / macOS safe no-op
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return;
    }
  }

  static void disable() {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return;
    }
  }
}
