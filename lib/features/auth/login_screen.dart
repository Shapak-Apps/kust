import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/features/auth/auth_support.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
      context.pushReplacement(account.emailVerified ? '/players' : '/verify');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(t, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AuthPage(
      title: t.signIn,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KustButton(
            label: t.signIn,
            onTap: _valid && !_busy ? _submit : null,
          ),
          const SizedBox(height: 8),
          KustButton(
            label: t.createAccount,
            style: KustButtonStyle.secondary,
            onTap: _busy ? null : () => context.pushReplacement('/register'),
          ),
        ],
      ),
      children: [
        FieldLabel(t.emailOrUsername),
        KustTextField(
          controller: _identifier,
          maxLength: 254,
          autofocus: true,
          action: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
        ),
        FieldLabel(t.passwordLabel),
        KustTextField(
          controller: _password,
          maxLength: 128,
          obscure: true,
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
