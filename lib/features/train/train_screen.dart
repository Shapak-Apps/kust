import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/tokens.dart';

/// The Train tab. Its mode is still to come.
class TrainScreen extends StatelessWidget {
  const TrainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ColoredBox(
      color: k.bg,
      child: Column(
        children: [
          FeltHeader(title: context.t.navTrain),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                32,
                0,
                32,
                KustNavBar.clearance(context),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/sword.svg',
                      width: 40,
                      height: 40,
                      colorFilter: ColorFilter.mode(k.muted, BlendMode.srcIn),
                    ),
                    const SizedBox(height: 12),
                    Text(context.t.levelComingSoon, style: k.title),
                    const SizedBox(height: 8),
                    Text(
                      context.t.trainSoonSub,
                      textAlign: TextAlign.center,
                      style: k.body.copyWith(color: k.muted),
                    ),
                    const SizedBox(height: 24),
                    KustButton(
                      label: context.t.solvePuzzles,
                      expand: false,
                      onTap: () => context.go('/puzzles'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
