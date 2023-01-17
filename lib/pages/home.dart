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
            padding: const EdgeInsets.only(bottom: 120),
            controller: controller,
            itemCount: c.list.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                child: MusicItem(music: c.list[index]),
                onTap: () {
                  if (c.isPlaying.value) {
                    c.pause();
                    return;
                  } else {
                    c.play();
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
                    c.getControls(),
                  ],
                ),
              )),
        ]),
      ),
    );
  }
}
