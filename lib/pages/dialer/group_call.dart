/*
 *   GloomChat
 *   Copyright (C) 2024 Afterdamage
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 */

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide VideoRenderer;
import 'package:matrix/matrix.dart';
import 'package:matrix/src/voip/backend/mesh_backend.dart';
import 'package:matrix/src/voip/utils/types.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:afterdamage/utils/platform_infos.dart';
import 'package:afterdamage/utils/voip/video_renderer.dart';
import 'package:afterdamage/widgets/avatar.dart';
import 'pip/pip_view.dart';

/// A participant tile in the group call grid.
class _ParticipantTile extends StatelessWidget {
  final WrappedMediaStream stream;
  final Client matrixClient;

  const _ParticipantTile({
    required this.stream,
    required this.matrixClient,
  });

  @override
  Widget build(BuildContext context) {
    final videoMuted = stream.videoMuted;
    final audioMuted = stream.audioMuted;
    final mirrored = stream.isLocal() &&
        stream.purpose == SDPStreamMetadataPurpose.Usermedia;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.zero,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!videoMuted)
            VideoRenderer(
              stream,
              mirror: mirrored,
              fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            ),
          if (videoMuted) ...[
            Container(color: Colors.black54),
            Avatar(
              mxContent: stream.getUser().avatarUrl,
              name: stream.displayName,
              size: 56,
              client: matrixClient,
            ),
          ],
          // Name + mute indicators
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (audioMuted)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: FaIcon(
                        FontAwesomeIcons.microphoneSlash,
                        color: Colors.redAccent,
                        size: 12,
                      ),
                    ),
                  Text(
                    stream.displayName ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen group call UI with participant grid and controls.
class GroupCalling extends StatefulWidget {
  final VoidCallback? onClear;
  final BuildContext context;
  final GroupCallSession groupCall;
  final Client client;

  const GroupCalling({
    required this.context,
    required this.groupCall,
    required this.client,
    this.onClear,
    super.key,
  });

  @override
  State<GroupCalling> createState() => _GroupCallingState();
}

class _GroupCallingState extends State<GroupCalling> {
  GroupCallSession get groupCall => widget.groupCall;
  MeshBackend get _backend => groupCall.backend as MeshBackend;

  bool _micMuted = false;
  bool _camMuted = false;
  bool _screenSharing = false;

  List<WrappedMediaStream> get _streams {
    final streams = <WrappedMediaStream>[];
    // Collect all user media streams from the mesh backend
    streams.addAll(_backend.userMediaStreams);
    streams.addAll(_backend.screenShareStreams);
    return streams;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}

    // Listen for feed changes from the mesh backend
    _backend.onGroupCallFeedsChanged.stream.listen((_) {
      if (mounted) setState(() {});
    });

    // Listen for group call state changes
    groupCall.matrixRTCEventStream.stream.listen((_) {
      if (mounted) setState(() {});
    });

    // Enter the group call
    try {
      await groupCall.enter();
    } catch (e) {
      Logs().e('[GroupCall] Failed to enter: $e');
    }
  }

  @override
  void dispose() {
    try {
      WakelockPlus.disable();
    } catch (_) {}
    super.dispose();
  }

  void _toggleMic() {
    _micMuted = !_micMuted;
    _backend.setDeviceMuted(groupCall, _micMuted, MediaInputKind.audioinput);
    setState(() {});
  }

  void _toggleCamera() {
    _camMuted = !_camMuted;
    _backend.setDeviceMuted(groupCall, _camMuted, MediaInputKind.videoinput);
    setState(() {});
  }

  void _toggleScreenShare() async {
    if (PlatformInfos.isAndroid && !_screenSharing) {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'notification_channel_id',
          channelName: 'Foreground Notification',
          channelDescription: L10n.of(widget.context).foregroundServiceRunning,
        ),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
        ),
      );
      FlutterForegroundTask.startService(
        notificationTitle: L10n.of(widget.context).screenSharingTitle,
        notificationText: L10n.of(widget.context).screenSharingDetail,
      );
    } else if (PlatformInfos.isAndroid && _screenSharing) {
      FlutterForegroundTask.stopService();
    }

    setState(() {
      _screenSharing = !_screenSharing;
      _backend.setScreensharingEnabled(groupCall, _screenSharing, '');
    });
  }

  void _leaveCall() async {
    try {
      await groupCall.leave();
    } catch (e) {
      Logs().e('[GroupCall] Failed to leave: $e');
    }
    widget.onClear?.call();
  }

  /// Builds a responsive grid of participant tiles.
  Widget _buildParticipantGrid() {
    final streams = _streams;
    if (streams.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.users, size: 48, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Waiting for participants...',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
          ],
        ),
      );
    }

    // Calculate grid dimensions
    final count = streams.length;
    final columns = count <= 1 ? 1 : count <= 4 ? 2 : 3;
    final rows = (count / columns).ceil();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 4 / 3,
      ),
      itemCount: count,
      itemBuilder: (context, index) => _ParticipantTile(
        stream: streams[index],
        matrixClient: widget.client,
      ),
    );
  }

  List<Widget> _buildControls() {
    return [
      FloatingActionButton(
        heroTag: 'gc_mic',
        onPressed: _toggleMic,
        foregroundColor: _micMuted ? Colors.black26 : Colors.white,
        backgroundColor: _micMuted ? Colors.white : Colors.black45,
        child: FaIcon(
          _micMuted
              ? FontAwesomeIcons.microphoneSlash
              : FontAwesomeIcons.microphone,
        ),
      ),
      FloatingActionButton(
        heroTag: 'gc_cam',
        onPressed: _toggleCamera,
        foregroundColor: _camMuted ? Colors.black26 : Colors.white,
        backgroundColor: _camMuted ? Colors.white : Colors.black45,
        child: FaIcon(
          _camMuted ? FontAwesomeIcons.videoSlash : FontAwesomeIcons.video,
        ),
      ),
      if (PlatformInfos.isMobile || PlatformInfos.isWeb)
        FloatingActionButton(
          heroTag: 'gc_screen',
          onPressed: _toggleScreenShare,
          foregroundColor: _screenSharing ? Colors.black26 : Colors.white,
          backgroundColor: _screenSharing ? Colors.white : Colors.black45,
          child: const FaIcon(FontAwesomeIcons.desktop),
        ),
      FloatingActionButton(
        heroTag: 'gc_leave',
        onPressed: _leaveCall,
        backgroundColor: Colors.red,
        child: const FaIcon(FontAwesomeIcons.phoneSlash),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final roomName = groupCall.room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(widget.context)),
    );

    return PIPView(
      builder: (context, isFloating) {
        return Scaffold(
          backgroundColor: Colors.black87,
          resizeToAvoidBottomInset: !isFloating,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: isFloating
              ? null
              : SizedBox(
                  width: 320,
                  height: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _buildControls(),
                  ),
                ),
          body: Stack(
            children: [
              // Participant grid
              Positioned.fill(
                child: _buildParticipantGrid(),
              ),
              // Top bar with room name and PIP button
              if (!isFloating)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.arrowLeft,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            PIPView.of(context)?.setFloating(true);
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                roomName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_streams.length} participant${_streams.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
