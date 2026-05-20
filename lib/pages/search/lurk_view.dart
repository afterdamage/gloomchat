import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:afterdamage/widgets/avatar.dart';

class _LurkProject {
  final String name;
  final String url;

  const _LurkProject(this.name, this.url);
}

class LurkView extends StatelessWidget {
  const LurkView({super.key});

  static const _projects = [
    _LurkProject('PeerTube', 'https://joinpeertube.org'),
    _LurkProject('Funkwhale', 'https://funkwhale.audio'),
    _LurkProject('WireGuard', 'https://www.wireguard.com'),
    _LurkProject('CryptPad', 'https://cryptpad.org'),
    _LurkProject('Organic Maps', 'https://organicmaps.app'),
    _LurkProject('NextGraph', 'https://nextgraph.org'),
    _LurkProject('Tails OS', 'https://tails.boum.org'),
    _LurkProject('Whonix', 'https://www.whonix.org'),
    _LurkProject('Termux', 'https://termux.dev'),
    _LurkProject('SimpleX Chat', 'https://simplex.chat'),
  ];

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    } catch (e, s) {
      Logs().w('LurkView: failed to launch $url', e, s);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _projects.length,
        itemBuilder: (context, i) {
          final project = _projects[i];
          return InkWell(
            onTap: () => _openUrl(context, project.url),
            child: SizedBox(
              width: 84,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Avatar(mxContent: null, name: project.name),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      project.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
