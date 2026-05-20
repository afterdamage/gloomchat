// Conditional selector: use real flutter_callkit_incoming types on io
// (mobile / desktop), fall back to no-op stubs on web.
export 'callkit_events_stub.dart'
    if (dart.library.io) 'callkit_events_impl.dart';
