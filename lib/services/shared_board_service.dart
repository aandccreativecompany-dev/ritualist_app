import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// A lightweight, text-only collaborative vision board: create one and get
/// a short code, or join one with a code someone shared with you. Anyone
/// who has the code and is signed in can add a point — the code itself is
/// the access control, the same model many lightweight shared-list apps
/// use. Deliberately text-only (no photos) since syncing images would need
/// Firebase Storage wired up separately, which this app doesn't have yet.
///
/// Requires a new Firestore security rule the app's Firebase console needs
/// (see the delivery notes) — the existing rules only cover the per-user
/// `users/{uid}` backup collection, not this one.
class SharedBoardService {
  SharedBoardService._();
  static final SharedBoardService instance = SharedBoardService._();

  final _db = FirebaseFirestore.instance;
  static const _collection = 'sharedVisionBoards';

  String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I — easy to read aloud
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Creates a new shared board with an auto-generated code, retrying on
  /// the rare chance of a collision. Returns the code.
  Future<String> createBoard({required String title, required String ownerUid}) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _randomCode();
      final doc = _db.collection(_collection).doc(code);
      final existing = await doc.get();
      if (existing.exists) continue;
      await doc.set({
        'title': title,
        'ownerUid': ownerUid,
        'points': <Map<String, dynamic>>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return code;
    }
    throw Exception('Could not generate a unique board code — try again.');
  }

  /// Returns the board's title if [code] exists, or null if it doesn't.
  Future<String?> joinBoard(String code) async {
    final doc = await _db.collection(_collection).doc(code.trim().toUpperCase()).get();
    final data = doc.data();
    if (data == null) return null;
    final title = data['title'];
    return title is String ? title : 'Shared board';
  }

  Future<void> addPoint({
    required String code,
    required String text,
    required String addedByName,
  }) async {
    await _db.collection(_collection).doc(code.trim().toUpperCase()).update({
      'points': FieldValue.arrayUnion([
        {'text': text, 'addedBy': addedByName, 'addedAt': DateTime.now().toIso8601String()}
      ]),
    });
  }

  /// Returns the board's points as a list of (text, addedBy) pairs, newest
  /// first. Returns an empty list if the board doesn't exist or the fetch
  /// fails — callers should not treat that as fatal.
  Future<List<(String, String)>> fetchPoints(String code) async {
    try {
      final doc = await _db.collection(_collection).doc(code.trim().toUpperCase()).get();
      final rawPoints = doc.data()?['points'];
      if (rawPoints is! List) return [];
      final result = <(String, String)>[];
      for (final entry in rawPoints) {
        if (entry is Map) {
          final text = entry['text'];
          final addedBy = entry['addedBy'];
          if (text is String && text.isNotEmpty) {
            result.add((text, addedBy is String ? addedBy : ''));
          }
        }
      }
      return result.reversed.toList();
    } catch (_) {
      return [];
    }
  }
}
