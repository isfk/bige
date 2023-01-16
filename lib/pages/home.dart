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
      appBar: AppBar(
        title: const AutoSizeText(
          "播放器",
          style: TextStyle(
            fontSize: 20,
            color: Color.fromARGB(160, 255, 255, 255),
          ),
          minFontSize: 14,
          maxLines: 1,
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            image: DecorationImage(
              image: AssetImage("assets/lizhi.png"),
              alignment: Alignment.centerLeft,
            ),
          ),
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
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 10),
            controller: controller,
            itemCount: c.list.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                child: MusicItem(music: c.list[index]),
                onTap: () => {},
              );
            },
          ),
        ),
      ),
    );
  }
}
