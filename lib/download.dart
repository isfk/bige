import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bige/music.dart';
import 'package:bige/common/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

import 'common/global.dart';

class Download extends StatefulWidget {
  const Download({super.key});

  @override
  State<Download> createState() => _DownloadState();
}

class _DownloadState extends State<Download> {
  String platform = Global.platformVal;

  final ScrollController _controller = ScrollController();
  var destBasePath = "";
  var chunk = 5;
  var loading = true;
  var downloading = false;
  var downloadingI = 0;
  var downloadingMsg = "";
  var cancelToken = CancelToken();

  List<Music> musics = [];
  List<int> chunkCountAll = [0, 0, 0, 0, 0];

  void getMusics() async {
    List<Music> list = [];
    var data = jsonDecode(getJsonStr());
    var firstI = 0;
    for (var d in data) {
      var m = Music.fromJson(d);
      if (await isMusicExists(m.url!)) {
        m.downloaded = "已下载";
      } else {
        m.downloaded = "未下载";
      }
      list.add(m);
    }
    for (var i = 0; i < list.length; i++) {
      if (list[i].downloaded == "未下载") {
        firstI = i;
        break;
      }
    }

    setState(() {
      musics = list;
      loading = false;
      downloadingI = firstI;
    });

    // var url =
    // "https://testingcf.jsdelivr.net/gh/nj-lizhi/song@main/audio/list-v2.js";
    // var dio = Dio();
    // dio
    //     .get(url, options: Options(receiveDataWhenStatusError: true))
    //     .then((resp) {
    //   if (resp.statusCode != 200) {
    //     showToast(context, "请求出错，请重试");
    //     return;
    //   }

    //   var dataStr = resp.data
    //       .toString()
    //       .replaceAll("var list = ", "")
    //       .replaceAll("name:", "\"name\":")
    //       .replaceAll("artist:", "\"artist\":")
    //       .replaceAll("cover:", "\"cover\":")
    //       .replaceAll("url:", "\"url\":")
    //       .replaceAll("cover.png\",", "cover.png\"")
    //       .replaceAll("},\n];", "}\n]");
    //   log(dataStr.toString());
    //   var data = jsonDecode(dataStr);
    //   for (var d in data) {
    //     list.add(Music.fromJson(d));
    //   }
    //   setState(() {
    //     musics = list;
    //     loading = false;
    //   });
    // });
  }

  void startDownload({int i = 0, bool restart = false}) async {
    checkPermission().then((value) {
      if (value) {
        if (i >= musics.length) {
          showToast(context, "所有歌曲下载完成", duration: 10);
          setState(() {
            downloadingI = 0;
            downloading = false;
            downloadingMsg = "";
          });
          return;
        }

        setState(() {
          cancelToken = CancelToken();
          downloading = true;
          downloadingI = i;
        });

        // 创建目录
        var saveDir = Directory(destBasePath);
        if (!saveDir.existsSync()) {
          saveDir.createSync();
        }

        Future.delayed(Duration.zero, () {}).then((value) async {
          var music = musics[i];

          if (music.downloaded == "已下载") {
            // 跳过，继续下载
            startDownload(i: ++i);
            return;
          }
          log("${music.name} 开始下载");

          var saveDestPath = await getDestPath(music.artist!);
          var saveDestFilePath = await getDestFilePath(music.url!);
          var saveTempPath = await getTempPath(music.artist!);
          var saveTempFilePath = await getTempFilePath(music.url!);
          log("saveDestPath ... $saveDestPath");
          log("saveDestFilePath ... $saveDestFilePath");
          log("saveTempPath ... $saveTempPath");
          log("saveTempFilePath ... $saveTempFilePath");
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
            _controller.animateTo(
              i > 0 ? (i - 1) * Global.musicItemHeight : 0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn,
            );

            setState(() {
              downloadingMsg = "分析中: ${music.name}";
            });

            // 探测文件大小
            total = await getRangeTotal(music.url!);
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
              setState(() {
                chunkCountAll = chunkCountAll;
              });
              start += chunkSize;
              end += chunkSize;
            }

            await Future.wait(futures);

            // 合并 块
            mergeChunk(chunk, saveTempFilePath, saveDestFilePath);

            music.downloaded = "已下载";
            musics[i] = music;
            setState(() {
              musics = musics;
            });

            startDownload(i: ++i);
          } catch (e) {
            log(e.toString());
          }
        });
      } else {
        showToast(context, "您没有给媒体权限");
      }
    });
  }

  void pauseDownload() async {
    cancelToken.cancel("您取消了下载");
    // showToast(context, "当前歌曲下载完停止", duration: 10);
    setState(() {
      downloading = false;
      downloadingMsg = "逼歌";
    });
  }

  Future<Response> downloadChunk(int i, int j, Music music, String tempFile,
      int start, int end, int fileTotal) async {
    return Dio().download(
      music.url!,
      tempFile,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: false,
        headers: {
          "range": "bytes=$start-$end",
        },
      ),
      cancelToken: cancelToken,
      onReceiveProgress: (count, total) {
        if (total == -1) {
          showToast(context, "${music.name} 下载异常");
          return;
        }

        chunkCountAll[j] = count;
        setState(() {
          chunkCountAll = chunkCountAll;
        });

        // 计算进度
        var tt = 0;
        for (var c in chunkCountAll) {
          tt += c;
        }
        var msg = '${(tt / fileTotal * 100).toStringAsFixed(2)}%';
        music.downloaded = msg;
        musics[i] = music;
        setState(() {
          musics = musics;
          downloadingMsg = "下载中: ${music.name} $msg";
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getMusics();

    getMusicPath(type: 1).then((value) {
      setState(() {
        destBasePath = value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(40, 255, 255, 255),
      appBar: AppBar(
        title: AutoSizeText(
          downloadingMsg.isNotEmpty ? downloadingMsg : "逼歌",
          style: const TextStyle(
            fontSize: 20,
            color: Color.fromARGB(160, 255, 255, 255),
          ),
          minFontSize: 14,
          maxLines: 1,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: downloading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: downloadingI / musics.length,
                  semanticsLabel: '下载总进度',
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color.fromARGB(160, 255, 255, 255),
                  ),
                  backgroundColor: const Color.fromARGB(40, 255, 255, 255),
                ),
              )
            : null,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(
                    "温馨提示: ",
                    style: TextStyle(
                      color: Color.fromARGB(160, 255, 255, 255),
                    ),
                  ),
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  content: Text(
                      "下载路径: \n\n $destBasePath \n\n 使用主流音乐播放器扫描本地音乐即可 \n\n 如出现下载卡住情况可停止再继续下载"),
                  contentTextStyle: const TextStyle(
                    color: Color.fromARGB(160, 255, 255, 255),
                  ),
                  shape: const Border(
                    top: BorderSide(
                      width: 6.0,
                      color: Color.fromARGB(160, 255, 255, 255),
                    ),
                    left: BorderSide(
                      width: 6.0,
                      color: Color.fromARGB(80, 255, 255, 255),
                    ),
                    right: BorderSide(
                      width: 6.0,
                      color: Color.fromARGB(80, 255, 255, 255),
                    ),
                    bottom: BorderSide(
                      width: 6.0,
                      color: Color.fromARGB(160, 255, 255, 255),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, '关闭窗口'),
                      child: const Text(
                        "关闭窗口",
                        style: TextStyle(
                          color: Color.fromARGB(160, 255, 255, 255),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: downloading
                          ? () {
                              Navigator.pop(context, '停止下载');
                              pauseDownload();
                            }
                          : () {
                              Navigator.pop(context, '开始下载');
                              startDownload();
                            },
                      child: Text(
                        downloading ? "停止下载" : "开始下载",
                        style: const TextStyle(
                          color: Color.fromARGB(160, 255, 255, 255),
                        ),
                      ),
                    )
                  ],
                  actionsAlignment: MainAxisAlignment.center,
                ),
              );
            },
            icon: const Icon(
              CupertinoIcons.cloud_download,
              color: Color.fromARGB(160, 255, 255, 255),
            ),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: AssetImage("assets/lizhi.png"),
            alignment: Alignment.bottomRight,
          ),
        ),
        child: loading
            ? Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      height: 50,
                      child: LoadingIndicator(
                        indicatorType: Indicator.lineScalePulseOutRapid,
                        colors: [
                          Colors.blue,
                          Colors.red,
                          Colors.yellow,
                          Colors.green,
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("列表加载中"),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 10),
                controller: _controller,
                itemCount: musics.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      if (musics[index].downloaded == "未下载") {
                        showToast(context, "未下载");
                        return;
                      }
                      var file = await getDestFilePath(musics[index].url!);
                      var metadata = await getMetatada(file);
                      log(metadata.toString());
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text(
                            "歌曲信息:",
                            style: TextStyle(
                              color: Color.fromARGB(160, 255, 255, 255),
                            ),
                          ),
                          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 15),
                                child: metadata.albumArt != null
                                    ? Image.memory(
                                        metadata.albumArt!,
                                        width: 100,
                                      )
                                    : Image.asset(
                                        "assets/cover/io.png",
                                        width: 100,
                                      ),
                              ),
                              SizedBox(
                                height: 30,
                                child: ListTile(
                                  leading: const SizedBox(
                                    width: 10,
                                    child: Icon(
                                      CupertinoIcons.tag_circle_fill,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  title: Transform(
                                    transform:
                                        Matrix4.translationValues(-30, 0, 0),
                                    child: Text(
                                      metadata.trackName ?? "未知",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 30,
                                child: ListTile(
                                  leading: const Icon(
                                    CupertinoIcons.smallcircle_circle_fill,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  title: Transform(
                                    transform:
                                        Matrix4.translationValues(-30, 0, 0),
                                    child: Text(
                                      metadata.albumName ?? "未知",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 30,
                                child: ListTile(
                                  leading: const Icon(
                                    CupertinoIcons.person_circle_fill,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  title: Transform(
                                    transform:
                                        Matrix4.translationValues(-30, 0, 0),
                                    child: Text(
                                      metadata.albumArtistName ??
                                          metadata.trackArtistNames
                                              .toString()
                                              .replaceAll("[", "")
                                              .replaceAll("]", ""),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          contentTextStyle: const TextStyle(
                            color: Color.fromARGB(160, 255, 255, 255),
                          ),
                          shape: const Border(
                            top: BorderSide(
                              width: 6.0,
                              color: Color.fromARGB(160, 255, 255, 255),
                            ),
                            left: BorderSide(
                              width: 6.0,
                              color: Color.fromARGB(80, 255, 255, 255),
                            ),
                            right: BorderSide(
                              width: 6.0,
                              color: Color.fromARGB(80, 255, 255, 255),
                            ),
                            bottom: BorderSide(
                              width: 6.0,
                              color: Color.fromARGB(160, 255, 255, 255),
                            ),
                          ),
                          // actions: [
                          //   TextButton(
                          //     onPressed: () => Navigator.pop(context, '关闭窗口'),
                          //     child: const Text(
                          //       "关闭窗口",
                          //       style: TextStyle(
                          //         color: Color.fromARGB(160, 255, 255, 255),
                          //       ),
                          //     ),
                          //   ),
                          //   TextButton(
                          //     onPressed: () {
                          //       musics[index].downloaded == "未下载"
                          //           ? Navigator.pop(context, '下载歌曲')
                          //           : Navigator.pop(context, '删除歌曲');
                          //     },
                          //     child: Text(
                          //       musics[index].downloaded == "未下载"
                          //           ? "下载歌曲"
                          //           : "删除歌曲",
                          //       style: const TextStyle(
                          //         color: Color.fromARGB(160, 255, 255, 255),
                          //       ),
                          //     ),
                          //   )
                          // ],
                          // actionsAlignment: MainAxisAlignment.center,
                        ),
                      );
                    },
                    child: MusicItem(music: musics[index]),
                  );
                },
              ),
      ),
    );
  }
}

class MusicItem extends StatefulWidget {
  const MusicItem({super.key, required this.music});

  final Music music;
  @override
  State<MusicItem> createState() => _MusicItemState();
}

class _MusicItemState extends State<MusicItem> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Global.musicItemHeight,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(getCoverPng(widget.music.artist!)),
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.hue),
            fit: BoxFit.contain,
            alignment: Alignment.topLeft,
          ),
          color: const Color.fromARGB(40, 255, 255, 255),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        padding: const EdgeInsets.all(10),
        child: Padding(
          padding: EdgeInsets.only(
              left: Theme.of(context).platform == TargetPlatform.android
                  ? 70
                  : 80),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    "${widget.music.name}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(160, 255, 255, 255),
                    ),
                    minFontSize: 14,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${widget.music.artist}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Color.fromARGB(80, 255, 255, 255),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Text(
                  widget.music.downloaded,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Color.fromARGB(80, 255, 255, 255),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
