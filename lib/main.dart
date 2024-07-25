import 'package:flutter/material.dart';
import 'package:ots_new_kit/constant/registerweb.dart';
import 'home.dart';

void main() {
  registerwebimplementation();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      title: 'Flutter Web Views',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: "Arial",
      ),
      home: Home(),
    );
  }
}
