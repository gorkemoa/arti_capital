import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' show Offset, Rect;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

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
  String? _downloadedFilePath;

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

  Future<String> _getLocalSavePath() async {
    final dir = await getTemporaryDirectory();
    final fileName = widget.url.split('/').last.split('?').first;
    return '${dir.path}/$fileName';
  }

  Future<String> _ensureDownloaded() async {
    if (_downloadedFilePath != null && await File(_downloadedFilePath!).exists()) {
      return _downloadedFilePath!;
    }
    final savePath = await _getLocalSavePath();
    final file = File(savePath);
    if (!await file.exists()) {
      final dio = Dio();
      await dio.download(widget.url, savePath);
    }
    _downloadedFilePath = savePath;
    return savePath;
  }

  Future<void> _share() async {
    try {
      final path = await _ensureDownloaded();
      final box = context.findRenderObject() as RenderBox?;
      final origin = (box != null)
          ? (box.localToGlobal(Offset.zero) & box.size)
          : const Rect.fromLTWH(0, 0, 1, 1);
      await Share.shareXFiles(
        [XFile(path)],
        sharePositionOrigin: origin,
        text: widget.title,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paylaşım sırasında hata: $e')),
      );
    }
  }

  Future<void> _download() async {
    // Android: DownloadManager, iOS: Paylaşım sayfası ile Files'a kaydetme
    const channel = MethodChannel('native_downloader');
    final fileName = widget.url.split('/').last.split('?').first;
    try {
      await channel.invokeMethod('downloadFile', {
        'url': widget.url,
        'fileName': fileName,
        'title': widget.title,
        'description': 'İndiriliyor...'
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İndirme başlatıldı: $fileName')),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Native indirme hatası: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İndirme sırasında hata: $e')),
      );
    }
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


