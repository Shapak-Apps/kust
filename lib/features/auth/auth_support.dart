import 'package:flutter/material.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/offline_bar.dart';

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
      return t.passwordShort;
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

class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });

  final String title;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.k.bg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          FeltHeader(
            title: title,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: children,
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: footer,
            ),
          const SafeArea(top: false, child: OfflineBar()),
        ],
      ),
    );
  }
}

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
