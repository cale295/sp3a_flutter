// lib/screens/pelanggan/midtrans_payment_screen.dart
// Full-screen WebView that displays the Midtrans Snap payment page.
// Detects payment completion via NavigationDelegate URL pattern matching.

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_colors.dart';

/// The outcome of the Midtrans Snap payment flow.
enum MidtransPaymentResult {
  /// Payment completed successfully (settlement/capture).
  success,

  /// User cancelled or payment was pending/expired.
  cancelled,

  /// An error occurred during payment.
  error,
}

/// Full-screen WebView screen for the Midtrans Snap payment UI.
///
/// Usage:
/// ```dart
/// final result = await Navigator.push<MidtransPaymentResult>(
///   context,
///   MaterialPageRoute(
///     builder: (_) => MidtransPaymentScreen(redirectUrl: url),
///   ),
/// );
/// ```
class MidtransPaymentScreen extends StatefulWidget {
  /// The Snap redirect URL returned by the `create-transaction` Edge Function.
  final String redirectUrl;

  const MidtransPaymentScreen({super.key, required this.redirectUrl});

  @override
  State<MidtransPaymentScreen> createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasPopped = false; // Guard against popping multiple times


  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              '[MidtransPaymentScreen] WebResource error: '
              '${error.errorCode} — ${error.description}',
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            final rawUrl = request.url;
            final url = rawUrl.toLowerCase();
            debugPrint('[MidtransPaymentScreen] Navigating to: $rawUrl');

            // ── PRIMARY: Intercept example.com redirect ───────────────────────────
            // Midtrans is configured to redirect to https://example.com when
            // the payment flow ends. We intercept this, show a Snackbar,
            // and pop the screen — without loading the dummy website.
            final isExampleRedirect =
                url.startsWith('https://example.com') ||
                url.startsWith('http://example.com');

            if (isExampleRedirect) {
              debugPrint(
                '[MidtransPaymentScreen] Intercepted example.com redirect. '
                'Payment flow ended. URL: $rawUrl',
              );

              // Extract transaction_status query param if Midtrans appended it.
              String? transactionStatus;
              try {
                transactionStatus =
                    Uri.parse(rawUrl).queryParameters['transaction_status'];
                debugPrint(
                  '[MidtransPaymentScreen] transaction_status='
                  '"$transactionStatus"',
                );
              } catch (_) {
                debugPrint('[MidtransPaymentScreen] Could not parse query params.');
              }

              _popWithSnackbar(transactionStatus: transactionStatus);
              return NavigationDecision.prevent;
            }

            // ── SECONDARY: Standard Snap /finish URL patterns (fallback) ───────
            final isSnapFinish = url.contains('/finish') ||
                url.contains('/unfinish') ||
                url.contains('/error');

            if (isSnapFinish) {
              debugPrint(
                '[MidtransPaymentScreen] Snap finish URL detected: $rawUrl',
              );
              final hasCancelled = url.contains('unfinish') ||
                  url.contains('cancel') ||
                  url.contains('deny') ||
                  url.contains('expire');
              final hasError = url.contains('/error');

              MidtransPaymentResult result;
              if (hasError) {
                result = MidtransPaymentResult.error;
              } else if (hasCancelled) {
                result = MidtransPaymentResult.cancelled;
              } else {
                result = MidtransPaymentResult.success;
              }

              debugPrint('[MidtransPaymentScreen] Snap result: $result');
              _popWithResult(result);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  /// Pops with a typed [MidtransPaymentResult] (used by the Snap /finish fallback
  /// and by the manual close button).
  void _popWithResult(MidtransPaymentResult result) {
    if (_hasPopped || !mounted) return;
    _hasPopped = true;
    Navigator.of(context).pop(result);
  }

  /// Pops with `true` and shows an informational Snackbar.
  /// Used when the example.com redirect is intercepted: the payment was submitted
  /// but settlement is confirmed asynchronously by the Midtrans webhook.
  void _popWithSnackbar({String? transactionStatus}) {
    if (_hasPopped || !mounted) return;
    _hasPopped = true;

    // Capture messenger BEFORE the async gap (required by use_build_context_synchronously).
    final messenger = ScaffoldMessenger.maybeOf(context);

    // Pop first so the parent screen is visible before the Snackbar appears.
    Navigator.of(context).pop(true);

    // Short delay to let the parent scaffold become active.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (messenger == null) return;

      messenger.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pembayaran sedang diproses, silakan cek status tagihan '
                  'secara berkala.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  void _onClosePressed() {
    _popWithResult(MidtransPaymentResult.cancelled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Tutup Pembayaran',
          onPressed: _onClosePressed,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: AppColors.primary,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembayaran Aman',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Powered by Midtrans',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: AnimatedOpacity(
            opacity: _isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: LinearProgressIndicator(
              backgroundColor: AppColors.primary.withAlpha(20),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 3,
            ),
          ),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
