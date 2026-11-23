import 'package:flutter/material.dart';

import 'package:kust/core/countries.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// The flag of country [code], [height] tall, with softly rounded corners.
class CountryFlag extends StatelessWidget {
  const CountryFlag(this.code, {super.key, this.height = 16});

  final String code;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: kCountries[code],
    image: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(height * 0.12),
      child: Image.asset(
        flagAsset(code),
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => SizedBox(height: height),
      ),
    ),
  );
}

/// Lets the player pick a country, with a search; returns its code, an
/// empty string for none, or null when the sheet is closed.
Future<String?> pickCountry(BuildContext context, {String? current}) =>
    showKustSheet<String>(
      context,
      builder: (_) => _CountryPicker(current: current),
    );

class _CountryPicker extends StatefulWidget {
  const _CountryPicker({this.current});

  final String? current;

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final e in kCountries.entries)
        if (q.isEmpty ||
            e.value.toLowerCase().contains(q) ||
            e.key.toLowerCase() == q)
          e,
    ];
    Widget row({
      required Widget leading,
      required String title,
      required String value,
    }) => Pressable(
      onTap: () => Navigator.of(context).pop(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 36, child: Center(child: leading)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: k.body.copyWith(
                  fontWeight: value == (widget.current ?? '')
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
            ),
            if (value == (widget.current ?? ''))
              Icon(Icons.check_rounded, color: k.accent, size: 20),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KustSheetHeader(title: t.country),
        TextField(
          autofocus: false,
          onChanged: (v) => setState(() => _query = v),
          style: k.body,
          decoration: InputDecoration(
            hintText: t.searchCountries,
            prefixIcon: Icon(Icons.search_rounded, color: k.muted),
            filled: true,
            fillColor: k.surfaceAlt,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(KustSpace.rMedium),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: ListView(
            children: [
              if (q.isEmpty)
                row(
                  leading: Icon(Icons.public_off_rounded, color: k.muted),
                  title: t.countryNone,
                  value: '',
                ),
              for (final e in shown)
                row(
                  leading: CountryFlag(e.key, height: 26),
                  title: e.value,
                  value: e.key,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
