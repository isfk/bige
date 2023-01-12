class Music {
  String? name;
  String? artist;
  String? url;
  String? cover;
  late String downloaded;

  Music({this.name, this.artist, this.url, required this.downloaded});

  Music.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    artist = json['artist'];
    url = json['url'];
    cover = json['cover'];
    downloaded = "未下载";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['artist'] = artist;
    data['url'] = url;
    data['cover'] = cover;
    data['download'] = downloaded;
    return data;
  }
}
