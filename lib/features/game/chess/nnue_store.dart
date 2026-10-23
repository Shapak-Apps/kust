import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thrown when the engine's network files are missing or fail verification.
class NnueException implements Exception {
  const NnueException(this.message);

  final String message;

  @override
  String toString() => 'NnueException: $message';
}

/// Unpacks Stockfish's NNUE networks from the app bundle. No network access.
///
/// Each network ships as gzip pieces `assets/engine/<name>.<n>.gz` (see
/// `tools/pack_nnue.py`) because GitHub rejects files over 100MB. The pieces
/// are decompressed one at a time, so memory stays low, and written to the
/// app's support directory on first launch.
///
/// A network named `nn-<12 hex>.nnue` is valid when the first 12 hex digits of
/// the SHA-256 of its contents equal that name part, which is how Stockfish
/// names them.
class NnueStore {
  NnueStore({AssetBundle? bundle, this.listParts})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// Overrides how the pieces of a network are found; for tests.
  final Future<List<String>> Function(String name)? listParts;

  /// Unpack progress of the file being written, 0..1, or null when idle.
  static final ValueNotifier<double?> progress = ValueNotifier(null);

  static const String assetDir = 'assets/engine';
  static final RegExp _nameRe = RegExp(r'^nn-([0-9a-f]{12})\.nnue$');

  /// Whether [file] holds the network that [name] promises.
  static Future<bool> verify(File file, String name) async {
    final match = _nameRe.firstMatch(name);
    if (match == null || !await file.exists()) return false;
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().startsWith(match.group(1)!);
  }

  Future<List<String>> _parts(String name) async {
    final custom = listParts;
    final List<String> keys;
    if (custom != null) {
      keys = await custom(name);
    } else {
      final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
      keys = manifest
          .listAssets()
          .where((k) => k.startsWith('$assetDir/$name.'))
          .toList();
    }
    int index(String key) =>
        int.tryParse(key.split('.').reversed.skip(1).first) ?? 1 << 30;
    return keys.where((k) => k.endsWith('.gz')).toList()
      ..sort((a, b) => index(a).compareTo(index(b)));
  }

  /// A file that was fully verified once is trusted on later launches if its
  /// length still matches, which avoids hashing 100MB on every start.
  Future<bool> _isTrusted(File target, File marker) async {
    if (!await target.exists() || !await marker.exists()) return false;
    final recorded = int.tryParse((await marker.readAsString()).trim());
    return recorded != null && recorded == await target.length();
  }

  /// Returns the path to a verified copy of [name] inside [dir], unpacking it
  /// first when missing or damaged. Safe to interrupt: data goes to a `.part`
  /// file that is only renamed once it verifies.
  Future<String> ensure(
    String name,
    String dir, {
    double progressFrom = 0,
    double progressTo = 1,
  }) async {
    final target = File('$dir/$name');
    final marker = File('${target.path}.ok');
    if (await _isTrusted(target, marker)) return target.path;

    if (await marker.exists()) await marker.delete();
    if (await target.exists()) await target.delete();

    final parts = await _parts(name);
    if (parts.isEmpty) {
      throw NnueException('$name is missing from this build');
    }

    final part = File('${target.path}.part');
    if (await part.exists()) await part.delete();
    final sink = part.openWrite();
    try {
      for (var i = 0; i < parts.length; i++) {
        final data = await _bundle.load(parts[i]);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        sink.add(await Isolate.run(() => gzip.decode(bytes)));
        progress.value =
            progressFrom + (progressTo - progressFrom) * (i + 1) / parts.length;
      }
      await sink.flush();
    } catch (e) {
      await sink.close().catchError((Object _) {});
      if (await part.exists()) await part.delete();
      throw NnueException('Could not unpack $name: $e');
    }
    await sink.close();

    if (!await verify(part, name)) {
      await part.delete();
      throw NnueException('$name is damaged');
    }
    await part.rename(target.path);
    await marker.writeAsString('${await target.length()}');
    return target.path;
  }
}
