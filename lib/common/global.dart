import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Global {
  static late SharedPreferences _prefs;
  static String platformVal = "android";
  static double musicItemHeight = 80;
  static String mirrorVal = "jsdelivr";

  //初始化全局信息，会在APP启动时执行
  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();
    _prefs = await SharedPreferences.getInstance();

    if (Platform.isAndroid) {
      platformVal = TargetPlatform.android.toString();
      musicItemHeight = 80;
    }

    if (Platform.isIOS) {
      platformVal = TargetPlatform.iOS.toString();
      musicItemHeight = 80;
    }

    String? mirrorVal = _prefs.getString("mirror");
    mirrorVal = mirrorVal ?? "jsdelivr";
  }

  static setMirror(String mirrorVal) {
    if (platformVal.isNotEmpty) {
      _prefs.setString("mirror", mirrorVal);
    } else {
      _prefs.setString("mirror", "jsdelivr");
    }
  }

  static getMirror() {
    return _prefs.getString("mirror") ?? "jsdelivr";
  }
}
