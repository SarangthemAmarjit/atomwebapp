import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ots_new_kit/js_interop.dart';
import 'web_view_container.dart';
import 'atom_pay_helper.dart';
import 'package:http/http.dart' as http;

class Home extends StatelessWidget {
  // merchant configuration data
  final String login = "317159"; //mandatory
  final String password = 'Test@123'; //mandatory
  final String prodid = 'NSE'; //mandatory
  final String requestHashKey = 'KEY1234567234'; //mandatory
  final String responseHashKey = 'KEYRESP123657234'; //mandatory
  final String requestEncryptionKey =
      'A4476C2062FFA58980DC8F79EB6A799E'; //mandatory
  final String responseDecryptionKey =
      '75AEF0FA1B94B3C10D4F5B268F757F11'; //mandatory
  final String txnid =
      'test240223'; // mandatory // this should be unique each time
  final String clientcode = "NAVIN"; //mandatory
  final String txncurr = "INR"; //mandatory
  final String mccCode = "5499"; //mandatory
  final String merchType = "R"; //mandatory
  final String amount = "1.00"; //mandatory

  final String mode = "uat"; // change live for production

  final String custFirstName = 'test'; //optional
  final String custLastName = 'user'; //optional
  final String mobile = '8888888888'; //optional
  final String email = 'test@gmail.com'; //optional
  final String address = 'mumbai'; //optional
  final String custacc = '639827'; //optional
  final String udf1 = "udf1"; //optional
  final String udf2 = "udf2"; //optional
  final String udf3 = "udf3"; //optional
  final String udf4 = "udf4"; //optional
  final String udf5 = "udf5"; //optional

  final String authApiUrl = "https://caller.atomtech.in/ots/aipay/auth"; // uat

  // final String auth_API_url =
  //     "https://payment1.atomtech.in/ots/aipay/auth"; // prod

  final String returnUrl =
      "https://pgtest.atomtech.in/mobilesdk/param"; //return url uat
  // final String returnUrl =
  //     "https://payment.atomtech.in/mobilesdk/param"; ////return url production

  final String payDetails = '';

  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NDPS Sample App'),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _initNdpsPayment(
                  context, responseHashKey, responseDecryptionKey),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }

  void _initNdpsPayment(BuildContext context, String responseHashKey,
      String responseDecryptionKey) {
    _getEncryptedPayUrl(context, responseHashKey, responseDecryptionKey);
  }

  _getEncryptedPayUrl(context, responseHashKey, responseDecryptionKey) async {
    String reqJsonData = _getJsonPayloadData();
    debugPrint(reqJsonData);

    try {
      // final String result = js.context.callMethod(
      //     'initAES', ["encrypt", reqJsonData, requestEncryptionKey]);

      String encryptedText =
          await getAtomEncryption(reqJsonData, requestEncryptionKey);

      log('authEncryptedString :' + encryptedText);
      // here is result.toString() parameter you will receive encrypted string
      // debugPrint("generated encrypted string: '$authEncryptedString'");
      _getAtomTokenId(context, encryptedText);
    } catch (e) {
      debugPrint("Failed to get encryption string: '$e'.");
    }
  }

  _getAtomTokenId(context, authEncryptedString) async {
    final url = Uri.parse('https://caller.atomtech.in/ots/aipay/auth');
    final headers = {
      "Access-Control-Allow-Origin": "*", // Required for CORS support to work
      // Required for cookies, authorization headers with HTTPS
      "Access-Control-Allow-Methods": "GET,PUT,POST,DELETE,PATCH,OPTIONS"
    };
    final body = jsonEncode({
      'encData': authEncryptedString,
      'merchId': '9273',
    });
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );
      // request.bodyFields = {'encData': authEncryptedString, 'merchId': login};

      if (response.statusCode == 200) {
        var authApiResponse = response.toString();

        final split = authApiResponse.trim().split('&');
        final Map<int, String> values = {
          for (int i = 0; i < split.length; i++) i: split[i]
        };
        final splitTwo = values[1]!.split('=');
        if (splitTwo[0] == 'encData') {
          const platform = MethodChannel('flutter.dev/NDPSAESLibrary');
          try {
            final String result = await platform.invokeMethod('NDPSAESInit', {
              'AES_Method': 'decrypt',
              'text': splitTwo[1].toString(),
              'encKey': responseDecryptionKey
            });
            debugPrint(result.toString()); // to read full response
            var respJsonStr = result.toString();
            Map<String, dynamic> jsonInput = jsonDecode(respJsonStr);
            if (jsonInput["responseDetails"]["txnStatusCode"] == 'OTS0000') {
              final atomTokenId = jsonInput["atomTokenId"].toString();
              debugPrint("atomTokenId: $atomTokenId");
              final String payDetails =
                  '{"atomTokenId" : "$atomTokenId","merchId": "$login","emailId": "$email","mobileNumber":"$mobile", "returnUrl":"$returnUrl"}';
              _openNdpsPG(
                  payDetails, context, responseHashKey, responseDecryptionKey);
            } else {
              debugPrint("Problem in auth API response");
            }
          } on PlatformException catch (e) {
            debugPrint("Failed to decrypt: '${e.message}'.");
          }
        }
      }
    } catch (e) {
      log(e.toString());
    }
  }

  _openNdpsPG(payDetails, context, responseHashKey, responseDecryptionKey) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => WebViewContainer(
                mode, payDetails, responseHashKey, responseDecryptionKey)));
  }

  _getJsonPayloadData() {
    var payDetails = {};
    payDetails['login'] = login;
    payDetails['password'] = password;
    payDetails['prodid'] = prodid;
    payDetails['custFirstName'] = custFirstName;
    payDetails['custLastName'] = custLastName;
    payDetails['amount'] = amount;
    payDetails['mobile'] = mobile;
    payDetails['address'] = address;
    payDetails['email'] = email;
    payDetails['txnid'] = txnid;
    payDetails['custacc'] = custacc;
    payDetails['requestHashKey'] = requestHashKey;
    payDetails['responseHashKey'] = responseHashKey;
    payDetails['requestencryptionKey'] = requestEncryptionKey;
    payDetails['responseencypritonKey'] = responseDecryptionKey;
    payDetails['clientcode'] = clientcode;
    payDetails['txncurr'] = txncurr;
    payDetails['mccCode'] = mccCode;
    payDetails['merchType'] = merchType;
    payDetails['returnUrl'] = returnUrl;
    payDetails['mode'] = mode;
    payDetails['udf1'] = udf1;
    payDetails['udf2'] = udf2;
    payDetails['udf3'] = udf3;
    payDetails['udf4'] = udf4;
    payDetails['udf5'] = udf5;
    String jsonPayLoadData = getRequestJsonData(payDetails);
    return jsonPayLoadData;
  }
}
