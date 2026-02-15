import 'package:flutter_test/flutter_test.dart';
import 'package:reflector/data/models/video_entry.dart';

void main() {
  String formatDurationShort(Duration? duration) {
      if (duration == null) return '00:00';
      
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      
      return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  String formatDurationLong(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);

      if (hours > 0) {
        return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
      } else {
        return "${twoDigits(minutes)}:${twoDigits(seconds)}";
      }
  }

  String formatDurationPlayback(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  test('null duration formats as 00:00', () {
      expect(formatDurationShort(null), '00:00');
    });

  test('zero duration', () {
      expect(formatDurationShort(Duration.zero), '00:00');
      expect(formatDurationLong(Duration.zero), '00:00');
      expect(formatDurationPlayback(Duration.zero), '00:00');
    });

  test('seconds formatting', () {
      expect(formatDurationShort(const Duration(seconds: 5)), '00:05');
      expect(formatDurationLong(const Duration(seconds: 5)), '00:05');
      expect(formatDurationPlayback(const Duration(seconds: 5)), '00:05');
    });

  test('minutes formatting', () {
      expect(formatDurationShort(const Duration(minutes: 5)), '05:00');
      expect(formatDurationLong(const Duration(minutes: 5)), '05:00');
      expect(formatDurationPlayback(const Duration(minutes: 5)), '05:00');
    });

  test('minutes and seconds', () {
      expect(formatDurationShort(const Duration(minutes: 5, seconds: 30)), '05:30');
      expect(formatDurationLong(const Duration(minutes: 5, seconds: 30)), '05:30');
      expect(formatDurationPlayback(const Duration(minutes: 5, seconds: 30)), '05:30');
    });

  test('hours in long format', () {
      expect(formatDurationLong(const Duration(hours: 1)), '01:00:00');
      expect(formatDurationLong(const Duration(hours: 2, minutes: 30, seconds: 15)), '02:30:15');
    });

  test('short format ignores hours', () {
      expect(formatDurationShort(const Duration(hours: 1)), '00:00');
      expect(formatDurationShort(const Duration(hours: 2, minutes: 30)), '30:00');
    });

  test('single digit padding', () {
      expect(formatDurationShort(const Duration(minutes: 1, seconds: 2)), '01:02');
      expect(formatDurationLong(const Duration(hours: 1, minutes: 2, seconds: 3)), '01:02:03');
      expect(formatDurationPlayback(const Duration(minutes: 1, seconds: 2)), '01:02');
    });

  test('large durations', () {
      expect(formatDurationShort(const Duration(hours: 2, minutes: 45, seconds: 30)), '45:30');
      expect(formatDurationLong(const Duration(hours: 2, minutes: 45, seconds: 30)), '02:45:30');
      expect(formatDurationPlayback(const Duration(hours: 2, minutes: 45, seconds: 30)), '45:30');
    });

  test('durations over 60 minutes', () {
    expect(formatDurationShort(const Duration(minutes: 90)), '30:00');
      expect(formatDurationShort(const Duration(minutes: 125, seconds: 45)), '05:45');
    });

    test('should handle edge cases', () {
      expect(formatDurationShort(const Duration(seconds: 59)), '00:59');
      expect(formatDurationShort(const Duration(minutes: 59, seconds: 59)), '59:59');
      expect(formatDurationLong(const Duration(hours: 23, minutes: 59, seconds: 59)), '23:59:59');
    });

  group('Video Entry Sorting Tests', () {
    test('should sort videos by date descending', () {
      final videos = [
        VideoEntry(
          id: '1',
          name: 'Video 1',
          date: DateTime(2024, 1, 1),
          videoPath: '/path1',
          thumbnailPath: '/thumb1',
        ),
        VideoEntry(
          id: '2',
          name: 'Video 2',
          date: DateTime(2024, 1, 3),
          videoPath: '/path2',
          thumbnailPath: '/thumb2',
        ),
        VideoEntry(
          id: '3',
          name: 'Video 3',
          date: DateTime(2024, 1, 2),
          videoPath: '/path3',
          thumbnailPath: '/thumb3',
        ),
      ];

      final sorted = List<VideoEntry>.from(videos);
      sorted.sort((a, b) {
        final dateComparison = b.date.compareTo(a.date);
        if (dateComparison != 0) return dateComparison;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      expect(sorted[0].id, '2'); // Most recent
      expect(sorted[1].id, '3');
      expect(sorted[2].id, '1'); // Oldest
    });

    test('should sort by name when dates are equal', () {
      final videos = [
        VideoEntry(
          id: '1',
          name: 'Zebra Video',
          date: DateTime(2024, 1, 1),
          videoPath: '/path1',
          thumbnailPath: '/thumb1',
        ),
        VideoEntry(
          id: '2',
          name: 'Apple Video',
          date: DateTime(2024, 1, 1),
          videoPath: '/path2',
          thumbnailPath: '/thumb2',
        ),
        VideoEntry(
          id: '3',
          name: 'Banana Video',
          date: DateTime(2024, 1, 1),
          videoPath: '/path3',
          thumbnailPath: '/thumb3',
        ),
      ];

      final sorted = List<VideoEntry>.from(videos);
      sorted.sort((a, b) {
        final dateComparison = b.date.compareTo(a.date);
        if (dateComparison != 0) return dateComparison;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      expect(sorted[0].name, 'Apple Video');
      expect(sorted[1].name, 'Banana Video');
      expect(sorted[2].name, 'Zebra Video');
    });

    test('should handle case-insensitive name sorting', () {
      final videos = [
        VideoEntry(
          id: '1',
          name: 'zebra Video',
          date: DateTime(2024, 1, 1),
          videoPath: '/path1',
          thumbnailPath: '/thumb1',
        ),
        VideoEntry(
          id: '2',
          name: 'Apple Video',
          date: DateTime(2024, 1, 1),
          videoPath: '/path2',
          thumbnailPath: '/thumb2',
        ),
      ];

      final sorted = List<VideoEntry>.from(videos);
      sorted.sort((a, b) {
        final dateComparison = b.date.compareTo(a.date);
        if (dateComparison != 0) return dateComparison;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      expect(sorted[0].name, 'Apple Video');
      expect(sorted[1].name, 'zebra Video');
    });
  });
}
