import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bige/music.dart';
import 'package:bige/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class Download extends StatefulWidget {
  const Download({super.key});

  @override
  State<Download> createState() => _DownloadState();
}

class _DownloadState extends State<Download> {
  final ScrollController _controller = ScrollController();
  var tempPath = "";
  var destPath = "";
  var url =
      "https://testingcf.jsdelivr.net/gh/nj-lizhi/song@main/audio/list-v2.js";
  var chunk = 5;
  var loading = true;
  var downloading = false;
  var pauseDownloading = false;
  var downloadI = 0;
  var downloadMsg = "";

  List<Music> musics = [];
  List<int> chunkCountAll = [0, 0, 0, 0, 0];

  void getMusics() async {
    List<Music> list = [];
    var data = jsonDecode(getJsonStr());
    for (var d in data) {
      list.add(Music.fromJson(d));
    }
    setState(() {
      musics = list;
      loading = false;
    });
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
        if (!restart) {
          if (pauseDownloading) {
            setState(() {
              downloadMsg = "暂停下载";
              downloading = false;
            });
            showToast(context, "暂停下载");
            return;
          }
        }

        if (i >= musics.length) {
          showToast(context, "所有歌曲下载完成", duration: 10);
          setState(() {
            downloadI = 0;
            downloading = false;
            pauseDownloading = false;
            downloadMsg = "";
          });
          return;
        }

        setState(() {
          downloading = true;
          pauseDownloading = false;
          downloadI = i;
        });

        var saveDir = Directory(destPath);
        if (!saveDir.existsSync()) {
          saveDir.createSync();
        }

        Future.delayed(Duration.zero, () {}).then((value) async {
          var music = musics[i];
          log("${music.name} 开始下载");
          var s = music.url!.split("/audio/");
          if (s.length == 2) {
            var s1 = s[1].split("/");
            if (s1.length == 2) {
              var saveDestPath = "$destPath/${s1[0]}";
              var saveDestFilePath = destPath + s[1];

              var saveTempPath = tempPath + s1[0];
              var saveTempFilePath = tempPath + s[1];

              try {
                var saveDestDir = Directory(saveDestPath);
                if (!saveDestDir.existsSync()) {
                  saveDestDir.createSync();
                }

                // Music 目录下是否已经存在
                var saveDestFile = File(saveDestFilePath);
                if (saveDestFile.existsSync()) {
                  music.downloaded = "已存在";
                  musics[i] = music;
                  setState(() {
                    musics = musics;
                  });
                  i++;
                  startDownload(i: i);
                  return;
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
                  i > 0 ? (i - 1) * 80 : 0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeIn,
                );

                // 探测文件大小
                total = await getTotal(music.url!);
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
                    futures.add(
                        downloadChunk(i, j, music, temp, start, end, total));
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
            }
          }
        });
      } else {
        showToast(context, "您没有给媒体权限");
      }
    });
  }

  void pauseDownload() async {
    showToast(context, "当前歌曲下载完停止", duration: 10);
    setState(() {
      pauseDownloading = true;
    });
  }

  Future<int> getTotal(String fileUrl) async {
    var response = await Dio().head(
      fileUrl,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: false,
        headers: {
          "range": "bytes=0-0",
        },
      ),
    );
    var rh = response.headers.value(HttpHeaders.contentRangeHeader);
    return int.parse(rh!.split("/").last);
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
          downloadMsg = "正在下载：${music.name} $msg";
        });
      },
    );
  }

  void mergeChunk(int chunk, String tempFile, String saveFile) async {
    var f0 = File("${tempFile}_0");
    IOSink ioSink = f0.openWrite(mode: FileMode.writeOnlyAppend);
    for (var i = 1; i < chunk; i++) {
      var f = File("${tempFile}_$i");
      await ioSink.addStream(f.openRead());
      await f.delete();
    }

    await ioSink.close();

    await f0.copy(saveFile);
    await f0.delete();
  }

  @override
  void initState() {
    super.initState();
    getMusics();

    getMusicPath(type: 0).then((value) {
      setState(() {
        tempPath = value;
      });
    });
    getMusicPath(type: 1).then((value) {
      setState(() {
        destPath = value;
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: AutoSizeText(
          downloadMsg.isNotEmpty ? downloadMsg : "逼歌",
          style: const TextStyle(
            fontSize: 20,
            color: Color.fromARGB(160, 255, 255, 255),
          ),
          minFontSize: 14,
          maxLines: 1,
        ),
        backgroundColor: const Color.fromARGB(40, 255, 255, 255),
        elevation: 0,
        bottom: downloading || pauseDownloading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: downloadI / musics.length,
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
                  title: Text("下载 ${musics.length} 首歌?"),
                  content: Text("保存路径: \n $destPath"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, '取消'),
                        child: const Text("取消")),
                    TextButton(
                      onPressed: downloading
                          ? () {
                              Navigator.pop(context, '暂停下载');
                              pauseDownload();
                            }
                          : () => pauseDownloading
                              ? {
                                  Navigator.pop(context, '恢复下载'),
                                  startDownload(i: downloadI, restart: true)
                                }
                              : {
                                  Navigator.pop(context, '开始下载'),
                                  startDownload(),
                                },
                      child: Text(
                        downloading
                            ? "停止下载"
                            : (pauseDownloading ? "恢复下载" : "开始下载"),
                      ),
                    )
                  ],
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
                    onTap: () => {},
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
      height: 80,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(widget.music.cover!),
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.hue),
            fit: BoxFit.contain,
            alignment: Alignment.topLeft,
          ),
          color: const Color.fromARGB(40, 255, 255, 255),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        padding: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.only(left: 70),
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
