import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:player/pages/home.dart';

Future<void> main() async {
  await JustAudioBackground.init(
    // androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelId: 'com.bige365.player',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    artDownscaleHeight: 50,
    artDownscaleWidth: 50,
    // androidNotificationIcon: "assets/lizhi.png",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle =
          const SystemUiOverlayStyle(statusBarColor: Colors.transparent);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    return GetMaterialApp(
      title: '播放器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}
