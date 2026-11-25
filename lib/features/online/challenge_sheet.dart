import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/online_repository.dart';
import 'package:kust/features/game/time_control.dart';
import 'package:kust/features/play/bot_time_row.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/country_flag.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/tokens.dart';

/// Challenging a friend: the same sheet as choosing a bot game, with the
/// same "Play as" cards and time row, so every game is set up alike. The
/// clock always runs online.
Future<void> showChallengeSheet(BuildContext context, Player friend) {
  return showKustSheet<void>(
    context,
    builder: (_) => _ChallengeSheet(friend: friend, host: context),
  );
}

class _ChallengeSheet extends StatefulWidget {
  const _ChallengeSheet({required this.friend, required this.host});

  final Player friend;

  /// The screen under the sheet, to open the game from.
  final BuildContext host;

  @override
  State<_ChallengeSheet> createState() => _ChallengeSheetState();
}

class _ChallengeSheetState extends State<_ChallengeSheet> {
  Side? _side; // null = random
  TimeControl? _time = kTimeControls[1];
  bool _busy = false;
  String? _error;

  Future<void> _send() async {
    final time = _time;
    if (time == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final game = await OnlineRepository.instance.challenge(
        widget.friend.username,
        baseMinutes: time.baseMinutes,
        incrementSeconds: time.incrementSeconds,
        side: switch (_side) {
          Side.white => 'white',
          Side.black => 'black',
          null => 'random',
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      if (widget.host.mounted) widget.host.push('/online/${game.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.code == 'not_friends'
            ? context.t.onlineFriendsOnly
            : e.isNetwork
            ? context.t.noInternet
            : context.t.genericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final f = widget.friend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            PlayerAvatar(
              size: 56,
              name: f.displayName,
              photo: avatarImage(avatarUrlFor(f.avatarKey)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.challengeTitle(f.displayName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: k.title,
                        ),
                      ),
                      if (f.country != null) ...[
                        const SizedBox(width: 8),
                        CountryFlag(f.country!, height: 16),
                      ],
                    ],
                  ),
                  Text(t.eloValue(f.rating), style: k.caption),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SidePicker(
          side: _side,
          opponent: f.displayName,
          onChanged: (v) => setState(() => _side = v),
        ),
        const SizedBox(height: 16),
        TimeControlRow(
          value: _time,
          allowNoClock: false,
          onChanged: (v) => setState(() => _time = v),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: k.body.copyWith(color: k.danger)),
          ),
        const SizedBox(height: 16),
        KustButton(
          label: t.challengeSend,
          icon: Icons.sports_esports_rounded,
          style: KustButtonStyle.gold,
          onTap: _time == null || _busy ? null : _send,
        ),
      ],
    );
  }
}
