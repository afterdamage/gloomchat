import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/search/lurk_view.dart';

class SearchView extends StatelessWidget {
  final TabController tabController;

  const SearchView({required this.tabController, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).search),
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              icon: const FaIcon(FontAwesomeIcons.compass, size: 14),
              text: L10n.of(context).publicRooms,
            ),
            Tab(
              icon: const FaIcon(FontAwesomeIcons.cubes, size: 14),
              text: L10n.of(context).publicSpaces,
            ),
            Tab(
              icon: const FaIcon(FontAwesomeIcons.users, size: 14),
              text: L10n.of(context).users,
            ),
            Tab(
              icon: const FaIcon(FontAwesomeIcons.comments, size: 14),
              text: L10n.of(context).chats,
            ),
            Tab(
              icon: const FaIcon(FontAwesomeIcons.eye, size: 14),
              child: Text(L10n.of(context).lurk),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _PlaceholderTab(
            icon: const FaIcon(FontAwesomeIcons.compass),
            label: L10n.of(context).publicRooms,
          ),
          _PlaceholderTab(
            icon: const FaIcon(FontAwesomeIcons.cubes),
            label: L10n.of(context).publicSpaces,
          ),
          _PlaceholderTab(
            icon: const FaIcon(FontAwesomeIcons.users),
            label: L10n.of(context).users,
          ),
          _PlaceholderTab(
            icon: const FaIcon(FontAwesomeIcons.comments),
            label: L10n.of(context).chats,
          ),
          const LurkView(),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final Widget icon;
  final String label;

  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: theme.iconTheme.copyWith(
              size: 48,
              color: theme.colorScheme.secondary,
            ),
            child: icon,
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
