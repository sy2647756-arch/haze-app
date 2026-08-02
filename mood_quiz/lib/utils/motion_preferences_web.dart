import 'package:web/web.dart' as web;

bool platformPrefersReducedMotion() =>
    web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;
