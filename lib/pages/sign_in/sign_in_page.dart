import 'package:afterdamage/config/themes.dart';
import 'package:afterdamage/l10n/l10n.dart';
import 'package:afterdamage/pages/sign_in/view_model/model/public_homeserver_data.dart';
import 'package:afterdamage/pages/sign_in/view_model/sign_in_view_model.dart';
import 'package:afterdamage/utils/localized_exception_extension.dart';
import 'package:afterdamage/utils/sign_in_flows/check_homeserver.dart';
import 'package:afterdamage/widgets/layouts/login_scaffold.dart';
import 'package:afterdamage/widgets/matrix.dart';
import 'package:afterdamage/widgets/view_model_builder.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

// ── Dracula palette ───────────────────────────────────────────────────────────
const _kBg      = Color(0xFF282a36);
const _kSurface = Color(0xFF44475a);
const _kFg      = Color(0xFFf8f8f2);
const _kMuted   = Color(0xFF6272a4);
const _kRed     = Color(0xFFff5555);
const _kCyan    = Color(0xFF8be9fd);

class SignInPage extends StatelessWidget {
  final bool signUp;
  const SignInPage({required this.signUp, super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      create: () => SignInViewModel(Matrix.of(context), signUp: signUp),
      builder: (context, viewModel, _) {
        final state = viewModel.value;
        final publicHomeservers = state.filteredPublicHomeservers;
        final selectedHomeserver = state.selectedHomeserver;
        final isConnecting =
            state.loginLoading.connectionState == ConnectionState.waiting;

        return LoginScaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xCC1e2029),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: isConnecting
                ? CloseButton(
                    color: _kMuted,
                    onPressed: () =>
                        viewModel.setLoginLoading(AsyncSnapshot.nothing()),
                  )
                : BackButton(
                    color: _kMuted,
                    onPressed: Navigator.of(context).pop,
                  ),
            title: _GloomChatLogo(),
            centerTitle: false,
          ),
          body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Section label
                  Text(
                    signUp ? '// CHOOSE YOUR FORTRESS' : '// RETURN TO BASE',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'FreeMono',
                      fontSize: 10,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    signUp
                        ? L10n.of(context).signUpGreeting
                        : L10n.of(context).signInGreeting,
                    style: const TextStyle(
                      color: _kMuted,
                      fontFamily: 'FreeMono',
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search field
                  TextField(
                    readOnly: state.publicHomeservers.connectionState ==
                            ConnectionState.waiting ||
                        isConnecting,
                    controller: viewModel.filterTextController,
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(
                      color: _kFg,
                      fontFamily: 'FreeMono',
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _kSurface.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: _kMuted.withOpacity(0.4)),
                        borderRadius: BorderRadius.zero,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _kMuted.withOpacity(0.3)),
                        borderRadius: BorderRadius.zero,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                      errorText: state.publicHomeservers.error
                          ?.toLocalizedString(context),
                      prefixIcon:
                          const Icon(Icons.search_outlined, color: _kMuted),
                      hintText: L10n.of(context).searchOrEnterHomeserverAddress,
                      hintStyle: const TextStyle(
                        color: _kMuted,
                        fontFamily: 'FreeMono',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Server list
                  if (state.publicHomeservers.connectionState ==
                      ConnectionState.done)
                    Expanded(
                      child: RadioGroup<PublicHomeserverData>(
                        groupValue: state.selectedHomeserver,
                        onChanged: viewModel.selectHomeserver,
                        child: ListView.separated(
                          itemCount: publicHomeservers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final server = publicHomeservers[i];
                            final isSelected = server == selectedHomeserver;
                            return _ServerCard(
                              server: server,
                              isSelected: isSelected,
                              isEnabled: !isConnecting && server.available != false,
                              signUp: signUp,
                            );
                          },
                        ),
                      ),
                    )
                  else
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          bottomNavigationBar: AnimatedSize(
            duration: GloomThemes.animationDuration,
            curve: GloomThemes.animationCurve,
            child: selectedHomeserver == null ||
                    !publicHomeservers.contains(selectedHomeserver)
                ? const SizedBox.shrink()
                : Container(
                    color: _kBg,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SafeArea(
                        child: _GlowButton(
                          label: isConnecting
                              ? null
                              : L10n.of(context).continueText.toUpperCase(),
                          onPressed: isConnecting
                              ? null
                              : () => connectToHomeserverFlow(
                                    selectedHomeserver,
                                    context,
                                    viewModel.setLoginLoading,
                                    signUp,
                                  ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────
class _GloomChatLogo extends StatelessWidget {
  const _GloomChatLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'Gloom',
          style: TextStyle(
            color: _kFg,
            fontFamily: 'FreeMono',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        Text(
          'Chat',
          style: TextStyle(
            color: _kRed,
            fontFamily: 'FreeMono',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ── Server card (dispatch-entry style) ───────────────────────────────────────
class _ServerCard extends StatelessWidget {
  final PublicHomeserverData server;
  final bool isSelected;
  final bool isEnabled;
  final bool signUp;

  const _ServerCard({
    required this.server,
    required this.isSelected,
    required this.isEnabled,
    required this.signUp,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final website = server.website;
    final borderColor =
        isSelected ? accent.withOpacity(0.7) : _kSurface.withOpacity(0.6);

    return RadioListTile<PublicHomeserverData>(
      value: server,
      enabled: isEnabled,
      dense: false,
      tileColor: isSelected
          ? accent.withOpacity(0.07)
          : _kSurface.withOpacity(0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: borderColor),
      ),
      activeColor: accent,
      title: Row(
        children: [
          Expanded(
            child: Text(
              server.name ?? 'Unknown',
              style: TextStyle(
                color: isSelected ? accent : _kFg,
                fontFamily: 'FreeMono',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (website != null)
            SizedBox.square(
              dimension: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.open_in_new_outlined, size: 14, color: _kMuted),
                onPressed: () => launchUrlString(website),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          if ((server.features?.isNotEmpty == true) ||
              (server.languages?.isNotEmpty == true))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  ...?server.languages?.map(
                    (lang) => _Tag(label: lang, color: _kCyan),
                  ),
                  ...?server.features?.map(
                    (feat) => _Tag(label: feat, color: accent),
                  ),
                ],
              ),
            ),
          Text(
            server.description ?? 'A Matrix homeserver.',
            style: const TextStyle(
              color: _kMuted,
              fontFamily: 'FreeMono',
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature tag ───────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.4)),
        color: color.withOpacity(0.08),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontFamily: 'FreeMono',
          fontSize: 8,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ── Red glow continue button ──────────────────────────────────────────────────
class _GlowButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;

  const _GlowButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: _kRed.withOpacity(0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kRed,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _kSurface,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            elevation: 0,
            textStyle: const TextStyle(
              fontFamily: 'FreeMono',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          child: label != null
              ? Text(label!)
              : const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
        ),
      ),
    );
  }
}
