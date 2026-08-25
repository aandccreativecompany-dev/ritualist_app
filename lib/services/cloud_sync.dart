import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';
import '../store.dart';
import 'auth_service.dart';

/// Optional cloud backup for signed-in users: the whole local AppState blob
/// is mirrored to Firestore under the signed-in user's own uid, and pulled
/// back down whenever they sign in (including a fresh device). This is a
/// last-write-wins backup, not a merge engine — good enough for "my data
/// follows my account," not for editing the same account from two phones
/// at the same moment.
class CloudSync {
  CloudSync._();
  static final CloudSync instance = CloudSync._();

  final _db = FirebaseFirestore.instance;
  Timer? _debounce;
  bool _wired = false;

  /// Starts mirroring local edits to Firestore whenever a user is signed
  /// in. Safe to call once, at app start — it's a no-op until someone
  /// actually signs in.
  void wire() {
    if (_wired) return;
    _wired = true;
    store.addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => _push(user.uid));
  }

  Future<void> _push(String uid) async {
    try {
      await _db.collection('users').doc(uid).set({
        'state': store.state.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best-effort — local storage is always the source of truth if a
      // push fails (no network, rules not deployed yet, etc.).
    }
  }

  /// Pulls the signed-in user's cloud copy down and replaces local state
  /// with it. Call right after a successful sign-in.
  Future<void> pullAndApply(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).get();
      final data = snap.data();
      final remoteState = data?['state'];
      if (remoteState is Map) {
        await store.replaceState(
            AppState.fromJson(Map<String, dynamic>.from(remoteState)));
      } else {
        // First sign-in from this device with no cloud copy yet — push
        // what's here now so the account has something to sync from.
        await _push(uid);
      }
    } catch (_) {
      // No network, or Firestore rules aren't live yet — keep using
      // whatever's already on the device.
    }
  }
}
