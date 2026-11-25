import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/game/chess/chess_helpers.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/country_flag.dart';
import 'package:kust/ui/game_player_bar.dart';
import 'package:kust/ui/player_avatar.dart';

/// Watching a finished game: the board with a player bar over and under
/// it, as in a game — photo, name, rating, flag and what each side has
/// taken by the move on screen.
class ReplayWithPlayers extends StatefulWidget {
  const ReplayWithPlayers({
    super.key,
    required this.game,
    required this.position,
    required this.whiteAtBottom,
    required this.board,
    this.owner,
  });

  final GameRecord game;
  final Position position;
  final bool whiteAtBottom;
  final Widget board;

  /// Whose game it is, when it is someone else's; null for mine.
  final String? owner;

  @override
  State<ReplayWithPlayers> createState() => _ReplayWithPlayersState();
}

class _ReplayWithPlayersState extends State<ReplayWithPlayers> {
  Player? _owner;
  Player? _opponent;

  @override
  void initState() {
    super.initState();
    final owner = widget.owner;
    if (owner != null) _load(owner, (p) => _owner = p);
    if (widget.game.botId == 'online' && widget.game.botName != null) {
      _load(widget.game.botName!, (p) => _opponent = p);
    }
  }

  Future<void> _load(String username, void Function(Player) set) async {
    try {
      final got = await PlayersRepository.instance.player(username);
      if (mounted) setState(() => set(got.player));
    } on ApiException {
      // The bar shows what the record knows.
    }
  }

  /// What [side] has taken: the other side's pieces missing from the board.
  static List<Piece> _taken(Position position, Side side) {
    const start = {
      Role.queen: 1,
      Role.rook: 2,
      Role.bishop: 2,
      Role.knight: 2,
      Role.pawn: 8,
    };
    final them = side.opposite;
    final left = <Role, int>{};
    for (final s in Square.values) {
      final p = position.board.pieceAt(s);
      if (p != null && p.color == them) left[p.role] = (left[p.role] ?? 0) + 1;
    }
    return [
      for (final e in start.entries)
        for (var i = 0; i < e.value - (left[e.key] ?? 0); i++)
          Piece(color: them, role: e.key),
    ];
  }

  /// The rating against bots kept on the phone, when storage is open.
  static int? _localRating() {
    try {
      return PlayerRatingStore.instance.rating;
    } catch (_) {
      return null;
    }
  }

  Widget _bar(BuildContext context, Side side) {
    final t = context.t;
    final g = widget.game;
    final ownerSide = g.playerIsWhite ? Side.white : Side.black;
    final isOwner = side == ownerSide;
    late final Widget avatar;
    late final String name;
    int? rating;
    String? country;

    if (g.isLocal) {
      name = side == Side.white ? t.whiteName : t.blackName;
      avatar = PlayerAvatar(size: 40, name: name);
    } else if (isOwner) {
      final other = _owner;
      if (widget.owner != null) {
        name = other?.displayName ?? widget.owner!;
        rating = other?.rating;
        country = other?.country;
        avatar = PlayerAvatar(
          size: 40,
          name: name,
          photo: avatarImage(avatarUrlFor(other?.avatarKey)),
        );
      } else {
        final account = AuthService.instance.state.value.account;
        final ready = AppStorage.isReady;
        name =
            account?.displayName ??
            (ready ? AppStorage.instance.username : null) ??
            t.youName;
        rating = account?.rating ?? _localRating();
        country = ready ? AppStorage.instance.country : null;
        final photo = ready ? AppStorage.instance.photoPath : null;
        avatar = PlayerAvatar(
          size: 40,
          name: name,
          photo: photo != null
              ? FileImage(io.File(photo))
              : avatarImage(avatarUrlFor(account?.avatarKey)),
        );
      }
    } else if (g.botId == 'online') {
      final p = _opponent;
      name = p?.displayName ?? g.botName ?? '';
      rating = p?.rating ?? g.botElo;
      country = p?.country;
      avatar = PlayerAvatar(
        size: 40,
        name: name,
        photo: avatarImage(avatarUrlFor(p?.avatarKey)),
      );
    } else {
      name = g.botName ?? 'Bot';
      rating = g.botElo;
      final file = name.isEmpty
          ? ''
          : name[0].toUpperCase() + name.substring(1);
      avatar = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(
          'assets/bots/$file.webp',
          width: 40,
          height: 40,
          cacheWidth: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => PlayerAvatar(size: 40, name: name),
        ),
      );
    }

    return GamePlayerBar(
      avatar: avatar,
      name: name,
      flag: country == null ? null : CountryFlag(country, height: 18),
      rating: rating == null ? null : t.eloValue(rating),
      captured: _taken(widget.position, side),
      advantage: boardMaterialAdvantageFor(widget.position, side),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = widget.whiteAtBottom ? Side.white : Side.black;
    return LayoutBuilder(
      builder: (context, box) {
        final side = (box.maxHeight - GamePlayerBar.height * 2).clamp(
          0.0,
          box.maxWidth,
        );
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _bar(context, bottom.opposite),
              SizedBox(width: side, height: side, child: widget.board),
              _bar(context, bottom),
            ],
          ),
        );
      },
    );
  }
}
