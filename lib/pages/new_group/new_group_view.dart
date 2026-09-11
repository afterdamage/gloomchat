import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/new_group/new_group.dart';
import 'package:afterdamage/utils/localized_exception_extension.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'package:afterdamage/widgets/layouts/max_width_body.dart';
import 'package:flutter/material.dart';
import 'package:afterdamage/widgets/square_switch.dart';

class NewGroupView extends StatelessWidget {
  final NewGroupController controller;

  const NewGroupView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final avatar = controller.avatar;
    final error = controller.error;
    return Scaffold(
      appBar: AppBar(
        leading: Center(
          child: BackButton(
            onPressed: controller.loading ? null : Navigator.of(context).pop,
          ),
        ),
        title: Text(
          controller.createGroupType == CreateGroupType.space
              ? L10n.of(context).newSpace
              : L10n.of(context).createGroup,
        ),
      ),
      body: MaxWidthBody(
        child: Column(
          mainAxisSize: .min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SegmentedButton<CreateGroupType>(
                style: SegmentedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                selected: {controller.createGroupType},
                onSelectionChanged: controller.setCreateGroupType,
                segments: [
                  ButtonSegment(
                    value: CreateGroupType.group,
                    label: Text(L10n.of(context).group),
                  ),
                  ButtonSegment(
                    value: CreateGroupType.space,
                    label: Text(L10n.of(context).space),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.zero,
              onTap: controller.loading ? null : controller.selectPhoto,
              child: CircleAvatar(
                radius: Avatar.defaultSize,
                child: avatar == null
                    ? const Icon(Icons.add_a_photo_outlined)
                    : ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: Image.memory(
                          avatar,
                          width: Avatar.defaultSize * 2,
                          height: Avatar.defaultSize * 2,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                autofocus: true,
                controller: controller.nameController,
                autocorrect: false,
                readOnly: controller.loading,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.people_outlined),
                  labelText: controller.createGroupType == CreateGroupType.space
                      ? L10n.of(context).spaceName
                      : L10n.of(context).groupName,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SquareSwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 32),
              secondary: const Icon(Icons.public_outlined),
              title: Text(
                controller.createGroupType == CreateGroupType.space
                    ? L10n.of(context).spaceIsPublic
                    : L10n.of(context).groupIsPublic,
              ),
              value: controller.publicGroup,
              onChanged: controller.loading ? null : controller.setPublicGroup,
            ),
            AnimatedSize(
              duration: GloomThemes.animationDuration,
              curve: GloomThemes.animationCurve,
              child: controller.publicGroup
                  ? SquareSwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 32,
                      ),
                      secondary: const Icon(Icons.search_outlined),
                      title: Text(L10n.of(context).groupCanBeFoundViaSearch),
                      value: controller.groupCanBeFound,
                      onChanged: controller.loading
                          ? null
                          : controller.setGroupCanBeFound,
                    )
                  : const SizedBox.shrink(),
            ),
            AnimatedSize(
              duration: GloomThemes.animationDuration,
              curve: GloomThemes.animationCurve,
              child: controller.createGroupType == CreateGroupType.space
                  ? const SizedBox.shrink()
                  : SquareSwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 32,
                      ),
                      secondary: Icon(
                        Icons.lock_outlined,
                        color: theme.colorScheme.onSurface,
                      ),
                      title: Text(
                        L10n.of(context).enableEncryption,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      value: !controller.publicGroup,
                      onChanged: null,
                    ),
            ),
            AnimatedSize(
              duration: GloomThemes.animationDuration,
              curve: GloomThemes.animationCurve,
              child: controller.createGroupType == CreateGroupType.space
                  ? ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 32,
                      ),
                      trailing: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Icon(Icons.info_outlined),
                      ),
                      subtitle: Text(L10n.of(context).newSpaceDescription),
                    )
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.loading
                      ? null
                      : controller.submitAction,
                  child: controller.loading
                      ? const LinearProgressIndicator()
                      : Text(
                          controller.createGroupType == CreateGroupType.space
                              ? L10n.of(context).createNewSpace
                              : L10n.of(context).createGroupAndInviteUsers,
                        ),
                ),
              ),
            ),
            AnimatedSize(
              duration: GloomThemes.animationDuration,
              curve: GloomThemes.animationCurve,
              child: error == null
                  ? const SizedBox.shrink()
                  : ListTile(
                      leading: Icon(
                        Icons.warning_outlined,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        error.toLocalizedString(context),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
