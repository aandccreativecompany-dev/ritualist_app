import 'dart:convert';
import 'dart:io';

import '../app_version.dart';

/// One release, as reported by GitHub — just the two fields the update
/// banner needs.
class UpdateInfo {
  final String version; // e.g. "0.4.1" (tag's leading "v" stripped)
  final String url; // the GitHub Release page, for "What's new"
  const UpdateInfo({required this.version, required this.url});
}

/// Checks GitHub Releases for a newer build than the one currently running.
/// Deliberately dependency-free (plain `dart:io`/`dart:convert`, no http
/// package, no package_info_plus) — one more network plugin isn't worth it
/// for a single GET request, per the "keep app size down" constraint.
class UpdateChecker {
  UpdateChecker._();
  static final UpdateChecker instance = UpdateChecker._();

  static const _owner = 'aandccreativecompany-dev';
  // Update this if/when the GitHub repo itself gets renamed to match the
  // app (e.g. via `gh repo rename prakriya_app`) — this string has to match
  // the repo's actual name on GitHub for the Releases API call below to
  // find anything.
  static const _repo = 'prakriya_app';

  /// Returns the latest release's info if it's newer than [kAppVersion],
  /// otherwise null. Never throws — a missing network, GitHub rate limit, or
  /// unexpected response shape just means "no update to report this time."
  Future<UpdateInfo?> checkForUpdate() async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(Uri.https(
          'api.github.com', '/repos/$_owner/$_repo/releases/latest'));
      request.headers.set('Accept', 'application/vnd.github+json');
      request.headers.set('User-Agent', 'prakriya-app');
      final response = await request.close().timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        await response.drain<void>();
        return null;
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final tag = decoded['tag_name'];
      final url = decoded['html_url'];
      if (tag is! String || tag.isEmpty) return null;
      final remoteVersion = tag.startsWith('v') ? tag.substring(1) : tag;
      if (!_isNewer(remoteVersion, kAppVersion)) return null;
      return UpdateInfo(
        version: remoteVersion,
        url: url is String && url.isNotEmpty
            ? url
            : 'https://github.com/$_owner/$_repo/releases/latest',
      );
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  /// Numeric, dot-separated comparison ("0.10.0" > "0.9.0"), unlike a plain
  /// string compare — falls back to false (not newer) on anything that
  /// doesn't parse as numbers, so a malformed tag never falsely nags.
  bool _isNewer(String remote, String local) {
    final r = remote.split('.').map((p) => int.tryParse(p) ?? -1).toList();
    final l = local.split('.').map((p) => int.tryParse(p) ?? -1).toList();
    if (r.contains(-1) || l.contains(-1)) return false;
    for (var i = 0; i < r.length || i < l.length; i++) {
      final rv = i < r.length ? r[i] : 0;
      final lv = i < l.length ? l[i] : 0;
      if (rv != lv) return rv > lv;
    }
    return false;
  }
}
