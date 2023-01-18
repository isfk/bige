import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:player/controllers/musicController.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../common/utils.dart';
import '../models/music.dart';

class MusicItem extends StatefulWidget {
  const MusicItem({super.key, required this.music});

  final Music music;
  @override
  State<MusicItem> createState() => _MusicItemState();
}

class _MusicItemState extends State<MusicItem> {
  var c = Get.put(MusicController());
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: c.musicItemHeight,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(getCoverPng(widget.music.artist)),
            // colorFilter: const ColorFilter.mode(Colors.black, BlendMode.hue),
            fit: BoxFit.contain,
            alignment: Alignment.topLeft,
          ),
          color: const Color.fromARGB(100, 200, 200, 200),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Padding(
          padding: const EdgeInsets.only(left: 60),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    widget.music.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      // color: Color.fromARGB(160, 255, 255, 255),
                    ),
                    minFontSize: 14,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.music.artist,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      // color: Color.fromARGB(80, 255, 255, 255),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                bottom: 3,
                child: Text(
                  widget.music.download,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color.fromARGB(255, 120, 120, 120),
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
