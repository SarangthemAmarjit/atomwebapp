import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:ots_new_kit/mobile.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'atom_pay_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({
    Key? key,
  }) : super(key: key);

  @override
  createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewXController _webviewController;

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
      navigationDelegate: (request) {
        if (request.content.source.contains('mobile')) {
          print('Trying to open Mobile');
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const MobilePage())); // Close current window
          return NavigationDecision.prevent; // Prevent opening url
        } else if (request.content.source.contains('youtube.com')) {
          print('Trying to open Youtube');
          return NavigationDecision.navigate; // Allow opening url
        } else {
          return NavigationDecision.navigate; // Default decision
        }
      },
      initialContent:
          'https://paynetzuat.atomtech.in/ots/payment/txn?merchId=9273&encData=EEFE91104888339DC842075EDBBCC10D9E9FBE7D6E995F62D2AC79802CA4579D39E92D34530E3EB547638BF7B78D3E5264E192CE1906B5EDE017ACF0B8626AC6E34A20D72739ED85574A2C957008E4C702C93585EF8CCA4D640C4CC969ADC67C54CCCA4D1C4CF0378AE0DADCBF09BE99AF095F84F412AEE72243EE565910EA130CF6782CE7516EFD02592B4B8E7094160AF3BD1423974425446AF506EAF469C06A51FA887DD0303353E4C5FA215787241D338BC90DC73745A929463CA397C175BAB268D1A68BE767AF27ED56BD83BD224F713CE480B1F54EB2D0E782FE7469FC72CF2D7C4437326236447C6ECBAECE19458BBE3EE58C9E628B7689196A899A2E02C2508AF43C522C307B2E5DFFA26637B361A536F6DAA15E926E9A812F0491CA02BE4C4D778C628A801C8121F87D35D1A9197536F509B821C5B9AA14E563B74062AE4741D9E962934385CA31E0E8193F874D1403B43FA9D40DE9A8189399030DDC2C25E015BC0D8267A20D5A3AA4788DC1FCA2EBB182DA284F33C92A3C4D6DA7C5A00EF7B6B0CEC466E3A554A27F5A50',
      initialSourceType: SourceType.urlBypass,
      javascriptMode: JavascriptMode.unrestricted,
      webSpecificParams: const WebSpecificParams(
        printDebugInfo: true,
      ),
      // navigationDelegate: (NavigationRequest request) async {
      //   log('NavigationRequest ' + request.content.source);
      //   if (request.content.source.startsWith("upi://")) {
      //     debugPrint("upi url started loading");
      //     try {
      //       // ignore: deprecated_member_use
      //       await launch(request.content.source);
      //     } catch (e) {
      //       _closeWebView(
      //           context, "Transaction Status = cannot open UPI applications");
      //       throw 'custom error for UPI Intent';
      //     }
      //     return NavigationDecision.prevent;
      //   }
      //   return NavigationDecision.navigate;
      // },
      onWebViewCreated: (controller) {
        _webviewController = controller;
        _loadHtmlFromAssets();
      },
      onPageStarted: (String url) async {
        log(url);
      },
      onPageFinished: (String url) {
        log(url);
      },
      width: screenWidth,
      height: screenHeight,
    );
  }

  _loadHtmlFromAssets() async {
    _webviewController.loadContent(
        URLRequest(
                url: Uri.parse(
                    'https://paynetzuat.atomtech.in/ots/payment/txn?merchId=9273&encData=EEFE91104888339DC842075EDBBCC10D9E9FBE7D6E995F62D2AC79802CA4579D39E92D34530E3EB547638BF7B78D3E5264E192CE1906B5EDE017ACF0B8626AC6E34A20D72739ED85574A2C957008E4C702C93585EF8CCA4D640C4CC969ADC67C54CCCA4D1C4CF0378AE0DADCBF09BE99AF095F84F412AEE72243EE565910EA130CF6782CE7516EFD02592B4B8E7094160AF3BD1423974425446AF506EAF469C06A51FA887DD0303353E4C5FA215787241D338BC90DC73745A929463CA397C175BAB268D1A68BE767AF27ED56BD83BD224F713CE480B1F54EB2D0E782FE7469FC72CF2D7C4437326236447C6ECBAECE19458BBE3EE58C9E628B7689196A899A2E02C2508AF43C522C307B2E5DFFA26637B361A536F6DAA15E926E9A812F0491CA02BE4C4D778C628A801C8121F87D35D1A9197536F509B821C5B9AA14E563B74062AE4741D9E962934385CA31E0E8193F874D1403B43FA9D40DE9A8189399030DDC2C25E015BC0D8267A20D5A3AA4788DC1FCA2EBB182DA284F33C92A3C4D6DA7C5A00EF7B6B0CEC466E3A554A27F5A50'))
            .toString(),
        headers: {
          "Access-Control-Allow-Origin":
              "*", // Required for CORS support to work
          "Access-Control-Allow-Credentials":
              "true", // Required for cookies, authorization headers with HTTPS
          "Access-Control-Allow-Headers":
              "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
          "Access-Control-Allow-Methods": "POST, OPTIONS"
        },
        sourceType: SourceType.urlBypass);
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
