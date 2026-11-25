import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/auth/auth_support.dart';
import 'package:kust/features/onboarding/onboarding_level.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_button_3d.dart';
import 'package:kust/ui/kust_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.next});

  /// Where to go once signed in; see [goAfterAuth].
  final String? next;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _identifier.addListener(_changed);
    _password.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _valid =>
      _identifier.text.trim().isNotEmpty && _password.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    final t = context.t;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final account = await AuthService.instance.login(
        identifier: _identifier.text.trim(),
        password: _password.text,
      );
      await pullServerProfile(account);
      if (!mounted) return;
      if (account.emailVerified) {
        // An existing account has its name, username and rating already:
        // no onboarding, straight home.
        var next = widget.next;
        if (next != null && next.startsWith('/onboarding')) {
          await completeOnboarding(
            prefs: await SharedPreferences.getInstance(),
            ratingStore: PlayerRatingStore.instance,
          );
          next = null;
        }
        if (!mounted) return;
        goAfterAuth(context, next);
      } else {
        context.pushReplacement(withNext('/verify', widget.next));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(t, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final next = widget.next;
    return AuthPage(
      title: t.authWelcomeBack,
      subtitle: t.authSignInSub,
      onSkip: next == null ? null : () => context.go(next),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KustButton3D(
            expand: true,
            label: t.signIn,
            onTap: _valid && !_busy ? _submit : null,
          ),
          AuthSwitch(
            prompt: t.authNoAccount,
            action: t.createAccount,
            onTap: _busy
                ? null
                : () => context.pushReplacement(withNext('/register', next)),
          ),
        ],
      ),
      children: [
        KustTextField(
          controller: _identifier,
          maxLength: 254,
          autofocus: true,
          icon: Icons.person_outline_rounded,
          hint: t.emailOrUsername,
          action: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
        ),
        fieldGap,
        KustTextField(
          controller: _password,
          maxLength: 128,
          obscure: true,
          icon: Icons.lock_outline_rounded,
          hint: t.passwordLabel,
          action: TextInputAction.done,
          keyboardType: TextInputType.visiblePassword,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
        ),
        ErrorLine(_error),
      ],
    );
  }
}
