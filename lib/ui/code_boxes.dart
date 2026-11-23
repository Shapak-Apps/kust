import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kust/ui/tokens.dart';

/// Where a code stands: being typed, accepted, or refused.
enum CodeStatus { typing, correct, wrong }

/// A one-time code as a row of boxes, one digit each, as Instagram asks for
/// it. A plain field lies under the boxes and does the typing, so pasting,
/// deleting and the keyboard's code suggestion all just work; the boxes
/// only draw what it holds, with the next one to fill ringed in gold.
///
/// When the code is judged the boxes answer as Telegram's do: a wave of
/// green from the first box to the last when it is right; a wave of red, a
/// shake and a buzz when it is wrong.
class CodeBoxes extends StatefulWidget {
  const CodeBoxes({
    super.key,
    required this.controller,
    this.length = 6,
    this.autofocus = true,
    this.status = CodeStatus.typing,
  });

  final TextEditingController controller;
  final int length;
  final bool autofocus;
  final CodeStatus status;

  /// How long the wave takes to reach the last box; wait this long before
  /// moving on, so it is seen.
  static const Duration wave = Duration(milliseconds: 650);

  @override
  State<CodeBoxes> createState() => _CodeBoxesState();
}

class _CodeBoxesState extends State<CodeBoxes>
    with SingleTickerProviderStateMixin {
  final _focus = FocusNode();
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: CodeBoxes.wave,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
    _wave.addListener(_changed);
  }

  @override
  void didUpdateWidget(CodeBoxes old) {
    super.didUpdateWidget(old);
    if (widget.status == old.status) return;
    switch (widget.status) {
      case CodeStatus.correct:
        HapticFeedback.lightImpact();
        _wave.forward(from: 0);
      case CodeStatus.wrong:
        HapticFeedback.heavyImpact();
        _wave.forward(from: 0);
      case CodeStatus.typing:
        _wave.value = 0;
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    _wave.dispose();
    super.dispose();
  }

  /// How far the wave has reached box [i], from 0 to 1: each box turns in
  /// its own slice of the wave, one after another.
  double _reach(int i) {
    final slice = 1 / (widget.length + 2);
    return ((_wave.value - i * slice) / (slice * 3)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final text = widget.controller.text;
    // A short shake, fading out, while a wrong code turns red.
    final shake = widget.status == CodeStatus.wrong
        ? math.sin(_wave.value * math.pi * 6) * 8 * (1 - _wave.value)
        : 0.0;
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
                readOnly: widget.status != CodeStatus.typing,
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
            child: Transform.translate(
              offset: Offset(shake, 0),
              child: Row(
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _box(k, text, i)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(KustTokens k, String text, int i) {
    final filled = i < text.length;
    final current =
        widget.status == CodeStatus.typing &&
        _focus.hasFocus &&
        (i == text.length || (i == widget.length - 1 && filled));
    final Color resting = current
        ? KustTokens.gold
        : filled
        ? k.muted.withValues(alpha: 0.5)
        : Colors.transparent;
    final verdict = switch (widget.status) {
      CodeStatus.correct => k.success,
      CodeStatus.wrong => k.danger,
      CodeStatus.typing => null,
    };
    final reach = verdict == null ? 0.0 : _reach(i);
    final border = verdict == null
        ? resting
        : Color.lerp(resting, verdict, reach)!;
    // Each box lifts a little as the wave passes it.
    final lift = math.sin(reach * math.pi) * 4;
    return Transform.translate(
      offset: Offset(0, -lift),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: verdict == null
              ? k.surfaceAlt
              : Color.lerp(
                  k.surfaceAlt,
                  verdict.withValues(alpha: 0.18),
                  reach,
                ),
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
      ),
    );
  }
}
