import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kust/core/error_log.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_text_field.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// The player's profile: photo, name, username and a few words about them,
/// with an edit mode for changing them. Kept on the device.
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

  void _edit() {
    _name.text = _store.displayName(context.t);
    _username.text = _store.username ?? '';
    _bio.text = _store.bio;
    setState(() => _editing = true);
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
        body: Column(
          children: [
            FeltHeader(
              title: _editing ? context.t.editProfile : context.t.profile,
              onBack: _editing ? () => setState(() => _editing = false) : _back,
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _store.profileListenable(),
                builder: (context, _, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  children: _editing ? _form(context, k) : _view(context, k),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(BuildContext context) {
    final path = _store.photoPath;
    return PlayerAvatar(
      size: 104,
      name: _store.displayName(context.t),
      photo: path == null ? null : FileImage(File(path)),
    );
  }

  List<Widget> _view(BuildContext context, KustTokens k) {
    final username = _store.username;
    final bio = _store.bio;
    return [
      Center(child: _avatar(context)),
      const SizedBox(height: 16),
      Text(
        _store.displayName(context.t),
        textAlign: TextAlign.center,
        style: k.title,
      ),
      if (username != null) ...[
        const SizedBox(height: 4),
        Text(
          '@$username',
          textAlign: TextAlign.center,
          style: k.body.copyWith(color: k.muted),
        ),
      ],
      if (bio.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(bio, textAlign: TextAlign.center, style: k.body),
      ],
      const SizedBox(height: 24),
      KustButton(
        label: context.t.editProfile,
        icon: Icons.edit_outlined,
        style: KustButtonStyle.outline,
        onTap: _edit,
      ),
    ];
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
