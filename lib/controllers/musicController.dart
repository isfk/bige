import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:player/data.dart';
import 'package:player/models/music.dart';

class MusicController extends GetxController {
  double musicItemHeight = 80;

  List<Music> list = <Music>[].obs;
  Rx<Music> playMusic = Music().obs;
  RxInt playIndex = 0.obs;
  final isPlaying = false.obs;
  final isLoading = false.obs;

  Rx<AudioPlayer> audioPlayer = AudioPlayer().obs;
  Duration playProcess = const Duration();
  Duration totalProcess = const Duration();

  @override
  void onInit() {
    super.onInit();

    // 生成列表
    for (var element in jsonDecode(getJsonData())) {
      list.add(Music.fromJson(element));
    }

    audioPlayer().playerStateStream.listen((state) {
      if (state.playing) {
        isPlaying(true);
      } else {
        isPlaying(false);
      }
      switch (state.processingState) {
        case ProcessingState.idle:
          log("idle");
          isLoading(false);
          break;
        case ProcessingState.loading:
          log("loading");
          isLoading(true);
          break;
        case ProcessingState.buffering:
          log("buffering");
          isLoading(true);
          break;
        case ProcessingState.ready:
          log("ready");
          isLoading(false);
          break;
        case ProcessingState.completed:
          log("completed");
          isLoading(false);
          next();
      }
    });
  }

  void play(int i) async {
    log("play... ${list[i].name}");
    playIndex(i);
    playMusic(list[i]);
    await setAudioSource();
    await audioPlayer().play();
  }

  void pause() async {
    log("pause...  ${list[playIndex()].name}");
    await audioPlayer().pause();
  }

  void stop() async {
    log("stop... ${list[playIndex()].name}");
    await audioPlayer().stop();
  }

  void prev() async {
    playIndex -= 1;
    if (playIndex < 0) {
      playIndex(0);
    }
    playMusic(list[playIndex()]);
    log("prev... ${playMusic.value.name}");
    await setAudioSource();
    await audioPlayer().play();
  }

  void next() async {
    playIndex += 1;
    if (playIndex > list.length - 1) {
      playIndex(0);
    }
    playMusic(list[playIndex()]);
    log("next... ${playMusic.value.name}");
    await setAudioSource();
    await audioPlayer().play();
  }

  void shuffle() async {
    list.shuffle();
  }

  setAudioSource() async {
    return audioPlayer().setAudioSource(
      AudioSource.uri(
        Uri.parse(playMusic.value.url),
        tag: MediaItem(
          id: "${playIndex()}",
          title: playMusic().name,
          album: playMusic().artist,
          displayTitle: playMusic().name,
          displaySubtitle: playMusic().artist,
          displayDescription: "我们不能失去信仰",
          artUri: Uri.parse(playMusic().cover),
        ),
      ),
    );
  }

  getControlPlayPause() {
    if (isLoading() == true) {
      return Stack(
        children: [
          IconButton(
            iconSize: 60,
            onPressed: () => play(playIndex()),
            icon: const Icon(
              CupertinoIcons.play_circle,
              color: Color.fromARGB(200, 0, 0, 0),
            ),
          ),
          Positioned(
            left: 14,
            top: -1,
            child: Container(
              margin: const EdgeInsets.only(top: 15),
              width: 47.0,
              height: 47.0,
              child: const CircularProgressIndicator(),
            ),
          ),
        ],
      );
    } else if (isPlaying() == true) {
      return IconButton(
        iconSize: 60,
        onPressed: () => pause(),
        icon: const Icon(
          CupertinoIcons.pause_circle,
          color: Color.fromARGB(200, 0, 0, 0),
        ),
      );
    } else {
      return IconButton(
        iconSize: 60,
        onPressed: () => play(playIndex()),
        icon: const Icon(
          CupertinoIcons.play_circle,
          color: Color.fromARGB(200, 0, 0, 0),
        ),
      );
    }
  }

  getControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          iconSize: 30,
          onPressed: () => shuffle(),
          icon: const Icon(
            CupertinoIcons.shuffle,
            color: Color.fromARGB(200, 0, 0, 0),
          ),
        ),
        IconButton(
          iconSize: 30,
          onPressed: () => isLoading() ? null : prev(),
          icon: const Icon(
            CupertinoIcons.backward_fill,
            color: Color.fromARGB(200, 0, 0, 0),
          ),
        ),
        getControlPlayPause(),
        IconButton(
          iconSize: 30,
          onPressed: () => isLoading() ? null : next(),
          icon: const Icon(
            CupertinoIcons.forward_fill,
            color: Color.fromARGB(200, 0, 0, 0),
          ),
        ),
        IconButton(
          iconSize: 30,
          onPressed: () {},
          icon: const Icon(
            CupertinoIcons.music_note_list,
            color: Color.fromARGB(200, 0, 0, 0),
          ),
        ),
      ],
    );
  }
}
