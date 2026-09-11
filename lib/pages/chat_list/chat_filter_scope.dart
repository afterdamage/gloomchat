import 'package:flutter/widgets.dart';

import 'package:afterdamage/pages/chat_list/chat_list.dart';

class ChatFilterScope extends InheritedWidget {
  final ActiveFilter activeFilter;
  final ValueChanged<ActiveFilter> onFilterChanged;

  const ChatFilterScope({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    required super.child,
  });

  static ChatFilterScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatFilterScope>();

  @override
  bool updateShouldNotify(ChatFilterScope oldWidget) =>
      activeFilter != oldWidget.activeFilter;
}
