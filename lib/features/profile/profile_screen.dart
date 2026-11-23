import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kust/core/countries.dart';
import 'package:kust/core/error_log.dart';
import 'package:kust/core/net/account.dart';
import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/server_config.dart';
import 'package:kust/core/storage/game_history_store.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/achievements/achievements.dart';
import 'package:kust/features/achievements/achievements_screen.dart';
import 'package:kust/features/history/history_screen.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/country_flag.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_sheet.dart';
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

  void _openPlayers() {
    final auth = AuthService.instance.state.value;
    if (!auth.isSignedIn) {
      _showSignInSheet();
    } else if (!auth.isVerified) {
      context.push('/verify');
    } else {
      context.push('/players');
    }
  }

  void _showSignInSheet() {
    final t = context.t;
    showKustSheet<void>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KustSheetHeader(
            title: t.signInToSeePlayers,
            subtitle: t.signInToSeePlayersBody,
          ),
          KustButton(
            label: t.signIn,
            onTap: () {
              Navigator.of(sheet).pop();
              context.push('/login');
            },
          ),
          const SizedBox(height: 8),
          KustButton(
            label: t.createAccount,
            style: KustButtonStyle.secondary,
            onTap: () {
              Navigator.of(sheet).pop();
              context.push('/register');
            },
          ),
        ],
      ),
    );
  }

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
      // Shrunk on the phone to at most 512 px as a JPEG (around 30–60 KB),
      // so uploads are quick and the bucket stays small.
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;
      await _store.setPhoto(picked.path);
      if (AuthService.instance.state.value.isSignedIn) {
        try {
          await AuthService.instance.uploadAvatar(await picked.readAsBytes());
        } on ApiException {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.t.photoNotUploaded),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
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
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        children: _form(context, k),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: KustButton(
                          label: context.t.saveName,
                          onTap: _valid ? _save : null,
                        ),
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
      // The photo on this phone, else the account's (signed in elsewhere).
      photo: path != null
          ? FileImage(File(path))
          : avatarImage(
              avatarUrlFor(AuthService.instance.state.value.account?.avatarKey),
            ),
    );
  }

  Widget _view(BuildContext context, KustTokens k) {
    final username = _store.username;
    final bio = _store.bio;
    final country = _store.country;
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
                              // The name with the country's flag after it.
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _store.displayName(context.t),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: k.title,
                                    ),
                                  ),
                                  if (country != null) ...[
                                    const SizedBox(width: 8),
                                    CountryFlag(country, height: 22),
                                  ],
                                ],
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
              const _AccountCard(),
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
                        onPressed: _openPlayers,
                        tooltip: context.t.allPlayers,
                        color: Colors.white,
                        icon: const Icon(Icons.public_rounded),
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
    final t = context.t;
    final country = _store.country;
    return [
      // The photo, with a camera on its corner: tap to change it.
      Center(
        child: Semantics(
          button: true,
          label: t.choosePhoto,
          child: Pressable(
            onTap: _pickPhoto,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _avatar(context),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: k.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: k.bg, width: 3),
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      size: 18,
                      color: k.accentInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (_store.photoPath != null)
        Center(
          child: TextButton(
            onPressed: () {
              _store.setPhoto(null);
              if (AuthService.instance.state.value.isSignedIn) {
                AuthService.instance.removeAvatar().ignore();
              }
            },
            child: Text(t.removePhoto, style: TextStyle(color: k.muted)),
          ),
        )
      else
        const SizedBox(height: 16),
      const SizedBox(height: 8),
      // One group of rows, label on the left and the value beside it.
      Container(
        decoration: BoxDecoration(
          color: k.surface,
          borderRadius: BorderRadius.circular(KustSpace.rMedium),
        ),
        child: Column(
          children: [
            _FormRow(
              label: t.yourName,
              child: KustTextField(
                controller: _name,
                maxLength: AppStorage.maxNameLength,
                capitalization: TextCapitalization.words,
                bare: true,
              ),
            ),
            _FormRow(
              label: t.username,
              child: KustTextField.username(controller: _username, bare: true),
            ),
            _FormRow(
              label: t.country,
              onTap: () async {
                final picked = await pickCountry(context, current: country);
                if (picked != null) {
                  await _store.setCountry(picked.isEmpty ? null : picked);
                }
              },
              child: Row(
                children: [
                  if (country != null) ...[
                    CountryFlag(country, height: 22),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      country == null ? t.countryNone : kCountries[country]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: k.body.copyWith(
                        color: country == null ? k.muted : k.ink,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: k.muted),
                ],
              ),
            ),
            _FormRow(
              label: t.bio,
              last: true,
              child: KustTextField(
                controller: _bio,
                maxLength: AppStorage.maxBioLength,
                maxLines: 3,
                capitalization: TextCapitalization.sentences,
                bare: true,
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        child: Text(t.usernameRule, style: k.caption),
      ),
    ];
  }
}

/// A row of the edit form: the label on the left, the value beside it, a
/// hairline under it unless it is the [last].
class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.label,
    required this.child,
    this.onTap,
    this.last = false,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: k.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: k.body.copyWith(color: k.muted)),
          ),
          Expanded(child: child),
        ],
      ),
    );
    return onTap == null ? row : Pressable(onTap: onTap, child: row);
  }
}

/// When the player joined, rating and games played, side by side.
class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final joined = AppStorage.isReady ? AppStorage.instance.joinedAt : null;
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
            if (joined != null)
              stat(
                '${t.dateShort(t.monthsShort.split(',')[joined.month - 1], joined.day)} '
                '${joined.year}',
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
          // The title takes the room up to View all, and only then is cut.
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: k.title,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: k.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count,
                    style: k.caption.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            child: Text(context.t.viewAll, maxLines: 1),
          ),
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
                      child: AchievementBadge(
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
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.achievement,
    required this.earned,
  });

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

/// For a guest: what an account gives, with the two ways to get one.
/// Under the stats, where it is seen without crowding the player's name.
class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    if (!ServerConfig.enabled) return const SizedBox.shrink();
    final k = context.k;
    final t = context.t;
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthService.instance.state,
      builder: (context, auth, _) {
        if (auth.status != AuthStatus.signedOut) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: k.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: k.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: KustTokens.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: KustTokens.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.accountCardTitle,
                            style: k.body.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(t.accountCardBody, style: k.caption),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: KustButton(
                        label: t.createAccount,
                        height: 46,
                        onTap: () => context.push('/register'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: KustButton(
                        label: t.signIn,
                        height: 46,
                        style: KustButtonStyle.secondary,
                        onTap: () => context.push('/login'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
