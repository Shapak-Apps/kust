import 'package:kust/l10n/app_locale.dart';

class TimeControl {
  const TimeControl({required this.baseMinutes, this.incrementSeconds = 0});

  final int baseMinutes;
  final int incrementSeconds;

  Duration get base => Duration(minutes: baseMinutes);
  Duration get increment => Duration(seconds: incrementSeconds);

  String get label => labelIn(AppText.now);

  String labelIn(AppL10n t) => incrementSeconds > 0
      ? '$baseMinutes+$incrementSeconds'
      : t.minutesShort(baseMinutes);

  static Duration display(Duration d) {
    if (d <= Duration.zero) return Duration.zero;
    return Duration(seconds: (d.inMilliseconds / 1000).ceil());
  }

  static String format(Duration d) {
    final total = d.inSeconds.clamp(0, 59999);
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
