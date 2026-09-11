import 'package:flutter/material.dart';

import 'package:afterdamage/pages/search/search_view.dart';

enum SearchTab { publicRooms, publicSpaces, users, chats, lurk }

class LurkSearchController extends StatefulWidget {
  const LurkSearchController({super.key});

  @override
  LurkSearchControllerState createState() => LurkSearchControllerState();
}

class LurkSearchControllerState extends State<LurkSearchController>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;

  SearchTab get activeTab =>
      SearchTab.values[tabController.index.clamp(0, SearchTab.values.length - 1)];

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: SearchTab.values.length,
      vsync: this,
    );
    tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SearchView(tabController: tabController);
}
