import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/features/learn/learn_progress.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_sheet.dart';

import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/widgets/offline_bar.dart';

class AppShell extends StatefulWidget {
  /// The tabs, kept alive by the router; one of them is shown.
  final StatefulNavigationShell shell;

  const AppShell({super.key, required this.shell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// The tab just tapped, shown selected before its page is built: a page
  /// that is slow to build the first time (Puzzles) must not hold the tab
  /// back, so the bar answers the tap at once and the page follows.
  int? _pending;

  static const int _learnTab = 2;
  static const String _gateOffKey = 'beginner_gate_off';

  /// A beginner who hasn't yet learned how the pieces move: Learn is the
  /// only tab until they have (or say they already know).
  bool _beginner = false;

  @override
  void initState() {
    super.initState();
    LearnProgress.instance.load();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      _beginner =
          prefs.getString('chess_level') == 'beginner' &&
          !(prefs.getBool(_gateOffKey) ?? false);
    });
  }

  bool get _gated =>
      _beginner &&
      LearnProgress.instance.firstStepsDone < LearnProgress.firstSteps.length;

  void _select(int index) {
    if (index != _learnTab && _gated) {
      _learnFirst(index);
      return;
    }
    setState(() => _pending = index);
    // After the frame that shows the new tab, so its slow build comes
    // second.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.shell.goBranch(index);
    });
  }

  /// Asks a beginner to finish the piece lessons first, showing how far
  /// they are; they can go on learning, or say they know the moves.
  void _learnFirst(int wanted) {
    final t = context.t;
    final k = context.k;
    final done = LearnProgress.instance.firstStepsDone;
    showKustSheet<void>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KustSheetHeader(title: t.learnFirstTitle, subtitle: t.learnFirstBody),
          Row(
            children: [
              for (var i = 0; i < LearnProgress.firstSteps.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < done ? k.success : k.surfaceAlt,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(t.learnFirstProgress(done), style: k.caption),
          const SizedBox(height: 20),
          KustButton(
            label: t.learnFirstKeep,
            onTap: () {
              Navigator.of(sheet).pop();
              final next = LearnProgress.firstSteps.firstWhere(
                (id) => !LearnProgress.instance.done.value.contains(id),
                orElse: () => LearnProgress.firstSteps.first,
              );
              if (widget.shell.currentIndex != _learnTab) _select(_learnTab);
              context.push('/lesson/$next');
            },
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(sheet).pop();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(_gateOffKey, true);
              _beginner = false;
              if (mounted) _select(wanted);
            },
            child: Text(
              t.learnFirstSkip,
              style: k.body.copyWith(
                color: k.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.shell.currentIndex;
    if (_pending == current) _pending = null;
    final selected = _pending ?? current;

    return Scaffold(
      backgroundColor: context.k.bg,
      // The top bar and the tab bar blur the page through one shared read.
      body: BackdropGroup(
        child: Stack(
          children: [
            Positioned.fill(child: widget.shell),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: KustNavBar(
                selectedIndex: selected,
                items: [
                  KustNavItem(
                    Icons.sports_esports_outlined,
                    Icons.sports_esports_rounded,
                    context.t.navPlay,
                  ),
                  KustNavItem(
                    Icons.extension_outlined,
                    Icons.extension_rounded,
                    context.t.navPuzzles,
                  ),
                  KustNavItem(
                    Icons.school_outlined,
                    Icons.school_rounded,
                    context.t.navLearn,
                  ),
                  KustNavItem.svg('assets/icons/sword.svg', context.t.navTrain),
                ],
                onSelected: _select,
                footer: const OfflineBar(edge: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
