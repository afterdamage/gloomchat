import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afterdamage/config/routes.dart';
import 'package:afterdamage/config/setting_keys.dart';
import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/dialer/call_screen.dart';
import 'package:afterdamage/pages/dialer/incoming_call_card.dart';
import 'package:afterdamage/theme/dracula_accents.dart';
import 'package:afterdamage/utils/voip_plugin.dart';
import 'package:afterdamage/widgets/app_lock.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:afterdamage/widgets/theme_builder.dart';
import '../utils/custom_scroll_behaviour.dart';

class GloomChatApp extends StatelessWidget {
  final Widget? testWidget;
  final List<Client> clients;
  final String? pincode;
  final SharedPreferences store;

  const GloomChatApp({
    super.key,
    this.testWidget,
    required this.clients,
    required this.store,
    this.pincode,
  });

  /// getInitialLink may rereturn the value multiple times if this view is
  /// opened multiple times for example if the user logs out after they logged
  /// in with qr code or magic link.
  static bool gotInitialLink = false;

  // Key used to access the Navigator's Overlay for call UI insertion.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Router must be outside of build method so that hot reload does not reset
  // the current path.
  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    routes: AppRoutes.routes,
    debugLogDiagnostics: true,
  );

  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(
      builder: (context, themeMode, primaryColor) {
        // Get the current Dracula accent from settings
        final accentName = AppSettings.draculaAccent.value;
        final draculaAccent = DraculaAccent.values.firstWhere(
          (accent) => accent.name == accentName,
          orElse: () => DraculaAccent.red,  // Default to red accent
        );

        return MaterialApp.router(
          title: AppSettings.applicationName.value,
          themeMode: themeMode,
          // Use light theme with Dracula accent as seed color
          theme: GloomThemes.buildTheme(
            context,
            Brightness.light,
            draculaAccent.previewColor,
          ),
          // Use Dracula accent theme for dark mode
          darkTheme: GloomThemes.buildAccentTheme(
            context,
            draculaAccent,
          ),
          scrollBehavior: CustomScrollBehavior(),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          routerConfig: router,
          builder: (context, child) => AppLockWidget(
            pincode: pincode,
            clients: clients,
            // Need a navigator above the Matrix widget for
            // displaying dialogs
            child: Matrix(
              clients: clients,
              store: store,
              // _CallScreenRoot wraps the entire router so the call UI
              // is always present regardless of which route is active.
              child: _CallScreenRoot(child: testWidget ?? child),
            ),
          ),
        );
      },
    );
  }
}

/// Wraps the entire app so the call UI is always present on every route.
///
/// Uses a [Stack] so the call screen sits on top of the entire router/Navigator
/// tree — no async [OverlayEntry] insertion, no insertion-order race conditions
/// with route pushes. The call widget is wired directly to [activeCallNotifier],
/// making it instantly and reliably reactive to incoming calls.
///
/// * **Web column mode**: compact [IncomingCallCard] positioned bottom-right.
/// * **All other cases (mobile, narrow web, desktop)**: full-screen [CallScreen].
class _CallScreenRoot extends StatefulWidget {
  final Widget? child;
  const _CallScreenRoot({this.child});

  @override
  State<_CallScreenRoot> createState() => _CallScreenRootState();
}

class _CallScreenRootState extends State<_CallScreenRoot> {
  ValueNotifier<ActiveCallState?>? _notifier;
  // Track whether the web column-mode incoming card was dismissed per-call.
  bool _cardDismissed = false;
  String? _lastCallId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newNotifier = Matrix.of(context).activeCallNotifier;
    if (newNotifier != _notifier) {
      _notifier?.removeListener(_onCallChanged);
      _notifier = newNotifier;
      _notifier!.addListener(_onCallChanged);
      // Pick up any call already in flight when this widget first builds.
      _syncCallId(_notifier!.value?.callId);
    }
  }

  void _syncCallId(String? callId) {
    if (callId != _lastCallId) {
      _lastCallId = callId;
      _cardDismissed = false;
    }
  }

  void _onCallChanged() {
    if (!mounted) return;
    setState(() => _syncCallId(_notifier?.value?.callId));
  }

  void _onClear() {
    final m = Matrix.of(context);
    m.activeCallNotifier.value = null;
    m.callExpandedNotifier.value = false;
  }

  @override
  void dispose() {
    _notifier?.removeListener(_onCallChanged);
    super.dispose();
  }

  Widget? _buildCallWidget(BuildContext context, ActiveCallState activeCall) {
    if (kIsWeb && GloomThemes.isColumnMode(context)) {
      // Desktop web: incoming notification card; sidebar handles connected state.
      if (activeCall.call.isOutgoing || _cardDismissed) return null;
      return Positioned(
        bottom: 24,
        right: 24,
        width: 300,
        child: IncomingCallCard(
          call: activeCall.call,
          client: activeCall.client,
          onDismiss: () => setState(() => _cardDismissed = true),
        ),
      );
    }

    // Mobile + narrow web + desktop non-column: full-screen call screen.
    return CallScreen(
      call: activeCall.call,
      client: activeCall.client,
      onClear: _onClear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseChild = widget.child ?? const SizedBox.shrink();
    final activeCall = _notifier?.value;

    if (activeCall == null) return baseChild;

    final callWidget = _buildCallWidget(context, activeCall);
    if (callWidget == null) return baseChild;

    return Stack(
      fit: StackFit.expand,
      children: [
        baseChild,
        callWidget,
      ],
    );
  }
}

