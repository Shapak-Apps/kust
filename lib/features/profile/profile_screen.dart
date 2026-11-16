import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kust/core/error_log.dart';
import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/features/achievements/achievements_screen.dart';
import 'package:kust/features/history/history_screen.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_text_field.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/board_banner.dart';

/// The player's profile: their board and pieces from settings, photo, name,
/// username and a few words about them, their numbers, recent games and
/// achievements, with an edit mode for changing them. Kept on the device.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _store = AppStorage.instance;
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    // A player from before onboarding asked for a username picks one first.
    if (_store.username == null) _fill();
    _name.addListener(_changed);
    _username.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      AppStorage.usernamePattern.hasMatch(_username.text.trim());

  void _back() => context.canPop() ? context.pop() : context.go('/play');

  /// Puts the saved profile in the form and opens it.
  void _fill() {
    _name.text = _store.displayName(AppText.now);
    _username.text = _store.username ?? '';
    _bio.text = _store.bio;
    _editing = true;
  }

  void _edit() => setState(_fill);

  Future<void> _save() async {
    final saved = await _store.saveProfile(
      name: _name.text,
      username: _username.text,
      bio: _bio.text,
    );
    if (saved && mounted) setState(() => _editing = false);
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) await _store.setPhoto(picked.path);
    } catch (e, st) {
      ErrorLog.record(e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return PopScope(
      // Back while editing leaves the edit, not the screen.
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _editing = false);
      },
      child: Scaffold(
        backgroundColor: k.bg,
        body: ValueListenableBuilder(
          valueListenable: _store.profileListenable(),
          builder: (context, _, _) => _editing
              ? Column(
                  children: [
                    FeltHeader(
                      title: context.t.editProfile,
                      onBack: () => setState(() => _editing = false),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        children: _form(context, k),
                      ),
                    ),
                  ],
                )
              : _view(context, k),
        ),
      ),
    );
  }

  Widget _avatar(BuildContext context, {double size = 104}) {
    final path = _store.photoPath;
    return PlayerAvatar(
      size: size,
      name: _store.displayName(context.t),
      photo: path == null ? null : FileImage(File(path)),
    );
  }

  void _qr() => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(context.t.levelComingSoon)));

  Widget _view(BuildContext context, KustTokens k) {
    final username = _store.username;
    final bio = _store.bio;
    final square = MediaQuery.sizeOf(context).width / BoardBanner.files;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 32,
            ),
            children: [
              // The board from settings, with the avatar standing on its edge.
              Stack(
                children: [
                  Column(
                    children: [
                      // Two ranks, the pawns behind the status bar.
                      BoardBanner(height: square * 2),
                      const SizedBox(height: 60),
                    ],
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: k.bg, width: 3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _avatar(context, size: 88),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _store.displayName(context.t),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: k.title,
                              ),
                              if (username != null)
                                Text(
                                  '@$username',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: k.body.copyWith(color: k.muted),
                                ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Text(bio, style: k.body),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: _Stats(),
              ),
              const _HistorySection(),
              const _AchievementsSection(),
            ],
          ),
          // The bar over the board: back, and the QR code and edit buttons.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0x00000000)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _back,
                        tooltip: context.t.back,
                        color: Colors.white,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _qr,
                        tooltip: context.t.qrCode,
                        color: Colors.white,
                        icon: const Icon(Icons.qr_code_2_rounded),
                      ),
                      IconButton(
                        onPressed: _edit,
                        tooltip: context.t.editProfile,
                        color: Colors.white,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _form(BuildContext context, KustTokens k) {
    return [
      Center(
        child: Pressable(onTap: _pickPhoto, child: _avatar(context)),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(onPressed: _pickPhoto, child: Text(context.t.choosePhoto)),
          if (_store.photoPath != null)
            TextButton(
              onPressed: () => _store.setPhoto(null),
              child: Text(
                context.t.removePhoto,
                style: TextStyle(color: k.muted),
              ),
            ),
        ],
      ),
      const SizedBox(height: 24),
      KustSectionLabel(context.t.yourName),
      KustTextField(
        controller: _name,
        maxLength: AppStorage.maxNameLength,
        capitalization: TextCapitalization.words,
      ),
      const SizedBox(height: 16),
      KustSectionLabel(context.t.username),
      KustTextField.username(
        controller: _username,
        helper: context.t.usernameRule,
      ),
      const SizedBox(height: 16),
      KustSectionLabel(context.t.bio),
      KustTextField(
        controller: _bio,
        maxLength: AppStorage.maxBioLength,
        maxLines: 4,
        capitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: 24),
      KustButton(label: context.t.saveName, onTap: _valid ? _save : null),
    ];
  }
}

/// Joined, rating and games played, side by side.
class _Stats extends StatelessWidget {
  const _Stats();

  /// Not recorded yet: a stand-in until accounts keep a real date.
  static final DateTime _joined = DateTime(2026, 11, 13);

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final month = t.monthsShort.split(',')[_joined.month - 1];
    Widget stat(String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: k.body.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(label, style: k.caption),
        ],
      ),
    );
    return ValueListenableBuilder(
      valueListenable: GameHistoryStore.instance.listenable(),
      builder: (context, _, _) => ValueListenableBuilder(
        valueListenable: PlayerRatingStore.instance.listenable(),
        builder: (context, _, _) => Row(
          children: [
            stat(
              '${t.dateShort(month, _joined.day)} ${_joined.year}',
              t.joined,
            ),
            stat('${PlayerRatingStore.instance.rating}', t.rating),
            stat('${GameHistoryStore.instance.all().length}', t.games),
          ],
        ),
      ),
    );
  }
}

/// A section title with a count beside it and a View all link.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.count,
    required this.onViewAll,
  });

  final String title;
  final String count;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 4),
      child: Row(
        children: [
          Text(title, style: k.title),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: k.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count,
              style: k.caption.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const Spacer(),
          TextButton(onPressed: onViewAll, child: Text(context.t.viewAll)),
        ],
      ),
    );
  }
}

/// The last few games, and the way to all of them.
class _HistorySection extends StatelessWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ValueListenableBuilder(
      valueListenable: GameHistoryStore.instance.listenable(),
      builder: (context, _, _) {
        final games = GameHistoryStore.instance.all();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              title: context.t.gameHistory,
              count: '${games.length}',
              onViewAll: () => context.push('/history'),
            ),
            if (games.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  context.t.histNoGames,
                  style: k.body.copyWith(color: k.muted),
                ),
              ),
            for (final (i, game) in games.take(5).indexed) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: k.line),
              GameTile(game: game),
            ],
          ],
        );
      },
    );
  }
}

/// Achievements in a row of tiles, earned ones first and in colour.
class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AchievementStore.instance.listenable(),
      builder: (context, _, _) {
        final unlocked = AchievementStore.instance.unlocked();
        final sorted = [
          ...kAchievements.where((a) => unlocked.containsKey(a.id)),
          ...kAchievements.where((a) => !unlocked.containsKey(a.id)),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              title: context.t.achievements,
              count: '${unlocked.length}/${kAchievements.length}',
              onViewAll: () => context.push('/achievements'),
            ),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final a = sorted[i];
                  return Semantics(
                    label:
                        '${a.titleIn(context.t)}, '
                        '${unlocked.containsKey(a.id) ? context.t.achEarned : context.t.achNotEarned}',
                    excludeSemantics: true,
                    child: Pressable(
                      onTap: () => context.push('/achievements'),
                      child: _AchievementBadge(
                        achievement: a,
                        earned: unlocked.containsKey(a.id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One achievement as a badge (see [AchievementIcon]) with its name under
/// it.
class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.achievement, required this.earned});

  final Achievement achievement;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          AchievementIcon(achievement: achievement, earned: earned),
          const SizedBox(height: 8),
          Text(
            achievement.titleIn(context.t),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: k.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: earned ? k.ink : k.muted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
