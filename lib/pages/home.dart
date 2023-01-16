import 'package:audioplayers/audioplayers.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
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
      backgroundColor: const Color.fromARGB(255, 187, 187, 187),
      appBar: PreferredSize(
        preferredSize: const Size(double.maxFinite, 56),
        child: GestureDetector(
          child: AppBar(
            title: const AutoSizeText(
              "我们不能失去信仰",
              style: TextStyle(
                  fontSize: 28,
                  color: Color.fromARGB(200, 0, 0, 0),
                  fontStyle: FontStyle.italic),
              minFontSize: 14,
              maxLines: 1,
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                  image: AssetImage("assets/lizhi.png"),
                  alignment: Alignment.bottomRight,
                  fit: BoxFit.scaleDown,
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
        () => Stack(children: [
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
              child: Container(
                height: 110,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 255, 255, 255),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(95, 0, 0, 0),
                      offset: Offset(0, -5),
                      blurRadius: 5,
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Center(
                          child: AutoSizeText(
                        c.playMusic.value.name.isNotEmpty
                            ? c.playMusic.value.name
                            : "点击播放",
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(200, 0, 0, 0),
                        ),
                        minFontSize: 14,
                        maxLines: 1,
                      )),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          iconSize: 30,
                          onPressed: () => c.shuffle(),
                          icon: const Icon(
                            CupertinoIcons.shuffle,
                            color: Color.fromARGB(200, 0, 0, 0),
                          ),
                        ),
                        IconButton(
                          iconSize: 30,
                          onPressed: () => c.prev(),
                          icon: const Icon(
                            CupertinoIcons.backward_fill,
                            color: Color.fromARGB(200, 0, 0, 0),
                          ),
                        ),
                        IconButton(
                          iconSize: 60,
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
                          icon: Icon(
                            c.isPlaying.value == true
                                ? Icons.pause_circle
                                : Icons.play_circle,
                            color: const Color.fromARGB(200, 0, 0, 0),
                          ),
                        ),
                        IconButton(
                          iconSize: 30,
                          onPressed: () => c.next(),
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
                    ),
                  ],
                ),
              )),
        ]),
      ),
    );
  }
}
