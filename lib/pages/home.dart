import 'package:audioplayers/audioplayers.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/instance_manager.dart';
import 'package:player/controllers/musicController.dart';
import 'package:player/widgets/musicItem.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController controller = ScrollController();
    final MusicController c = Get.put(MusicController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size(double.maxFinite, 56),
        child: GestureDetector(
          child: AppBar(
            title: Obx(
              () => AutoSizeText(
                "播放器 ${c.playMusic.value.name}",
                style: const TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(160, 255, 255, 255),
                ),
                minFontSize: 14,
                maxLines: 1,
              ),
            ),
            backgroundColor: Colors.black,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                image: DecorationImage(
                  image: AssetImage("assets/lizhi.png"),
                  alignment: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          onDoubleTap: () {
            controller.animateTo(0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease);
          },
        ),
      ),
      body: Obx(
        () => Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            image: DecorationImage(
              image: AssetImage("assets/lizhi.png"),
              alignment: Alignment.bottomRight,
            ),
          ),
          child: Stack(children: [
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 10),
              controller: controller,
              itemCount: c.list.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  child: MusicItem(music: c.list[index]),
                  onTap: () {
                    if (c.playIndex.value != index) {
                      // 切歌
                      c.play(index);
                      return;
                    }

                    if (c.audioPlayer.state == PlayerState.stopped) {
                      c.play(index);
                      return;
                    }
                    if (c.audioPlayer.state != PlayerState.playing) {
                      c.resume();
                    } else {
                      c.pause();
                    }
                  },
                );
              },
            ),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        onPressed: () => c.prev(), child: const Text("上一首")),
                    ElevatedButton(
                        onPressed: () {
                          if (c.audioPlayer.state == PlayerState.stopped) {
                            c.play(0);
                            return;
                          }
                          if (c.audioPlayer.state != PlayerState.playing) {
                            c.resume();
                          } else {
                            c.pause();
                          }
                        },
                        child: Text(c.isPlaying.value == true ? "暂停" : "播放")),
                    ElevatedButton(
                        onPressed: () => c.next(), child: const Text("下一首")),
                  ],
                ))
          ]),
        ),
      ),
    );
  }
}
