import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:player/common/utils.dart';
import 'package:player/data.dart';
import 'package:player/models/music.dart';

class MusicController extends GetxController {
  double musicItemHeight = 70;

  List<Music> list = <Music>[].obs;
  Rx<ConcatenatingAudioSource> playlist =
      ConcatenatingAudioSource(children: []).obs;

  Rx<Music> playMusic = Music().obs;
  RxInt playIndex = 0.obs;
  final isPlaying = false.obs;
  final isLoading = false.obs;

  Rx<String> loopMode = "all".obs;
  Rx<bool> shuffleMode = false.obs;

  Rx<AudioPlayer> audioPlayer = AudioPlayer().obs;
  Rx<Duration> playPosition = const Duration().obs;
  Duration totalProcess = const Duration();

  List<AudioSource> mediaList = [];

  @override
  void onInit() {
    super.onInit();
    // 生成列表
    for (var element in jsonDecode(getJsonData())) {
      var item = Music.fromJson(element);

      list.add(item);

      mediaList.add(
        AudioSource.uri(
          Uri.parse(item.url),
          tag: MediaItem(
            id: item.url,
            title: item.name,
            album: item.artist,
            displayTitle: item.name,
            displaySubtitle: item.artist,
            displayDescription: "我们不能失去信仰",
            artUri: Uri.parse(item.cover),
          ),
        ),
      );
    }

    audioPlayer().setLoopMode(LoopMode.all);
    audioPlayer().setShuffleModeEnabled(false);
    audioPlayer().setAudioSource(
      ConcatenatingAudioSource(children: mediaList),
      initialIndex: 0,
      initialPosition: Duration.zero,
    );
    audioPlayer().playerStateStream.listen((state) {
      if (state.playing) {
        isPlaying(true);
      } else {
        isPlaying(false);
      }
      switch (state.processingState) {
        case ProcessingState.idle:
          isLoading(false);
          break;
        case ProcessingState.loading:
          isLoading(true);
          break;
        case ProcessingState.buffering:
          isLoading(true);
          break;
        case ProcessingState.ready:
          isLoading(false);
          break;
        case ProcessingState.completed:
          isLoading(false);
          next();
      }
    });
    audioPlayer().currentIndexStream.listen((index) {
      if (index != null) {
        playIndex(index);
        var temp = list[index];
        temp.cover = getCoverPng(temp.artist);
        playMusic(temp);
      }
    });
    audioPlayer().positionStream.listen((position) {
      playPosition(position);
    });
    audioPlayer().durationStream.listen((duration) {});
    audioPlayer().shuffleModeEnabledStream.listen((shuffle) {
      log("shuffleModeEnabledStream: $shuffle");
    });
  }

  void play() async {
    await audioPlayer().seek(playPosition());
    if (isPlaying()) return;
    await audioPlayer().play();
  }

  void pause() async {
    await audioPlayer().pause();
  }

  void stop() async {
    await audioPlayer().stop();
  }

  void prev() async {
    await audioPlayer().seekToPrevious();
  }

  void next() async {
    await audioPlayer().seekToNext();
  }

  void shuffle() async {
    await audioPlayer().shuffle();
    await audioPlayer().setShuffleModeEnabled(true);
  }

  void switchShuffleMode() async {
    if (shuffleMode.value == false) {
      shuffleMode(true);
      await audioPlayer().setShuffleModeEnabled(true);
    } else {
      shuffleMode(false);
      await audioPlayer().setShuffleModeEnabled(false);
    }
  }

  void seek(int index) async {
    await audioPlayer().seek(Duration.zero, index: index);
    if (isPlaying()) return;
    await audioPlayer().play();
  }

  void switchLoopMode() async {
    if (loopMode() == "one") {
      loopMode("all");
      await audioPlayer().setLoopMode(LoopMode.all);
    } else {
      loopMode("one");
      await audioPlayer().setLoopMode(LoopMode.one);
    }
  }

  getControlPlayPause() {
    if (isLoading() == true) {
      return Stack(
        children: [
          IconButton(
            iconSize: 60,
            onPressed: () => play(),
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
        onPressed: () => play(),
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
          onPressed: () => switchShuffleMode(),
          icon: Icon(
            shuffleMode.value == false
                ? CupertinoIcons.shuffle
                : CupertinoIcons.shuffle,
            color: shuffleMode.value == false
                ? const Color.fromARGB(80, 0, 0, 0)
                : const Color.fromARGB(200, 0, 0, 0),
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
          onPressed: () => switchLoopMode(),
          icon: Obx(
            () => Icon(
              loopMode.value == "one"
                  ? CupertinoIcons.repeat_1
                  : CupertinoIcons.repeat,
              color: const Color.fromARGB(200, 0, 0, 0),
            ),
          ),
        ),
      ],
    );
  }
}
