import 'package:flutter/foundation.dart';

class PlatformGate {
  const PlatformGate();

  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get isSupportedMobile => isAndroid || isIOS;
}
