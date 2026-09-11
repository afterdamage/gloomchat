import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/gloom_chat_tester.dart';
import 'auth_flows.dart';
import 'chat_flows.dart';

Future<void> basicMessaging(WidgetTester widgetTester) => widgetTester
    .startGloomChatTest()
    .then((tester) => tester._basicMessaging());

extension on GloomChatTester {
  Future<void> _basicMessaging() async {
    await ensureLoggedIn();
    await ensureGroupChatCreated();

    await tapOn(ChatFlows.groupChatName);
    const testMessage = 'Hello from integration test!';
    await enterText(Key('chat_input_field'), testMessage);
    await tapOn(Key('send_button'));
    await waitFor(testMessage);
  }
}
