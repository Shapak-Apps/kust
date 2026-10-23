import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Thrown when a network file cannot be fetched or fails verification.
class NnueException implements Exception {
  const NnueException(this.message);

  final String message;

  @override
  String toString() => 'NnueException: $message';
}

/// Downloads and verifies Stockfish's NNUE network files.
///
/// The files are ~110MB so they are not bundled. A network named
/// `nn-<12 hex>.nnue` is valid when the first 12 hex digits of the SHA-256 of
/// its contents equal that name part, which is how Stockfish names them.
class NnueStore {
  NnueStore({Dio? dio, this.baseUrl = 'https://data.stockfishchess.org/nn'})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60),
            ),
          );

  final Dio _dio;
  final String baseUrl;

  /// Download progress of the file being fetched, 0..1, or null when idle.
  static final ValueNotifier<double?> progress = ValueNotifier(null);

  static final RegExp _nameRe = RegExp(r'^nn-([0-9a-f]{12})\.nnue$');

  /// Whether [file] holds the network that [name] promises.
  static Future<bool> verify(File file, String name) async {
    final match = _nameRe.firstMatch(name);
    if (match == null || !await file.exists()) return false;
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().startsWith(match.group(1)!);
  }

  /// Returns the path to a verified copy of [name] inside [dir], downloading
  /// it first when missing or corrupt. Safe to interrupt: data goes to a
  /// `.part` file that is only renamed after verification.
  Future<String> ensure(
    String name,
    String dir, {
    double progressFrom = 0,
    double progressTo = 1,
    int attempts = 3,
  }) async {
    final target = File('$dir/$name');
    if (await verify(target, name)) return target.path;
    if (await target.exists()) await target.delete();

    final part = File('${target.path}.part');
    Object? lastError;
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        if (await part.exists()) await part.delete();
        await _dio.download(
          '$baseUrl/$name',
          part.path,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              progress.value =
                  progressFrom + (progressTo - progressFrom) * received / total;
            }
          },
        );
        if (!await verify(part, name)) {
          throw const NnueException('Downloaded network failed verification');
        }
        await part.rename(target.path);
        return target.path;
      } catch (e) {
        lastError = e;
        if (await part.exists()) await part.delete();
        if (attempt < attempts) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    throw NnueException('Could not download $name: $lastError');
  }
}
