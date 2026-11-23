import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/tokens.dart';

/// A filled text field with no outline, as in the app's sheets.
class KustTextField extends StatelessWidget {
  const KustTextField({
    super.key,
    required this.controller,
    required this.maxLength,
    this.maxLines = 1,
    this.prefix,
    this.helper,
    this.autofocus = false,
    this.capitalization = TextCapitalization.none,
    this.formatters,
    this.onSubmitted,
    this.action,
    this.bare = false,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.onChanged,
    this.errorText,
    this.hint,
    this.icon,
  });

  /// For a username: only what [AppStorage.usernamePattern] allows, in
  /// lowercase as it is typed, after an "@".
  KustTextField.username({
    super.key,
    required this.controller,
    this.helper,
    this.autofocus = false,
    this.onSubmitted,
    this.action,
    this.bare = false,
    this.onChanged,
    this.errorText,
    this.hint,
    this.icon,
  }) : obscure = false,
       keyboardType = TextInputType.visiblePassword,
       autofillHints = const [AutofillHints.username],
       maxLength = 20,
       maxLines = 1,
       // With an icon the "@" is the icon.
       prefix = icon == null ? '@' : null,
       capitalization = TextCapitalization.none,
       formatters = _usernameFormatters;

  static final List<TextInputFormatter> _usernameFormatters = [
    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]')),
    TextInputFormatter.withFunction(
      (_, value) => value.copyWith(text: value.text.toLowerCase()),
    ),
  ];

  final TextEditingController controller;
  final int maxLength;
  final int maxLines;
  final String? prefix;
  final String? helper;
  final bool autofocus;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onSubmitted;

  /// The keyboard's action key, such as next to move to the field below.
  final TextInputAction? action;

  /// Without its filled box, for a field that sits in a list row.
  final bool bare;

  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? hint;

  /// Shown at the start of the field, in the muted colour.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (!obscure) return _field(context, hidden: false);
    // A password: an eye at the end shows or hides what is typed.
    return _Reveal(
      builder: (hidden, toggle) => _field(
        context,
        hidden: hidden,
        suffix: IconButton(
          onPressed: toggle,
          tooltip: hidden ? context.t.showPassword : context.t.hidePassword,
          icon: Icon(
            hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: context.k.muted,
          ),
        ),
      ),
    );
  }

  Widget _field(BuildContext context, {required bool hidden, Widget? suffix}) {
    final k = context.k;
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: 1,
      autofocus: autofocus,
      textCapitalization: capitalization,
      inputFormatters: formatters,
      autocorrect: prefix == null && formatters == null && !obscure,
      enableSuggestions: !obscure,
      obscureText: hidden,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: action,
      style: k.body,
      decoration: bare
          ? InputDecoration(
              isDense: true,
              counterText: '',
              prefixText: prefix,
              prefixStyle: k.body.copyWith(color: k.muted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            )
          : InputDecoration(
              counterText: '',
              prefixText: prefix,
              helperText: helper,
              errorText: errorText,
              hintText: hint,
              hintStyle: k.body.copyWith(color: k.muted),
              prefixIcon: icon == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 14, right: 8),
                      child: Icon(icon, size: 20, color: k.muted),
                    ),
              suffixIcon: suffix,
              filled: true,
              fillColor: k.surfaceAlt,
              // Slim, with modest corners.
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              // The icon brings its own padding: 14 before, 8 after.
              prefixIconConstraints: const BoxConstraints(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
    );
  }
}

/// Keeps whether a password is hidden; hidden at first.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.builder});

  final Widget Function(bool hidden, VoidCallback toggle) builder;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_hidden, () => setState(() => _hidden = !_hidden));
}
