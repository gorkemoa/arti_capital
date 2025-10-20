import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_colors.dart';

class DocumentViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const DocumentViewerPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Döküman yüklenemedi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                      });
                      _controller.reload();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: AppColors.background,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _loadingProgress > 0 ? _loadingProgress : null,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Yükleniyor...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurface.withOpacity(0.6),
                          ),
                    ),
                    if (_loadingProgress > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '%${(_loadingProgress * 100).toInt()}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurface.withOpacity(0.4),
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
