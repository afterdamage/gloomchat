import 'package:flutter/material.dart';

import 'settings_advanced_view.dart';

class AdvancedSettings extends StatefulWidget {
  const AdvancedSettings({super.key});

  @override
  AdvancedSettingsController createState() => AdvancedSettingsController();
}

class AdvancedSettingsController extends State<AdvancedSettings> {
  @override
  Widget build(BuildContext context) => AdvancedSettingsView(this);
}
