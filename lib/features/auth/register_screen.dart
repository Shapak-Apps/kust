import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/auth/auth_support.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_button_3d.dart';
import 'package:kust/ui/kust_text_field.dart';

enum _UsernameCheck { idle, checking, free, taken, reserved }

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.next});

  /// Where to go once the email is verified; see [goAfterAuth].
  final String? next;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  Timer? _debounce;
  _UsernameCheck _check = _UsernameCheck.idle;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final saved = AppStorage.instance.username;
    if (saved != null) {
      _username.text = saved;
      _scheduleCheck(saved);
    }
    for (final c in [_email, _password, _confirm]) {
      c.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _debounce?.cancel();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _scheduleCheck(String value) {
    _debounce?.cancel();
    if (!AppStorage.usernamePattern.hasMatch(value)) {
      setState(() => _check = _UsernameCheck.idle);
      return;
    }
    setState(() => _check = _UsernameCheck.checking);
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final problem = await AuthService.instance.usernameProblem(value);
        if (!mounted || _username.text != value) return;
        setState(() {
          _check = switch (problem) {
            null => _UsernameCheck.free,
            'reserved' => _UsernameCheck.reserved,
            _ => _UsernameCheck.taken,
          };
        });
      } on ApiException {
        if (mounted && _username.text == value) {
          setState(() => _check = _UsernameCheck.idle);
        }
      }
    });
  }

  String get _emailText => _email.text.trim();
  bool get _emailOk => _emailPattern.hasMatch(_emailText);
  bool get _passwordOk =>
      passwordRules(_password.text, _username.text, _emailText).every((r) => r);
  bool get _confirmOk => _confirm.text == _password.text;
  bool get _usernameOk =>
      AppStorage.usernamePattern.hasMatch(_username.text) &&
      _check != _UsernameCheck.taken &&
      _check != _UsernameCheck.reserved;

  /// Sign-up comes in two steps, so it never asks for four things at once:
  /// email and username, then the password.
  int _stage = 0;

  bool get _firstOk =>
      _emailOk && _usernameOk && _check != _UsernameCheck.checking;

  bool get _valid =>
      _emailOk &&
      _usernameOk &&
      _passwordOk &&
      _confirm.text.isNotEmpty &&
      _confirmOk;

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    final t = context.t;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = AuthService.instance;
      await auth.register(
        email: _emailText,
        username: _username.text.trim(),
        password: _password.text,
      );
      await pushLocalProfile(auth);
      if (!mounted) return;
      context.pushReplacement(withNext('/verify', widget.next), extra: 60);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = authErrorMessage(t, e);
        // A problem with the email or username belongs to the first step.
        if (const {
          'email_taken',
          'username_taken',
          'invalid_email',
          'invalid_username',
          'reserved_username',
        }.contains(e.code)) {
          _stage = 0;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final usernameError = switch (_check) {
      _UsernameCheck.taken => t.usernameTaken,
      _UsernameCheck.reserved => t.usernameReserved,
      _ => null,
    };
    final next = widget.next;
    final first = _stage == 0;
    final rules = passwordRules(_password.text, _username.text, _emailText);
    return PopScope(
      canPop: first,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _stage = 0);
      },
      child: AuthPage(
        step: _stage + 1,
        title: first ? t.authCreateTitle : t.authPasswordTitle,
        subtitle: first ? t.authCreateSub : t.authPasswordSub,
        onBack: first ? null : () => setState(() => _stage = 0),
        onSkip: next == null ? null : () => context.go(next),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KustButton3D(
              expand: true,
              label: first ? t.cont : t.createAccount,
              onTap: _busy
                  ? null
                  : first
                  ? (_firstOk
                        ? () => setState(() {
                            _stage = 1;
                            _error = null;
                          })
                        : null)
                  : (_valid ? _submit : null),
            ),
            AuthSwitch(
              prompt: t.authHaveAccount,
              action: t.signIn,
              onTap: _busy
                  ? null
                  : () => context.pushReplacement(withNext('/login', next)),
            ),
          ],
        ),
        children: first
            ? [
                KustTextField(
                  key: const ValueKey('email'),
                  controller: _email,
                  maxLength: 254,
                  autofocus: true,
                  icon: Icons.mail_outline_rounded,
                  hint: t.emailLabel,
                  action: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  errorText: _email.text.isNotEmpty && !_emailOk
                      ? t.invalidEmail
                      : null,
                ),
                fieldGap,
                KustTextField.username(
                  key: const ValueKey('username'),
                  controller: _username,
                  icon: Icons.alternate_email_rounded,
                  hint: t.username,
                  action: TextInputAction.done,
                  onChanged: _scheduleCheck,
                  onSubmitted: (_) {
                    if (_firstOk) setState(() => _stage = 1);
                  },
                  errorText: usernameError,
                  helper: _check == _UsernameCheck.free
                      ? t.usernameFree
                      : t.usernameRule,
                ),
                ErrorLine(_error),
              ]
            : [
                KustTextField(
                  key: const ValueKey('password'),
                  controller: _password,
                  maxLength: 128,
                  obscure: true,
                  autofocus: true,
                  icon: Icons.lock_outline_rounded,
                  hint: t.passwordLabel,
                  action: TextInputAction.next,
                  keyboardType: TextInputType.visiblePassword,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 10),
                PasswordChecklist(rules: rules),
                fieldGap,
                KustTextField(
                  key: const ValueKey('confirm'),
                  controller: _confirm,
                  maxLength: 128,
                  obscure: true,
                  icon: Icons.lock_outline_rounded,
                  hint: t.confirmPassword,
                  action: TextInputAction.done,
                  keyboardType: TextInputType.visiblePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submit(),
                  errorText: _confirm.text.isNotEmpty && !_confirmOk
                      ? t.passwordsDiffer
                      : null,
                ),
                ErrorLine(_error),
              ],
      ),
    );
  }
}
