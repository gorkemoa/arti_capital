import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class DocumentPreviewView extends StatefulWidget {
  const DocumentPreviewView({super.key, required this.url, required this.title});
  final String url;
  final String title;

  @override
  State<DocumentPreviewView> createState() => _DocumentPreviewViewState();
}

class _DocumentPreviewViewState extends State<DocumentPreviewView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _share() async {
    await Share.share(widget.url);
  }

  Future<void> _download() async {
    final dir = await getTemporaryDirectory();
    final fileName = widget.url.split('/').last.split('?').first;
    final savePath = '${dir.path}/$fileName';
    final dio = Dio();
    await dio.download(widget.url, savePath);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('İndirildi: $fileName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: _share, icon: const Icon(Icons.ios_share)),
          IconButton(onPressed: _download, icon: const Icon(Icons.download_outlined)),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}


