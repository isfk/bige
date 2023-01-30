import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:player/common/utils.dart';
import 'package:player/data.dart';
import 'package:player/models/music.dart';

class MusicController extends GetxController {
  double musicItemHeight = 80;

  List<Music> list = <Music>[].obs;
  Rx<Music> playMusic = Music().obs;
  RxInt playIndex = 0.obs;
  final isPlaying = false.obs;
  final isLoading = false.obs;

  RxString loopMode = "all".obs;
  RxBool shuffleMode = true.obs;

  Rx<AudioPlayer> audioPlayer = AudioPlayer().obs;
  Rx<Duration> playPosition = const Duration().obs;
  Rx<Duration> playDuration = const Duration().obs;
  RxDouble playProcess = (0.0).obs;
  RxDouble totalProcess = (0.0).obs;

  List<AudioSource> mediaList = [];

  // 下载相关
  var destBasePath = "".obs;
  var chunk = 5;
  var downloading = false.obs;
  var downloadingIndex = 0.obs;
  var downloadingIndexShow = 1.obs;
  var downloadingMsg = "".obs;
  var cancelToken = CancelToken().obs;

  List<int> chunkCountAll = [0, 0, 0, 0, 0];

  @override
  Future<void> onInit() async {
    super.onInit();
    // 列表
    list = getMusics();

    // 播放列表
    var futures = <Future>[];

    futures.add(checkMusics());
    await Future.wait(futures);
    // 下载路径
    getMusicPath(type: 1).then((value) {
      destBasePath(value);
    });

    // 播放器设置
    audioPlayer().setLoopMode(LoopMode.all);
    audioPlayer().setShuffleModeEnabled(shuffleMode());
    audioPlayer().setAudioSource(
      ConcatenatingAudioSource(children: mediaList),
      initialIndex: 0,
      initialPosition: Duration.zero,
    );

    // 播放器监听
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
    audioPlayer().currentIndexStream.listen((index) {
      if (index != null) {
        playIndex(index);
        var temp = list[index];
        log(temp.url);
        temp.cover = getCoverPng(temp.artist);
        playMusic(temp);
      }
    });
    audioPlayer().durationStream.listen((duration) {
      playDuration(duration);
    });
    audioPlayer().positionStream.listen((position) {
      playPosition(position);
      playProcess(position.inSeconds / playDuration().inSeconds);
    });
    audioPlayer().durationStream.listen((duration) {});
    audioPlayer().shuffleModeEnabledStream.listen((shuffle) {
      log("shuffleModeEnabledStream: $shuffle");
    });
  }

  Future<void> checkMusics() async {
    var findI = false;
    var ok = await checkPermission();
    for (var i = 0; i < list.length; i++) {
      var m = list[i];
      if (ok) {
        if (await isMusicExists(m.url)) {
          m.url = await getDestFilePath(m.url);
          addAudioSource(m);
          list[i] = m;
          continue;
        }
      }

      m.download = "在线播放";
      addAudioSource(m);
      list[i] = m;

      if (findI) continue;

      findI = true;
      downloadingIndex(i);
      downloadingIndexShow(i + 1);
      log("i ... $i");
    }
  }

  void addAudioSource(Music music) {
    if (music.url.contains("https://")) {
      log(music.url);
      mediaList.add(
        AudioSource.uri(
          Uri.parse(music.url),
          tag: MediaItem(
            id: music.url,
            title: music.name,
            album: music.artist,
            displayTitle: music.name,
            displaySubtitle: music.artist,
            displayDescription: "我们不能失去信仰",
            artUri: Uri.parse(music.cover),
          ),
        ),
      );
    } else {
      mediaList.add(
        AudioSource.uri(
          Uri.file(music.url),
          tag: MediaItem(
            id: music.url,
            title: music.name,
            album: music.artist,
            displayTitle: music.name,
            displaySubtitle: music.artist,
            displayDescription: "我们不能失去信仰",
            artUri: Uri.parse(music.cover),
          ),
        ),
      );
    }
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
              color: Color.fromARGB(150, 0, 0, 0),
            ),
          ),
          Positioned(
            left: 14,
            top: -1,
            child: Container(
              margin: const EdgeInsets.only(top: 15),
              width: 47.0,
              height: 47.0,
              child: const CircularProgressIndicator(
                color: Colors.blue,
              ),
            ),
          ),
        ],
      );
    } else if (isPlaying() == true) {
      return Stack(
        children: [
          Positioned(
            left: 14,
            top: -1,
            child: Container(
              margin: const EdgeInsets.only(top: 15),
              width: 47.0,
              height: 47.0,
              child: CircularProgressIndicator(
                color: Colors.blue,
                value: playProcess(),
              ),
            ),
          ),
          IconButton(
            iconSize: 60,
            onPressed: () => pause(),
            icon: const Icon(
              CupertinoIcons.pause_circle,
              color: Color.fromARGB(120, 0, 0, 0),
            ),
          )
        ],
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

  void startDownload({int i = 0, bool restart = false}) async {
    checkPermission().then((value) {
      if (value) {
        if (i >= list.length) {
          downloadingIndex(0);
          downloadingIndexShow(list.length);
          downloading(false);
          downloadingMsg("");
          return;
        }

        cancelToken(CancelToken());
        downloadingIndex(i);
        downloadingIndexShow(i + 1);
        downloading(true);

        // 创建目录
        var saveDir = Directory(destBasePath());
        if (!saveDir.existsSync()) {
          saveDir.createSync();
        }

        Future.delayed(Duration.zero, () {}).then((value) async {
          var music = list[i];

          if (music.download.isEmpty) {
            // 跳过，继续下载
            startDownload(i: ++i);
            return;
          }
          log("${music.name} 开始下载");

          var saveDestPath = await getDestPath(music.artist);
          var saveDestFilePath = await getDestFilePath(music.url);
          var saveTempPath = await getTempPath(music.artist);
          var saveTempFilePath = await getTempFilePath(music.url);
          // log("saveDestPath ... $saveDestPath");
          // log("saveDestFilePath ... $saveDestFilePath");
          // log("saveTempPath ... $saveTempPath");
          // log("saveTempFilePath ... $saveTempFilePath");
          // 创建目录
          try {
            var saveDestDir = Directory(saveDestPath);
            if (!saveDestDir.existsSync()) {
              saveDestDir.createSync();
            }

            var saveTempDir = Directory(saveTempPath);
            if (!saveTempDir.existsSync()) {
              saveTempDir.createSync();
            }
          } catch (e) {
            log(e.toString());
          }

          // 开始下载
          try {
            var total = 0;
            var start = 0;
            var end = 0;

            downloadingMsg("分析中: ${music.name}");

            // 探测文件大小
            total = await getRangeTotal(music.url);
            if (total == 0) return;
            var chunkSize = (total / chunk).ceil();
            end += chunkSize;
            var futures = <Future>[];
            for (var j = 0; j < chunk; j++) {
              if (end > total) end = total;
              var temp = "${saveTempFilePath}_$j";
              var f = File(temp);
              if (f.existsSync() && (f.lengthSync() == chunkSize + 1)) {
                // 存在 大小相同
                chunkCountAll[j] = f.lengthSync();
              } else {
                // 下载 或 重新下载 chunk
                futures
                    .add(downloadChunk(i, j, music, temp, start, end, total));
                chunkCountAll[j] = 0;
              }

              start += chunkSize;
              end += chunkSize;
            }

            await Future.wait(futures);

            // 合并 块
            mergeChunk(chunk, saveTempFilePath, saveDestFilePath);

            music.download = "";
            list[i] = music;

            startDownload(i: ++i);
          } catch (e) {
            log(e.toString());
          }
        });
      } else {}
    });
  }

  void pauseDownload() async {
    cancelToken().cancel("您取消了下载");
    // showToast(context, "当前歌曲下载完停止", duration: 10);
    downloading(false);
    downloadingMsg("逼歌");
  }

  Future downloadChunk(int i, int j, Music music, String tempFile, int start,
      int end, int fileTotal) async {
    return Dio().download(
      music.url,
      tempFile,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: false,
        headers: {
          "range": "bytes=$start-$end",
        },
      ),
      cancelToken: cancelToken(),
      onReceiveProgress: (count, total) {
        if (total == -1) {
          return;
        }

        chunkCountAll[j] = count;

        // 计算进度
        var tt = 0;
        for (var c in chunkCountAll) {
          tt += c;
        }
        var msg = '${(tt / fileTotal * 100).toStringAsFixed(2)}%';
        music.download = msg;
        list[i] = music;
        downloadingMsg("下载中: ${music.name} $msg");
      },
    );
  }
}
