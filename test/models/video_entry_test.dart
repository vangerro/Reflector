import 'package:flutter_test/flutter_test.dart';
import 'package:reflector/data/models/video_entry.dart';

void main() {
  group('VideoEntry Model Tests', () {
    final testDate = DateTime(2024, 1, 15, 10, 30, 0);
    const testDuration = Duration(minutes: 5, seconds: 30);

    test('should create VideoEntry with all required fields', () {
      final entry = VideoEntry(
        id: 'test-id-1',
        name: 'Test Video',
        date: testDate,
        videoPath: '/path/to/video.mp4',
        thumbnailPath: '/path/to/thumbnail.jpg',
        duration: testDuration,
      );

      expect(entry.id, 'test-id-1');
      expect(entry.name, 'Test Video');
      expect(entry.date, testDate);
      expect(entry.videoPath, '/path/to/video.mp4');
      expect(entry.thumbnailPath, '/path/to/thumbnail.jpg');
      expect(entry.duration, testDuration);
    });

    test('should create VideoEntry without duration', () {
      final entry = VideoEntry(
        id: 'test-id-2',
        name: 'Test Video 2',
        date: testDate,
        videoPath: '/path/to/video2.mp4',
        thumbnailPath: '/path/to/thumbnail2.jpg',
      );

      expect(entry.duration, isNull);
    });

    test('should serialize VideoEntry to JSON correctly', () {
      final entry = VideoEntry(
        id: 'test-id-3',
        name: 'Test Video 3',
        date: testDate,
        videoPath: '/path/to/video3.mp4',
        thumbnailPath: '/path/to/thumbnail3.jpg',
        duration: testDuration,
      );

      final json = entry.toJson();

      expect(json['id'], 'test-id-3');
      expect(json['name'], 'Test Video 3');
      expect(json['date'], testDate.toIso8601String());
      expect(json['videoPath'], '/path/to/video3.mp4');
      expect(json['thumbnailPath'], '/path/to/thumbnail3.jpg');
      expect(json['duration'], testDuration.inMilliseconds);
    });

    test('should serialize VideoEntry to JSON without duration', () {
      final entry = VideoEntry(
        id: 'test-id-4',
        name: 'Test Video 4',
        date: testDate,
        videoPath: '/path/to/video4.mp4',
        thumbnailPath: '/path/to/thumbnail4.jpg',
      );

      final json = entry.toJson();

      expect(json['duration'], isNull);
    });

    test('should deserialize JSON to VideoEntry correctly', () {
      final json = {
        'id': 'test-id-5',
        'name': 'Test Video 5',
        'date': testDate.toIso8601String(),
        'videoPath': '/path/to/video5.mp4',
        'thumbnailPath': '/path/to/thumbnail5.jpg',
        'duration': testDuration.inMilliseconds,
      };

      final entry = VideoEntry.fromJson(json);

      expect(entry.id, 'test-id-5');
      expect(entry.name, 'Test Video 5');
      expect(entry.date, testDate);
      expect(entry.videoPath, '/path/to/video5.mp4');
      expect(entry.thumbnailPath, '/path/to/thumbnail5.jpg');
      expect(entry.duration, testDuration);
    });

    test('should deserialize JSON to VideoEntry without duration', () {
      final json = {
        'id': 'test-id-6',
        'name': 'Test Video 6',
        'date': testDate.toIso8601String(),
        'videoPath': '/path/to/video6.mp4',
        'thumbnailPath': '/path/to/thumbnail6.jpg',
        'duration': null,
      };

      final entry = VideoEntry.fromJson(json);

      expect(entry.duration, isNull);
    });

    test('should create copy with updated fields', () {
      final original = VideoEntry(
        id: 'test-id-7',
        name: 'Original Name',
        date: testDate,
        videoPath: '/path/to/video7.mp4',
        thumbnailPath: '/path/to/thumbnail7.jpg',
        duration: testDuration,
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        duration: const Duration(minutes: 10),
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Updated Name');
      expect(updated.date, original.date);
      expect(updated.videoPath, original.videoPath);
      expect(updated.thumbnailPath, original.thumbnailPath);
      expect(updated.duration, const Duration(minutes: 10));
    });

    test('should create copy without changing original', () {
      final original = VideoEntry(
        id: 'test-id-8',
        name: 'Original Name',
        date: testDate,
        videoPath: '/path/to/video8.mp4',
        thumbnailPath: '/path/to/thumbnail8.jpg',
      );

      final copy = original.copyWith(name: 'New Name');

      expect(original.name, 'Original Name');
      expect(copy.name, 'New Name');
    });

    test('should be equal when IDs are the same', () {
      final entry1 = VideoEntry(
        id: 'same-id',
        name: 'Video 1',
        date: testDate,
        videoPath: '/path/to/video1.mp4',
        thumbnailPath: '/path/to/thumbnail1.jpg',
      );

      final entry2 = VideoEntry(
        id: 'same-id',
        name: 'Video 2',
        date: DateTime(2024, 2, 1),
        videoPath: '/different/path.mp4',
        thumbnailPath: '/different/thumbnail.jpg',
      );

      expect(entry1 == entry2, isTrue);
      expect(entry1.hashCode, entry2.hashCode);
    });

    test('should not be equal when IDs are different', () {
      final entry1 = VideoEntry(
        id: 'id-1',
        name: 'Video 1',
        date: testDate,
        videoPath: '/path/to/video1.mp4',
        thumbnailPath: '/path/to/thumbnail1.jpg',
      );

      final entry2 = VideoEntry(
        id: 'id-2',
        name: 'Video 1',
        date: testDate,
        videoPath: '/path/to/video1.mp4',
        thumbnailPath: '/path/to/thumbnail1.jpg',
      );

      expect(entry1 == entry2, isFalse);
    });

    test('should return correct string representation', () {
      final entry = VideoEntry(
        id: 'test-id-9',
        name: 'Test Video 9',
        date: testDate,
        videoPath: '/path/to/video9.mp4',
        thumbnailPath: '/path/to/thumbnail9.jpg',
      );

      final string = entry.toString();

      expect(string, contains('test-id-9'));
      expect(string, contains('Test Video 9'));
      expect(string, contains('2024-01-15'));
    });

    test('should handle round-trip JSON serialization', () {
      final original = VideoEntry(
        id: 'test-id-10',
        name: 'Test Video 10',
        date: testDate,
        videoPath: '/path/to/video10.mp4',
        thumbnailPath: '/path/to/thumbnail10.jpg',
        duration: testDuration,
      );

      final json = original.toJson();
      final deserialized = VideoEntry.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.name, original.name);
      expect(deserialized.date, original.date);
      expect(deserialized.videoPath, original.videoPath);
      expect(deserialized.thumbnailPath, original.thumbnailPath);
      expect(deserialized.duration, original.duration);
    });
  });
}
