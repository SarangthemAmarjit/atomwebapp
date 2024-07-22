import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'atom_pay_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewContainer extends StatefulWidget {
  final String mode;
  final String payDetails;
  final String responsehashKey;
  final String responseDecryptionKey;

  const WebViewContainer(
    this.mode,
    this.payDetails,
    this.responsehashKey,
    this.responseDecryptionKey, {
    Key? key,
  }) : super(key: key);

  @override
  createState() => _WebViewContainerState(
      mode, payDetails, responsehashKey, responseDecryptionKey);
}

class _WebViewContainerState extends State<WebViewContainer> {
  final String mode;
  final String payDetails;
  final String _responsehashKey;
  final String _responseDecryptionKey;
  late WebViewXController _webviewController;

  _WebViewContainerState(this.mode, this.payDetails, this._responsehashKey,
      this._responseDecryptionKey);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return WebViewX(
      initialSourceType: SourceType.html,
      onWebViewCreated: (controller) {
        _webviewController = controller;
        _loadHtmlFromAssets(mode);
      },
      onPageStarted: (String url) async {
        if (url.startsWith("upi://")) {
          debugPrint("upi url started loading");
          try {
            await launch(url);
          } catch (e) {
            _closeWebView(
                context, "Transaction Status = cannot open UPI applications");
            throw 'custom error for UPI Intent';
          }
        }
      },
      onPageFinished: (String url) async {
        if (url.contains("AIPAYLocalFile")) {
          debugPrint("AIPAYLocalFile Now url loaded: $url");
          await _webviewController.callJsMethod("openPay", [payDetails]);
        }

        if (url.contains('/mobilesdk/param')) {
          final response = await _webviewController.callJsMethod(
              "document.getElementsByTagName('h5')[0].innerHTML", []);
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
              final String result = await platform.invokeMethod('NDPSAESInit', {
                'AES_Method': 'decrypt',
                'text': splitTwo[1].toString(),
                'encKey': _responseDecryptionKey
              });
              var respJsonStr = result.toString();
              Map<String, dynamic> jsonInput = jsonDecode(respJsonStr);
              debugPrint("read full response: $jsonInput");

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
              debugPrint("Transaction Response: $jsonInput");
            } catch (e) {
              debugPrint("Failed to decrypt: '$e'.");
            }
          }
          _closeWebView(context, transactionResult);
        }
      },
      width: screenWidth,
      height: screenHeight,
    );
  }
  // _loadHtmlFromAssets(mode) async {
  //   final localUrl = mode == 'uat'
  //       ? "assets/payment/aipay_uat.html"
  //       : "assets/payment/aipay_prod.html";
  //   String fileText = await rootBundle.loadString(localUrl);
  //   _webviewController.loadContent(
  //       urlRequest: URLRequest(
  //           url: Uri.dataFromString(
  //     fileText,
  //     mimeType: 'text/html',
  //     encoding: Encoding.getByName('utf-8'),
  //   )));
  // }

  _loadHtmlFromAssets(String mode) {
    // final localUrl = mode == 'uat'
    //     ? "assets/payment/aipay_uat.html"
    //     : "assets/payment/aipay_prod.html";
    // String fileText = await rootBundle.loadString(localUrl);
    _webviewController.loadContent("assets/payment/aipay_uat.html",
        headers: {
          "Access-Control-Allow-Origin":
              "*", // Required for CORS support to work
          "Access-Control-Allow-Credentials":
              "true", // Required for cookies, authorization headers with HTTPS
          "Access-Control-Allow-Headers":
              "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
          "Access-Control-Allow-Methods": "POST, OPTIONS"
        },
        fromAssets: true,
        sourceType: SourceType.html);
  }

  _closeWebView(BuildContext context, String transactionResult) {
    Navigator.pop(context); // Close current window
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transaction Status = $transactionResult")));
  }

  Future<bool> _handleBackButtonAction(BuildContext context) async {
    debugPrint("_handleBackButtonAction called");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Do you want to exit the payment?'),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pop(); // Close current window
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Transaction Status = Transaction cancelled")));
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return Future.value(true);
  }
}
