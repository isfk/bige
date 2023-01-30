import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/controllers/musicController.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({Key? key}) : super(key: key);

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget>
    with AutomaticKeepAliveClientMixin {
  final MusicController c = Get.put(MusicController());
  @override

  // _showAbout() async {
  //   showLicensePage(
  //     context: context,
  //     applicationIcon: Image.asset(
  //       "assets/ic_logo.png",
  //       width: 40,
  //       height: 40,
  //     ),
  //     applicationName: "逼歌",
  //     applicationVersion: "v0.6.0",
  //     applicationLegalese: "Copyright© 逼歌",
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(
      () => Drawer(
        backgroundColor: Colors.white,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Column(
            children: [
              DrawerHeader(
                padding: EdgeInsets.zero,
                child: Column(
                  children: const [
                    SizedBox(
                      height: 64,
                    ),
                    Text(
                      "逼歌",
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 36,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                    Text(
                      "v0.6.0",
                      style: TextStyle(
                        color: Color.fromARGB(255, 200, 200, 200),
                        fontSize: 14,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              Stack(
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                      value: c.downloadingIndexShow / c.list.length,
                      semanticsLabel:
                          '下载总进度 ${c.downloadingIndexShow} / ${c.list.length}',
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(160, 0, 0, 0),
                      ),
                      backgroundColor: const Color.fromARGB(40, 0, 0, 0),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 60,
                    child: Text("${c.downloadingIndexShow}/${c.list.length}",
                        textAlign: TextAlign.center),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 90,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(120, 50),
                        backgroundColor:
                            c.downloading.value ? Colors.grey : Colors.black,
                      ),
                      onPressed: c.downloading.value
                          ? () {
                              c.pauseDownload();
                            }
                          : () {
                              c.startDownload(i: c.downloadingIndex());
                            },
                      child: Text(
                        c.downloading.value ? "停止下载" : "开始下载",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
