import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/game/chess/chess_helpers.dart';
import 'package:kust/features/learn/learn_progress.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/features/learn/garden_map.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/ui/kust_button_3d.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/widgets/piece_image.dart';

/// The Learn tab: a garden map with a raised tile for every lesson, from
/// the first pawn move at the bottom to checkmate at the top. The header tells
/// the stars earned and the camp you are in; the card at the bottom starts
/// the next lesson.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  ScrollController? _scroll;
  bool _loaded = false;

  /// Height of the header that floats over the top of the map.
  static const double _header = 196;

  /// Height of the up-next card over the bottom of the map.
  static const double _card = 96;

  @override
  void initState() {
    super.initState();
    LearnProgress.instance.load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  /// The trail starts at the foot, scrolled so the next stop is in view.
  ScrollController _controllerFor(
    LearnMapLayout layout,
    double viewport,
    int next,
  ) {
    return _scroll ??= ScrollController(
      initialScrollOffset: (layout.fromBottom(next) - viewport * 0.45).clamp(
        0.0,
        layout.height - viewport,
      ),
    );
  }

  void _open(Lesson lesson) => context.push('/lesson/${lesson.id}');

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final nav = KustNavBar.clearance(context);
    return ColoredBox(
      color: GardenColors.ground,
      child: !_loaded
          ? const SizedBox.expand()
          : LayoutBuilder(
              builder: (context, box) {
                final layout = LearnMapLayout(
                  width: box.maxWidth,
                  count: kLessons.length,
                  topInset: top + _header - 40,
                  footRoom: nav + _card + 120,
                );
                return ValueListenableBuilder<Set<String>>(
                  valueListenable: LearnProgress.instance.done,
                  builder: (context, done, _) {
                    final progress = LearnProgress.instance;
                    final nextIndex = kLessons.indexWhere(
                      (l) => !done.contains(l.id),
                    );
                    final controller = _controllerFor(
                      layout,
                      box.maxHeight,
                      nextIndex < 0 ? kLessons.length - 1 : nextIndex,
                    );
                    final camp = Camp.of(
                      nextIndex < 0 ? kLessons.length - 1 : nextIndex,
                    );
                    return Stack(
                      children: [
                        // Scrolled from the bottom, the way you climb.
                        SingleChildScrollView(
                          controller: controller,
                          reverse: true,
                          child: LearnMap(
                            layout: layout,
                            done: done,
                            stars: progress.stars,
                            onOpen: _open,
                            coachImage: 'assets/bots/Bahar.webp',
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: _Header(
                            top: top,
                            stars: progress.totalStars,
                            maxStars: kLessons.length * 3,
                            camp: camp,
                            campDone: [
                              for (var i = camp.first; i <= camp.last; i++)
                                if (done.contains(kLessons[i].id)) i,
                            ].length,
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: nav - 4,
                          child: nextIndex < 0
                              ? const _SummitCard()
                              : _UpNextCard(
                                  index: nextIndex,
                                  done: done.length,
                                  onStart: () => _open(kLessons[nextIndex]),
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.top,
    required this.stars,
    required this.maxStars,
    required this.camp,
    required this.campDone,
  });

  final double top;
  final int stars;
  final int maxStars;
  final Camp camp;
  final int campDone;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF10241A), Color(0xEE10241A), Color(0x0010241A)],
          stops: [0, 0.7, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.learnTitle,
                      style: const TextStyle(
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: Color(0xFFF2F0EA),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.learnSub,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFAEB6C8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
                decoration: BoxDecoration(
                  color: const Color(0xCC0F1320),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: GardenColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$stars / $maxStars',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF2F0EA),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CampBanner(camp: camp, done: campDone),
        ],
      ),
    );
  }
}

class _CampBanner extends StatelessWidget {
  const _CampBanner({required this.camp, required this.done});

  final Camp camp;
  final int done;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17694A), Color(0xFF0F4A33)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x803CB77C)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF0B3325),
              shape: BoxShape.circle,
            ),
            child: Icon(
              camp.isSummit ? Icons.flag_rounded : Icons.cabin_rounded,
              color: const Color(0xFFBFF0D6),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${camp.label(t)} · ${camp.title(t).toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Color(0xFF9EE7C1),
                        ),
                      ),
                    ),
                    Text(
                      '$done/${camp.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFBFF0D6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  camp.subtitle(t),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: done / camp.length,
                    minHeight: 4,
                    backgroundColor: const Color(0xFF0B3325),
                    color: const Color(0xFF3CB77C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The next lesson, ready to start: a ring for the climb so far, its name
/// and size, and a big green button.
class _UpNextCard extends StatelessWidget {
  const _UpNextCard({
    required this.index,
    required this.done,
    required this.onStart,
  });

  final int index;
  final int done;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final lesson = kLessons[index];
    final piece = lesson.piece;
    return Pressable(
      onTap: onStart,
      haptic: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF26221E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x10FFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: done / kLessons.length,
                      strokeWidth: 4,
                      backgroundColor: const Color(0x14FFFFFF),
                      color: const Color(0xFF3CB77C),
                    ),
                  ),
                  if (piece != null)
                    PieceImage(
                      assetForPiece(Piece(color: Side.white, role: piece)),
                      width: 30,
                      height: 30,
                    )
                  else
                    Icon(lesson.icon, color: const Color(0xFFF2F0EA)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.learnUpNext(index + 1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF9EE7C1),
                    ),
                  ),
                  Text(
                    lesson.title(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF2F0EA),
                    ),
                  ),
                  Text(
                    t.lessonMinutes(
                      lesson.tasks.length,
                      (lesson.tasks.length * 0.7).ceil(),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E8C86),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            KustButton3D(label: t.lessonStart.split(' ').first, onTap: onStart),
          ],
        ),
      ),
    );
  }
}

class _SummitCard extends StatelessWidget {
  const _SummitCard();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF26221E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: GardenColors.gold,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.learnSummitDone,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF2F0EA),
              ),
            ),
          ),
          KustButton3D(label: t.play, onTap: () => context.go('/play')),
        ],
      ),
    );
  }
}
