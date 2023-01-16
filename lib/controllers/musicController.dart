// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:player/data.dart';
import 'package:player/models/music.dart';

class MusicController extends GetxController {
  double MusicItemHeight = 80;

  List<Music> list = <Music>[].obs;
  Rx<Music> playMusic = Music().obs;
  RxInt playIndex = 0.obs;
  final isPlaying = false.obs;

  AudioPlayer audioPlayer = AudioPlayer();
  Duration playProcess = const Duration();
  Duration totalProcess = const Duration();
  PlayerState playerState = PlayerState.stopped;

  @override
  void onInit() {
    super.onInit();

    // 生成列表
    for (var element in jsonDecode(getJsonData())) {
      list.add(Music.fromJson(element));
    }

    // audio player
    audioPlayer.onDurationChanged.listen((Duration d) {
      totalProcess = d;
    });

    audioPlayer.onPositionChanged.listen((Duration d) {
      playProcess = d;
    });

    audioPlayer.onPlayerComplete.listen((event) {
      log("播放完成");
      next();
    });
  }

  void play(int i) async {
    log("play... ${list[i].name}");
    playIndex(i);
    playMusic(list[i]);
    playerState = PlayerState.playing;
    isPlaying(true);
    await audioPlayer.play(UrlSource(list[i].url));
  }

  void pause() async {
    log("pause...  ${list[playIndex.value].name}");
    playerState = PlayerState.paused;
    isPlaying(false);
    await audioPlayer.pause();
  }

  void stop() async {
    log("stop... ${list[playIndex.value].name}");
    playerState = PlayerState.stopped;
    isPlaying(false);
    await audioPlayer.stop();
  }

  void resume() async {
    log("resume... ${list[playIndex.value].name}");
    playerState = PlayerState.playing;
    isPlaying(true);
    await audioPlayer.resume();
  }

  void release() async {
    log("release... ${list[playIndex.value].name}");
    playerState = PlayerState.completed;
    isPlaying(false);
    await audioPlayer.release();
  }

  void prev() async {
    playIndex -= 1;
    if (playIndex < 0) {
      playIndex(0);
    }
    playMusic(list[playIndex()]);
    log("prev... ${playMusic.value.name}");
    playerState = PlayerState.playing;
    isPlaying(true);
    await audioPlayer.play(UrlSource(playMusic.value.url));
  }

  void next() async {
    playIndex += 1;
    if (playIndex > list.length - 1) {
      playIndex(0);
    }
    playMusic(list[playIndex()]);
    log("next... ${playMusic.value.name}");
    playerState = PlayerState.playing;
    isPlaying(true);
    await audioPlayer.play(UrlSource(playMusic.value.url));
  }
}
