import 'package:flutter/widgets.dart';

/// [duration], or none when the system asks for less motion.
Duration motion(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
