import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

void registerwebimplementation() {
  ui_web.platformViewRegistry.registerViewFactory('', (int viewId) {
    final html.Element htmlElement = html.DivElement()
      // ..other props
      ..style.width = '100%'
      ..style.height = '100%';
    // ...
    return htmlElement;
  });
  WebView.platform = WebWebViewPlatform();
}
