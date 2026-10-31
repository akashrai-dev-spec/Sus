import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class PlatformFeedback {
  static void lightImpact() {
    // Only execute haptic feedback on supported mobile platforms
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.lightImpact();
    }
  }

  static void mediumImpact() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      HapticFeedback.mediumImpact();
    }
  }
}
