import 'package:bige/common/global.dart';
import 'package:bige/download.dart';
import 'package:bige/provider/platform.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

void main() {
  Global.init().then(
    (e) => {
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => MirrorProvider()),
          ],
          child: const MyApp(),
        ),
      ),
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BiGe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Download(),
    );
  }
}
