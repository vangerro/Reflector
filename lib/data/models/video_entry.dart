class VideoEntry {
  final String id;
  final String name;
  final DateTime date;
  final String videoPath;
  final String thumbnailPath;
  final Duration? duration;

  VideoEntry({
    required this.id,
    required this.name,
    required this.date,
    required this.videoPath,
    required this.thumbnailPath,
    this.duration,
  });

  // Factory constructor für JSON
  factory VideoEntry.fromJson(Map<String, dynamic> json) {
    return VideoEntry(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      videoPath: json['videoPath'],
      thumbnailPath: json['thumbnailPath'],
      duration: json['duration'] != null 
          ? Duration(milliseconds: json['duration'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'videoPath': videoPath,
      'thumbnailPath': thumbnailPath,
      'duration': duration?.inMilliseconds,
    };
  }

  VideoEntry copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? videoPath,
    String? thumbnailPath,
    Duration? duration,
  }) {
    return VideoEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      videoPath: videoPath ?? this.videoPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VideoEntry(id: $id, name: $name, date: $date)';
  }
}
