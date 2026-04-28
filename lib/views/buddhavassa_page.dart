import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BuddhavassaPage extends StatefulWidget {
  const BuddhavassaPage({Key? key}) : super(key: key);

  @override
  State<BuddhavassaPage> createState() => _BuddhavassaPageState();
}

class _BuddhavassaPageState extends State<BuddhavassaPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadFlutterAsset('buddhavassa/index.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buddhist Era'),
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
