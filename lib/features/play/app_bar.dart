import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key, this.userAvatar});

  final String? userAvatar;

  static const double appBarHeight = 48;

  @override
  Size get preferredSize => const Size.fromHeight(appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: appBarHeight,
      backgroundColor: const Color(0xFFFFBB00).withValues(alpha: 0.85),
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,

      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: userAvatar == null
                ? Container(
                    width: 32,
                    height: 32,
                    color: const Color(0xFFCCCCCC).withOpacity(0.05),
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Color(0xFF181A1B),
                    ),
                  )
                : Image.network(
                    userAvatar!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ),

      title: Center(
        child: SvgPicture.asset('assets/images/header.svg', height: 47),
      ),

      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        const SizedBox(width: 4),
      ],
    );
  }
}
