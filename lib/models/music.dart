class Music {
  late String name;
  late String artist;
  late String url;
  late String cover;
  late String download;

  Music({
    this.name = "",
    this.artist = "",
    this.url = "",
    this.cover = "",
    this.download = "",
  });

  Music.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    artist = json['artist'];
    url = json['url'];
    cover = json['cover'];
    if (json['download'] == null) {
      download = "";
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['artist'] = artist;
    data['url'] = url;
    data['cover'] = cover;
    data['download'] = download;
    return data;
  }
}
