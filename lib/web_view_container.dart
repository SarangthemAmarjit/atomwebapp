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
      initialContent: 'http://10.10.1.44:80/',
      initialSourceType: SourceType.url,
      onWebViewCreated: (controller) {
        _webviewController = controller;
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

  // _loadHtmlFromAssets(String mode) {
  //   // final localUrl = mode == 'uat'
  //   //     ? "assets/payment/aipay_uat.html"
  //   //     : "assets/payment/aipay_prod.html";
  //   // String fileText = await rootBundle.loadString(localUrl);
  //   _webviewController.loadContent(
  //       "https://paynetzuat.atomtech.in/ots/payment/txn?merchId=9132&encData=582BAC98DB50B7B7465FEC80C84D6FA18F6D1CC00C98351348C5A40EDD068EB8D709BB8926395F15EEBC9480BAC3143BE26847B0CB657459D094BB024E3781759BC6204780A5BCE595226841911223EA336605F87C853E9E249C51614153D530F85D3106076E573EE7077560EBFDD89BFC8B94C3F5FF14F74A8A39E25FEA7C6C2E7BAE438FFB7A4D34D9A2CA7BCD046216EAAB9F85A5C4F8596823E197090E7128872CA1C2815E7AACCDB1CE30500B70ED152C7BBBD2D9783449597FE1073E85D28E1383B892CACFA82D9F1E2B19D9A419EED7E77F7F53CBAD8858115E4C34F88427966B80572AFC682B8610B6DE96A3BA4F35E4C0A5F78E35B1FE789B211C53B581748EFFF84DE2D1ACBD5302781B819756441327C7EDA92125AC99D8502B8C93BBB88B35803C8C27B4D07B1E6F827D3D47E6DFBDC18651336C11E614CBA7D7B29D4E6DE5756B277B746C8270D53424E667035C9039E078C30684ADB103D0617D4536668A91EF61A9F871CAEB7E4831BB24DF4DB7A9720EE6BCC0ADF1CFFDC3F3EEB6F09F45659CA46B18DD6014CAB48B5084E2762B5D3F509E6419EF0FD7BBD682B03E154FC51FAC3732C37EDA59DD5874D656AC78BDF27CF788DA6061B9C326ED818A55BFAC9ACADEA3470102E31621305B4D70578F68BC4813833E8888DD4548A1582E97CCCCF60F08E6D0D9209FD7C1765E66899B7BB680DA4EE246195B4346A6254786832A333713842B64ADB29FEC24452DFFB63D5C7091634B81637DE588940E18725901915ACAA407226CBE71DC31870B59BE18E966F4063AF3A0B5FF795D9BB65B768EB7004C588B1ADB4523D013EF35E2D565CDFA4201B03B57208A822BC4D3FFB04F51BA119032E5130DA103EACC50C21C654B8F7C14559945623CF6DCB50E923B4E40429969880028549277279EA3173B58ED68D589C57F70E08D59089B257F00809DA007276AE2BD43E12586FBD5E25830EFD39593C9BAA87F53198484C05634169D26F39459BC58EC812F96D1681DA4E14D8A913BF97C06FF1226D01E357481A00ED086ED3C3B58520809D59867A54EE3B7D9C35B2DFC899F0E79C88B2371D4F31CAA1FE7412CF336F6F15681123A5C91845BD8DDE98C7E8331A23F62175D2A0FAC053948AA170442DA729942D3980C750BCA63DD73D22B9D5D0CFA8BCD4EF60DCC59D7047D2368EB0FDCFAE671C737A9DF7A2D03378DC3DAC644DBB2A1AB6AA05123426D91B1EDAE7DB455C78E7493DE064147EB451E1549C97C5947A41C66B083666018590AA340",
  //       headers: {
  //         "Access-Control-Allow-Origin":
  //             "*", // Required for CORS support to work
  //         "Access-Control-Allow-Credentials":
  //             "true", // Required for cookies, authorization headers with HTTPS
  //         "Access-Control-Allow-Headers":
  //             "Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale",
  //         "Access-Control-Allow-Methods": "POST, OPTIONS"
  //       },
  //       sourceType: SourceType.urlBypass);
  // }

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
