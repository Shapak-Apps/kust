import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';

/// [path] with the screen to open after signing in, when there is one.
String withNext(String path, String? next) =>
    next == null ? path : '$path?next=${Uri.encodeComponent(next)}';

/// After signing in: [next] when the flow started somewhere (the welcome
/// screen), else the players list.
void goAfterAuth(BuildContext context, String? next) {
  if (next != null) {
    context.go(next);
  } else {
    context.pushReplacement('/players');
  }
}

String authErrorMessage(AppL10n t, ApiException e) {
  switch (e.code) {
    case ApiException.networkCode:
      return t.noInternet;
    case 'invalid_credentials':
      return t.invalidCredentials;
    case 'email_taken':
      return t.emailTaken;
    case 'username_taken':
      return t.usernameTaken;
    case 'reserved_username':
      return t.usernameReserved;
    case 'invalid_email':
      return t.invalidEmail;
    case 'invalid_password':
      return t.passwordWeak;
    case 'rate_limited':
    case 'resend_wait':
      return t.rateLimited;
    case 'wrong_code':
      return t.codeWrong;
    case 'code_expired':
    case 'no_code':
      return t.codeExpired;
    case 'too_many_attempts':
      return t.codeTooMany;
    default:
      return t.genericError;
  }
}

Future<void> pullServerProfile(Account account) async {
  final store = AppStorage.instance;
  await store.saveProfile(
    name: account.displayName,
    username: account.username,
    bio: account.bio,
  );
  await store.setCountry(account.country);
}

Future<void> pushLocalProfile(AuthService auth) async {
  final store = AppStorage.instance;
  final name = store.displayName(AppText.now);
  final custom = name != AppText.now.defaultPlayerName;
  try {
    await auth.updateProfile(
      displayName: custom ? name : null,
      bio: store.bio.isEmpty ? null : store.bio,
      country: store.country,
    );
  } on ApiException {
    return;
  }
}

/// A sign-in screen, kept bare: back (and skip, during onboarding), a big
/// title with a line under it, the fields, then the button and a link to
/// the other screen at the bottom. Never says it is offline: the app only
/// watches the connection once someone is signed in.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
    this.onSkip,
    this.onBack,
    this.step,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;

  /// Shown as "Skip for now" at the top right when set.
  final VoidCallback? onSkip;

  /// Back within the screen (sign-up's second step); else the screen closes.
  final VoidCallback? onBack;

  /// For sign-up: "Step 1 of 2" over the title.
  final int? step;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Scaffold(
      backgroundColor: k.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
              child: Row(
                children: [
                  KustIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: context.t.back,
                    onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  if (onSkip != null)
                    TextButton(
                      onPressed: onSkip,
                      child: Text(
                        context.t.onbSkip,
                        style: k.body.copyWith(
                          color: k.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                children: [
                  if (step != null) ...[
                    StepLabel(step: step!, total: 2),
                    const SizedBox(height: 6),
                  ],
                  Text(title, style: k.display),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(subtitle!, style: k.body.copyWith(color: k.muted)),
                  ],
                  const SizedBox(height: 28),
                  ...children,
                ],
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// "Don't have an account? Create account": a quiet line under the main
/// button that leads to the other screen.
class AuthSwitch extends StatelessWidget {
  const AuthSwitch({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text.rich(
            TextSpan(
              text: '$prompt ',
              style: k.body.copyWith(color: k.muted),
              children: [
                TextSpan(
                  text: action,
                  style: k.body.copyWith(
                    color: KustTokens.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// The space between two fields.
const Widget fieldGap = SizedBox(height: 14);

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(text, style: k.caption.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class ErrorLine extends StatelessWidget {
  const ErrorLine(this.text, {super.key});

  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox(height: 16);
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Text(text!, style: k.body.copyWith(color: k.danger)),
    );
  }
}

/// Whether [password] meets each rule the server checks, in the order the
/// checklist shows them: length, capital, small letter, digit, and not
/// built on the username or the email's name.
List<bool> passwordRules(String password, String username, String email) {
  final low = password.toLowerCase();
  final at = email.lastIndexOf('@');
  final name = at > 0 ? email.substring(0, at) : email;
  bool holds(String part) =>
      part.length >= 3 && low.contains(part.toLowerCase());
  return [
    password.runes.length >= 8,
    password.toLowerCase() != password,
    password.toUpperCase() != password,
    RegExp(r'\d').hasMatch(password),
    password.isNotEmpty && !holds(username) && !holds(name),
  ];
}

/// The password rules under the field, each ticked green once met.
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.rules});

  final List<bool> rules;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final labels = [
      t.pwRuleLength,
      t.pwRuleUpper,
      t.pwRuleLower,
      t.pwRuleDigit,
      t.pwRuleNoName,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      rules[i]
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(rules[i]),
                      size: 16,
                      color: rules[i] ? k.success : k.muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    labels[i],
                    style: k.caption.copyWith(
                      color: rules[i] ? k.ink : k.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Step 1 of 2" with the numbers big, the current one in gold, so the
/// eye finds where it is at once. Works in any language: the sentence is
/// built with markers in place of the numbers, then cut around them.
class StepLabel extends StatelessWidget {
  const StepLabel({super.key, required this.step, required this.total});

  final int step;
  final int total;

  static const int _stepMark = 900001;
  static const int _totalMark = 900002;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final words = k.caption.copyWith(fontSize: 14, fontWeight: FontWeight.w700);
    final number = words.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w900,
      color: k.ink,
    );
    final sentence = context.t.onbStepOf(_stepMark, _totalMark);
    final spans = <InlineSpan>[];
    sentence.splitMapJoin(
      RegExp('$_stepMark|$_totalMark'),
      onMatch: (m) {
        final isStep = m[0] == '$_stepMark';
        spans.add(
          TextSpan(
            text: '${isStep ? step : total}',
            style: isStep ? number.copyWith(color: KustTokens.gold) : number,
          ),
        );
        return '';
      },
      onNonMatch: (text) {
        if (text.isNotEmpty) spans.add(TextSpan(text: text, style: words));
        return '';
      },
    );
    return Semantics(
      label: context.t.onbStepOf(step, total),
      excludeSemantics: true,
      child: Text.rich(TextSpan(children: spans)),
    );
  }
}
