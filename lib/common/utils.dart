import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toast/toast.dart';

void showToast(BuildContext context, String msg,
    {int? duration, int? gravity}) {
  ToastContext().init(context);
  Toast.show(msg, duration: duration, gravity: gravity);
}

// 检测是否开启媒体权限
Future<bool> checkPermission() async {
  if (!Platform.isAndroid) {
    return true;
  }
  var status = await Permission.storage.status;
  if (status != PermissionStatus.granted) {
    var res = await Permission.storage.request();
    if (res.isGranted) {
      return true;
    }
    return false;
  }
  return true;
}

// 指定目录
Future<String> getMusicPath({int type = 0}) async {
  var path = "";

  if (Platform.isAndroid) {
    var dir = await getExternalStorageDirectory();
    path = "${dir!.path}/";

    if (type != 1) return path;

    return path = "/storage/emulated/0/Music/";
  }

  if (Platform.isIOS) {
    var dir = await getApplicationSupportDirectory();
    path = "${dir.path}/";

    if (type != 1) return path;

    var dir1 = await getApplicationSupportDirectory();
    return "${dir1.path}/";
  }

  return path;
}

// 通过专辑名获取专辑封面
String getCoverPng(String artist) {
  return "assets/cover/${artist.replaceAll("专辑-", "")}.png";
}

// 通过专辑名获取目标路径
Future<String> getDestPath(String artist) async {
  var musicPath = await getMusicPath(type: 1);
  return "$musicPath${artist.replaceAll("专辑-", "")}/";
}

// 从歌曲url获取目标全路径
Future<String> getDestFilePath(String url) async {
  var musicPath = await getMusicPath(type: 1);
  return musicPath + url.split("/audio/")[1];
}

// 通过专辑名获取临时路径
Future<String> getTempPath(String artist) async {
  var musicPath = await getMusicPath();
  return "$musicPath${artist.replaceAll("专辑-", "")}/";
}

// 从歌曲url获取临时全路径
Future<String> getTempFilePath(String url) async {
  var musicPath = await getMusicPath();
  return musicPath + url.split("/audio/")[1];
}

// 从歌曲url判断是否已经下载
Future<bool> isMusicExists(String url) async {
  var musicPath = await getMusicPath(type: 1);
  var mf = File(musicPath + url.split("/audio/")[1]);
  if (mf.existsSync()) {
    return true;
  }
  return false;
}

// 获取文件长度
Future<int> getRangeTotal(String fileUrl) async {
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

// 合并临时目录下多个文件，并复制到新地址
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

Future<Metadata> getMetatada(String file) async {
  var metadata = await MetadataRetriever.fromFile(File(file));
  return metadata;
}
