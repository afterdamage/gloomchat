// Stub for non-mobile platforms (web, desktop).
// Provides no-op implementations of flutter_callkit_incoming types so that
// voip_plugin.dart compiles on all platforms.
import 'dart:async';

// Minimal stub of the Event enum — only the variants consumed by voip_plugin.
enum Event {
  actionCallAccept,
  actionCallDecline,
  actionCallEnded,
  actionCallTimeout,
}

class CallEvent {
  final Event event;
  final dynamic body;
  const CallEvent(this.body, this.event);
}

class FlutterCallkitIncoming {
  static Stream<CallEvent?> get onEvent => const Stream.empty();
  static Future<void> setCallConnected(String id) async {}
}
