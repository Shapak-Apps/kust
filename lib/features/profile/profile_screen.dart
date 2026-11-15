import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kust/core/error_log.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/felt_header.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

/// The player's profile: photo, name, username and a few words about them.
/// Kept on the device.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _store = AppStorage.instance;
  late final _name = TextEditingController(
    text: _store.displayName(AppText.now),
  );
  late final _username = TextEditingController(text: _store.username ?? '');
  late final _bio = TextEditingController(text: _store.bio);

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
      AppStorage.usernamePattern.hasMatch(_username.text.trim().toLowerCase());

  void _back() => context.canPop() ? context.pop() : context.go('/play');

  Future<void> _save() async {
    final saved = await _store.saveProfile(
      name: _name.text,
      username: _username.text,
      bio: _bio.text,
    );
    if (saved && mounted) _back();
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
    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          FeltHeader(title: context.t.profile, onBack: _back),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                ValueListenableBuilder(
                  valueListenable: _store.nameListenable(),
                  builder: (context, _, _) => _photo(context, k),
                ),
                const SizedBox(height: 24),
                KustSectionLabel(context.t.yourName),
                _field(
                  k,
                  _name,
                  maxLength: AppStorage.maxNameLength,
                  capitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                KustSectionLabel(context.t.username),
                _field(
                  k,
                  _username,
                  maxLength: 20,
                  prefix: '@',
                  helper: context.t.usernameRule,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]')),
                  ],
                ),
                const SizedBox(height: 16),
                KustSectionLabel(context.t.bio),
                _field(
                  k,
                  _bio,
                  maxLength: AppStorage.maxBioLength,
                  maxLines: 4,
                  capitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),
                KustButton(
                  label: context.t.saveName,
                  onTap: _valid ? _save : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photo(BuildContext context, KustTokens k) {
    final path = _store.photoPath;
    return Column(
      children: [
        Pressable(
          onTap: _pickPhoto,
          child: PlayerAvatar(
            size: 104,
            name: _store.displayName(context.t),
            photo: path == null ? null : FileImage(File(path)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _pickPhoto,
              child: Text(context.t.choosePhoto),
            ),
            if (path != null)
              TextButton(
                onPressed: () => _store.setPhoto(null),
                child: Text(
                  context.t.removePhoto,
                  style: TextStyle(color: k.muted),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _field(
    KustTokens k,
    TextEditingController controller, {
    required int maxLength,
    int maxLines = 1,
    String? prefix,
    String? helper,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: 1,
      textCapitalization: capitalization,
      inputFormatters: formatters,
      autocorrect: prefix == null,
      style: k.body,
      decoration: InputDecoration(
        counterText: '',
        prefixText: prefix,
        helperText: helper,
        filled: true,
        fillColor: k.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KustSpace.rMedium),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
