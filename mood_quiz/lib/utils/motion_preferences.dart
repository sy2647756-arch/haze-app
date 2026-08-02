import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'motion_preferences_stub.dart'
    if (dart.library.js_interop) 'motion_preferences_web.dart';

/// Uses the browser's real CSS media query on Web because the engine-level
/// accessibility flag can be overly broad on some Windows configurations.
bool prefersReducedMotion(BuildContext context) {
  if (kIsWeb) return platformPrefersReducedMotion();
  return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}
