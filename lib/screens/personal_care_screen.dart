import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// Personal Care — mirrors the "Personal Care → Skin Care" section added to
/// the website: right now it's just the Skin Care intake form, embedded
/// in-app via a WebView so filling it out doesn't require leaving the app.
/// More Personal Care sub-sections (sleep, nutrition, movement) can slot in
/// next to this one later, same as on the website.
class PersonalCareScreen extends StatefulWidget {
  const PersonalCareScreen({super.key});

  @override
  State<PersonalCareScreen> createState() => _PersonalCareScreenState();
}

// Same Google Form as the website's Personal Care → Skin Care section
// (resolved from the forms.gle short link to its stable embeddable URL).
const _formEmbedUrl =
    'https://docs.google.com/forms/d/e/1FAIpQLSfqOxgf-prd-fNYpgHZu7nFDqeYEse88UVPpgWNxi-UPREecw/viewform?embedded=true';
const _formDirectUrl = 'https://forms.gle/ZYEt3fHograpWJW18';

class _PersonalCareScreenState extends State<PersonalCareScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            // Most likely: no internet connection. Fall back to a clear
            // "open in your browser" path rather than a stuck spinner or a
            // native error page that looks like the app is broken.
            if (mounted) {
              setState(() {
                _loading = false;
                _failed = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_formEmbedUrl));
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(_formDirectUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing more we can do offline; the button stays tappable to retry.
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    _controller.loadRequest(Uri.parse(_formEmbedUrl));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: Surfaces.pageBackground(dark),
        child: SafeArea(
          child: FadeSlideIn(
            child: Column(
              children: [
                const ScreenHeader(
                  icon: Icons.spa_outlined,
                  title: 'Personal Care',
                  subtitle: 'Skin Care — a quick, honest check-in. It shapes what we cover here next.',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Surfaces.cardBorder(dark)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Stack(
                          children: [
                            if (!_failed)
                              Positioned.fill(child: WebViewWidget(controller: _controller)),
                            if (_loading && !_failed)
                              const Positioned.fill(
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            if (_failed)
                              Positioned.fill(
                                child: Container(
                                  color: Surfaces.card(dark),
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.wifi_off_rounded,
                                          size: 32, color: Surfaces.muted(dark)),
                                      const SizedBox(height: 14),
                                      Text('Couldn’t load the form',
                                          style: display(16, Surfaces.heading(dark))),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Check your connection, or open it in your browser instead.',
                                        textAlign: TextAlign.center,
                                        style: body(13, Surfaces.muted(dark)),
                                      ),
                                      const SizedBox(height: 20),
                                      GoldButton(labelText: 'Try again', onPressed: _retry),
                                      const SizedBox(height: 10),
                                      TextButton(
                                        onPressed: _openExternally,
                                        child: Text('Open in browser instead',
                                            style: body(13, Surfaces.accent(dark),
                                                weight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: TextButton.icon(
                    onPressed: _openExternally,
                    icon: Icon(Icons.open_in_new, size: 16, color: Surfaces.muted(dark)),
                    label: Text('Trouble with the form above? Open it directly',
                        style: body(12.5, Surfaces.muted(dark))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
