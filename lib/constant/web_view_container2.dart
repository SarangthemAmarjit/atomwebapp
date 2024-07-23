import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ots_new_kit/atom_pay_helper.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

class WebViewContainerPage extends StatefulWidget {
  final mode;
  final payDetails;
  final responsehashKey;
  final responseDecryptionKey;
  const WebViewContainerPage(this.mode, this.payDetails, this.responsehashKey,
      this.responseDecryptionKey,
      {Key? key})
      : super(key: key);
  @override
  createState() => _WebViewContainerPageState(
      mode, payDetails, responsehashKey, responseDecryptionKey);
}

class _WebViewContainerPageState extends State<WebViewContainerPage> {
  final mode;
  final payDetails;
  final _responsehashKey;
  final _responseDecryptionKey;
  final _key = UniqueKey();
  late WebViewController _controller;

  final Completer<WebViewController> _controllerCompleter =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
  }

  _WebViewContainerPageState(this.mode, this.payDetails, this._responsehashKey,
      this._responseDecryptionKey);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _handleBackButtonAction(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0,
          toolbarHeight: 2,
        ),
        body: SafeArea(
            child: WebView(
          key: UniqueKey(),
          initialUrl: 'about:blank',
          onWebViewCreated: (WebViewController webViewController) {
            _controllerCompleter.future.then((value) => _controller = value);
            _controllerCompleter.complete(webViewController);
            debugPrint("payDetails from webview $payDetails");
            _loadHtmlFromAssets(mode);
          },
          navigationDelegate: (NavigationRequest request) async {
            if (request.url.startsWith("upi://")) {
              debugPrint("upi url started loading");
              try {
                // ignore: deprecated_member_use
                await launch(request.url);
              } catch (e) {
                _closeWebView(context,
                    "Transaction Status = cannot open UPI applications");
                throw 'custom error for UPI Intent';
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          javascriptMode: JavascriptMode.unrestricted,
          onPageFinished: (String url) async {
            if (url.contains("AIPAYLocalFile")) {
              debugPrint(" AIPAYLocalFile Now url loaded: $url");
              await _controller.runJavascriptReturningResult(
                  "openPay('" + payDetails + "')");
            }

            if (url.contains('/mobilesdk/param')) {
              final response = await _controller.runJavascriptReturningResult(
                  "document.getElementsByTagName('h5')[0].innerHTML");
              debugPrint("HTML response : $response");
              var transactionResult = "";
              if (response.trim().contains("cancelTransaction")) {
                transactionResult = "Transaction Cancelled!";
              } else {
                final split = response.trim().split('|');
                final Map<int, String> values = {
                  for (int i = 0; i < split.length; i++) i: split[i]
                };

                final splitTwo = values[1]!.split('=');
                const platform = MethodChannel('flutter.dev/NDPSAESLibrary');

                try {
                  final String result =
                      await platform.invokeMethod('NDPSAESInit', {
                    'AES_Method': 'decrypt',
                    'text': splitTwo[1].toString(),
                    'encKey': _responseDecryptionKey
                  });
                  var respJsonStr = result.toString();
                  Map<String, dynamic> jsonInput = jsonDecode(respJsonStr);
                  debugPrint("read full respone : $jsonInput");

                  //calling validateSignature function from atom_pay_helper file
                  var checkFinalTransaction =
                      validateSignature(jsonInput, _responsehashKey);

                  if (checkFinalTransaction) {
                    if (jsonInput["payInstrument"]["responseDetails"]
                                ["statusCode"] ==
                            'OTS0000' ||
                        jsonInput["payInstrument"]["responseDetails"]
                                ["statusCode"] ==
                            'OTS0551') {
                      debugPrint("Transaction success");
                      transactionResult = "Transaction Success";
                    } else {
                      debugPrint("Transaction failed");
                      transactionResult = "Transaction Failed";
                    }
                  } else {
                    debugPrint("signature mismatched");
                    transactionResult = "failed";
                  }
                  debugPrint("Transaction Response : $jsonInput");
                } on PlatformException catch (e) {
                  debugPrint("Failed to decrypt: '${e.message}'.");
                }
              }
              _closeWebView(context, transactionResult);
            }
          },
          gestureNavigationEnabled: true,
        )),
      ),
    );
  }

  _loadHtmlFromAssets(mode) async {
    final localUrl =
        mode == 'uat' ? "assets/aipay_uat.html" : "assets/aipay_prod.html";
    String fileText = await rootBundle.loadString(localUrl);
    _controller.loadUrl(
      Uri.dataFromString(fileText,
              mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
          .toString(),
      headers: {
        "Access-Control-Allow-Origin": "*", // Required for CORS support to work
        "Access-Control-Allow-Credentials":
            "true", // Required for cookies, authorization headers with HTTPS
        "Access-Control-Allow-Headers":
            "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
        "Access-Control-Allow-Methods": "POST, OPTIONS"
      },
    );
  }

  _closeWebView(context, transactionResult) {
    // ignore: use_build_context_synchronously
    Navigator.pop(context); // Close current window
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transaction Status = $transactionResult")));
  }

  Future<bool> _handleBackButtonAction(BuildContext context) async {
    debugPrint("_handleBackButtonAction called");
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Do you want to exit the payment ?'),
              actions: <Widget>[
                // ignore: deprecated_member_use
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('No'),
                ),
                // ignore: deprecated_member_use
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pop(); // Close current window
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "Transaction Status = Transaction cancelled")));
                  },
                  child: const Text('Yes'),
                ),
              ],
            ));
    return Future.value(true);
  }
}
