import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kust/ui/tokens.dart';

/// A one-time code as a row of boxes, one digit each, as Instagram asks for
/// it. A plain field lies under the boxes and does the typing, so pasting,
/// deleting and the keyboard's code suggestion all just work; the boxes
/// only draw what it holds, with the next one to fill ringed in gold.
class CodeBoxes extends StatefulWidget {
  const CodeBoxes({
    super.key,
    required this.controller,
    this.length = 6,
    this.autofocus = true,
    this.error = false,
  });

  final TextEditingController controller;
  final int length;
  final bool autofocus;

  /// Rings every box in red, after a wrong code.
  final bool error;

  @override
  State<CodeBoxes> createState() => _CodeBoxesState();
}

class _CodeBoxesState extends State<CodeBoxes> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final text = widget.controller.text;
    return SizedBox(
      height: 58,
      child: Stack(
        children: [
          // The field that takes the input, invisible, covering the boxes so
          // a tap anywhere on them opens the keyboard.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                maxLength: widget.length,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                showCursor: false,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Row(
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _box(k, text, i)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(KustTokens k, String text, int i) {
    final filled = i < text.length;
    final current =
        _focus.hasFocus &&
        (i == text.length || (i == widget.length - 1 && filled));
    final Color border = widget.error
        ? k.danger
        : current
        ? KustTokens.gold
        : filled
        ? k.muted.withValues(alpha: 0.5)
        : Colors.transparent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: k.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 2),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        transitionBuilder: (child, a) =>
            ScaleTransition(scale: a, child: child),
        child: Text(
          filled ? text[i] : '',
          key: ValueKey('$i${filled ? text[i] : ''}'),
          style: k.title.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
