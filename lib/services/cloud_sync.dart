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

  /// Explicit, user-triggered "Back up now" — pushes immediately rather
  /// than waiting for the debounce, and waits for any queued local save to
  /// land first so the pushed copy reflects everything just entered.
  Future<void> backUpNow(String uid) async {
    _debounce?.cancel();
    await store.flush();
    await _push(uid);
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

  /// Pulls the signed-in user's cloud copy down and REPLACES local state
  /// with it — destructive, last-write-wins. Only call this when the user
  /// has explicitly asked to restore from their cloud backup (e.g. a new
  /// phone), never automatically: see `pullIfFreshInstall` for the
  /// auto-sync-on-launch path, which deliberately never calls this.
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

  /// Safe to call every time the app launches with an already-signed-in
  /// user (Firebase persists sign-in across launches, so this fires on
  /// every cold start, not just a fresh sign-in). Used to be `pullAndApply`
  /// unconditionally, which meant: whenever the debounced 2-second push
  /// hadn't yet reached the cloud before the app closed (backgrounded,
  /// force-quit, "swiped away", or just no network at that moment), the NEXT
  /// launch would silently overwrite the on-device data — including
  /// whatever was written after that last successful push — with the older
  /// cloud snapshot. That's exactly what "a saved journal entry is gone a
  /// week later" looks like: the entry was real, saved locally, and then
  /// wiped by this call reviving a stale backup. Local storage is this
  /// app's actual source of truth (per the comment on `_push` above); the
  /// cloud copy exists to hand data to a NEW device, not to reconcile with
  /// an existing one that already has real data on it. So this only ever
  /// pulls when the device looks like a fresh install (nothing local yet) —
  /// otherwise it just makes sure the cloud copy is fresh by pushing now.
  Future<void> pullIfFreshInstall(String uid) async {
    if (!store.looksEmpty) {
      unawaited(_push(uid));
      return;
    }
    await pullAndApply(uid);
  }
}
