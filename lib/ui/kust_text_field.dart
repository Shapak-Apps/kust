import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kust/core/storage/app_storage.dart';
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
  }) : maxLength = 20,
       maxLines = 1,
       prefix = '@',
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

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: 1,
      autofocus: autofocus,
      textCapitalization: capitalization,
      inputFormatters: formatters,
      autocorrect: prefix == null,
      onSubmitted: onSubmitted,
      textInputAction: action,
      style: k.body,
      decoration: InputDecoration(
        counterText: '',
        prefixText: prefix,
        helperText: helper,
        filled: true,
        fillColor: k.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KustSpace.rMedium),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
