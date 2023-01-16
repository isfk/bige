// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:get/get.dart';
import 'package:player/data.dart';
import 'package:player/models/music.dart';

class MusicController extends GetxController {
  List<Music> list = <Music>[].obs;

  double MusicItemHeight = 100;

  @override
  void onInit() {
    super.onInit();

    for (var element in jsonDecode(getJsonData())) {
      list.add(Music.fromJson(element));
    }
  }
}
