import 'dart:async';

Future<String> tapScreen(int x, int y) async {
  return 'Tap at ($x, $y) requires AccessibilityService. Enable in Settings > Accessibility > Agentic AI.';
}

Future<String> swipeScreen(int x1, int y1, int x2, int y2) async {
  return 'Swipe from ($x1,$y1) to ($x2,$y2) requires AccessibilityService.';
}

Future<String> typeText(String text) async {
  return 'Type "$text" requires AccessibilityService with text input capability.';
}

Future<String> pressKey(String key) async {
  final validKeys = ['back', 'home', 'recents', 'power', 'volume_up', 'volume_down'];
  if (!validKeys.contains(key.toLowerCase())) {
    return 'Unknown key: $key. Valid keys: ${validKeys.join(', ')}';
  }
  return 'Press $key requires AccessibilityService with global action capability.';
}