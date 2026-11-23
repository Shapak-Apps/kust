import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/features/auth/auth_support.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_text_field.dart';
import 'package:kust/ui/tokens.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.initialCooldown = 0});

  final int initialCooldown;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _code = TextEditingController();
  Timer? _ticker;
  int _cooldown = 0;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _code.addListener(_onCode);
    _startCooldown(widget.initialCooldown);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _onCode() {
    setState(() {});
    if (_code.text.length == 6) _verify();
  }

  void _startCooldown(int seconds) {
    _ticker?.cancel();
    setState(() => _cooldown = seconds);
    if (seconds <= 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldown = _cooldown - 1);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    if (_code.text.length != 6 || _busy) return;
    final t = context.t;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await AuthService.instance.verifyEmail(_code.text);
      if (!mounted) return;
      context.pushReplacement('/players');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(t, e));
      if (e.code == 'wrong_code') _code.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _busy) return;
    final t = context.t;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final wait = await AuthService.instance.resendCode();
      if (!mounted) return;
      _code.clear();
      setState(() => _notice = t.codeSent);
      _startCooldown(wait);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(t, e));
      if (e.retryAfter != null) _startCooldown(e.retryAfter!);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.logout();
    await PlayersRepository.instance.clearCache();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = context.k;
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthService.instance.state,
      builder: (context, auth, _) {
        final email = auth.account?.email ?? '';
        return AuthPage(
          title: t.verifyTitle,
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KustButton(
                label: t.verifyButton,
                onTap: _code.text.length == 6 && !_busy ? _verify : null,
              ),
              const SizedBox(height: 8),
              KustButton(
                label: _cooldown > 0 ? t.resendIn(_cooldown) : t.resendCode,
                style: KustButtonStyle.secondary,
                onTap: _cooldown > 0 || _busy ? null : _resend,
              ),
              TextButton(
                onPressed: _busy ? null : _signOut,
                child: Text(t.signOut, style: TextStyle(color: k.muted)),
              ),
            ],
          ),
          children: [
            Text(t.verifySubtitle(email), style: k.body),
            FieldLabel(t.verifyCode),
            KustTextField(
              controller: _code,
              maxLength: 6,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              formatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            if (_notice != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                child: Text(_notice!, style: k.body.copyWith(color: k.success)),
              ),
            ErrorLine(_error),
          ],
        );
      },
    );
  }
}
