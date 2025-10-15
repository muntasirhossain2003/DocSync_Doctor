import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Web-specific implementation using HTML video elements
class WebVideoViewImpl extends StatefulWidget {
  final int uid;
  final bool isLocal;

  const WebVideoViewImpl({super.key, required this.uid, this.isLocal = false});

  @override
  State<WebVideoViewImpl> createState() => _WebVideoViewImplState();
}

class _WebVideoViewImplState extends State<WebVideoViewImpl> {
  late final String viewId;

  @override
  void initState() {
    super.initState();
    viewId = 'agora-video-${widget.isLocal ? 'local' : 'remote'}-${widget.uid}';

    // Register the view factory for web
    // The actual video element will be injected by Agora Web SDK
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final element = html.DivElement()
        ..id = this.viewId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      return element;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: viewId);
  }
}
