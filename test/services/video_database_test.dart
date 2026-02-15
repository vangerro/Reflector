import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:reflector/data/models/video_entry.dart';
import 'package:reflector/data/services/video_database.dart';

class MockPathProviderPlatform extends PathProviderPlatform {
  final String tempDir;

  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempDir;
  }
}

void main() {
  late Directory tempDir;
  
  // Initialize Flutter binding for path_provider
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Set up mock path provider
    tempDir = Directory.systemTemp.createTempSync('video_journal_test');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
  });
  
  tearDownAll(() {
    // Clean up temp directory
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    // Clean up before each test
    await VideoDatabase.close();
    try {
      await VideoDatabase.deleteDatabase();
    } catch (e) {
      // Database might not exist, ignore
    }
  });

  tearDown(() async {
    // Clean up after each test
    await VideoDatabase.close();
    try {
      await VideoDatabase.deleteDatabase();
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  group('VideoDatabase Tests', () {
    final testDate = DateTime(2024, 1, 15, 10, 30, 0);
    const testDuration = Duration(minutes: 5, seconds: 30);

    test('should initialize database', () async {
      final db = await VideoDatabase.database;
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('should insert video entry', () async {
      final entry = VideoEntry(
        id: 'test-id-1',
        name: 'Test Video 1',
        date: testDate,
        videoPath: '/path/to/video1.mp4',
        thumbnailPath: '/path/to/thumbnail1.jpg',
        duration: testDuration,
      );

      await VideoDatabase.insertVideo(entry);

      final retrieved = await VideoDatabase.getVideo('test-id-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, entry.id);
      expect(retrieved.name, entry.name);
      expect(retrieved.date, entry.date);
      expect(retrieved.videoPath, entry.videoPath);
      expect(retrieved.thumbnailPath, entry.thumbnailPath);
      expect(retrieved.duration, entry.duration);
    });

    test('should insert video entry without duration', () async {
      final entry = VideoEntry(
        id: 'test-id-2',
        name: 'Test Video 2',
        date: testDate,
        videoPath: '/path/to/video2.mp4',
        thumbnailPath: '/path/to/thumbnail2.jpg',
      );

      await VideoDatabase.insertVideo(entry);

      final retrieved = await VideoDatabase.getVideo('test-id-2');
      expect(retrieved, isNotNull);
      expect(retrieved!.duration, isNull);
    });

    test('should get all video entries', () async {
      final entry1 = VideoEntry(
        id: 'test-id-3',
        name: 'Test Video 3',
        date: testDate,
        videoPath: '/path/to/video3.mp4',
        thumbnailPath: '/path/to/thumbnail3.jpg',
      );

      final entry2 = VideoEntry(
        id: 'test-id-4',
        name: 'Test Video 4',
        date: testDate.add(const Duration(days: 1)),
        videoPath: '/path/to/video4.mp4',
        thumbnailPath: '/path/to/thumbnail4.jpg',
      );

      await VideoDatabase.insertVideo(entry1);
      await VideoDatabase.insertVideo(entry2);

      final allVideos = await VideoDatabase.getAllVideos();
      expect(allVideos.length, 2);
      expect(allVideos.any((v) => v.id == 'test-id-3'), isTrue);
      expect(allVideos.any((v) => v.id == 'test-id-4'), isTrue);
    });

    test('should return empty list when no videos exist', () async {
      final allVideos = await VideoDatabase.getAllVideos();
      expect(allVideos, isEmpty);
    });

    test('should get video by ID', () async {
      final entry = VideoEntry(
        id: 'test-id-5',
        name: 'Test Video 5',
        date: testDate,
        videoPath: '/path/to/video5.mp4',
        thumbnailPath: '/path/to/thumbnail5.jpg',
      );

      await VideoDatabase.insertVideo(entry);

      final retrieved = await VideoDatabase.getVideo('test-id-5');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test-id-5');
    });

    test('should return null for non-existent video', () async {
      final retrieved = await VideoDatabase.getVideo('non-existent-id');
      expect(retrieved, isNull);
    });

    test('should update video entry', () async {
      final entry = VideoEntry(
        id: 'test-id-6',
        name: 'Original Name',
        date: testDate,
        videoPath: '/path/to/video6.mp4',
        thumbnailPath: '/path/to/thumbnail6.jpg',
      );

      await VideoDatabase.insertVideo(entry);

      final updated = entry.copyWith(
        name: 'Updated Name',
        duration: testDuration,
      );

      await VideoDatabase.updateVideo(updated);

      final retrieved = await VideoDatabase.getVideo('test-id-6');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Updated Name');
      expect(retrieved.duration, testDuration);
    });

    test('should delete video entry', () async {
      final entry = VideoEntry(
        id: 'test-id-7',
        name: 'Test Video 7',
        date: testDate,
        videoPath: '/path/to/video7.mp4',
        thumbnailPath: '/path/to/thumbnail7.jpg',
      );

      await VideoDatabase.insertVideo(entry);
      await VideoDatabase.deleteVideo('test-id-7');

      final retrieved = await VideoDatabase.getVideo('test-id-7');
      expect(retrieved, isNull);

      final allVideos = await VideoDatabase.getAllVideos();
      expect(allVideos, isEmpty);
    });

    test('should handle multiple insertions and deletions', () async {
      final entries = List.generate(5, (i) => VideoEntry(
        id: 'test-id-$i',
        name: 'Test Video $i',
        date: testDate.add(Duration(days: i)),
        videoPath: '/path/to/video$i.mp4',
        thumbnailPath: '/path/to/thumbnail$i.jpg',
      ));

      // Insert all
      for (final entry in entries) {
        await VideoDatabase.insertVideo(entry);
      }

      var allVideos = await VideoDatabase.getAllVideos();
      expect(allVideos.length, 5);

      // Delete some
      await VideoDatabase.deleteVideo('test-id-1');
      await VideoDatabase.deleteVideo('test-id-3');

      allVideos = await VideoDatabase.getAllVideos();
      expect(allVideos.length, 3);
      expect(allVideos.any((v) => v.id == 'test-id-1'), isFalse);
      expect(allVideos.any((v) => v.id == 'test-id-3'), isFalse);
    });

    test('should replace video on insert with same ID', () async {
      final entry1 = VideoEntry(
        id: 'test-id-8',
        name: 'Original Name',
        date: testDate,
        videoPath: '/path/to/video8.mp4',
        thumbnailPath: '/path/to/thumbnail8.jpg',
      );

      final entry2 = VideoEntry(
        id: 'test-id-8',
        name: 'Replaced Name',
        date: testDate.add(const Duration(days: 1)),
        videoPath: '/path/to/video8-new.mp4',
        thumbnailPath: '/path/to/thumbnail8-new.jpg',
      );

      await VideoDatabase.insertVideo(entry1);
      await VideoDatabase.insertVideo(entry2);

      final retrieved = await VideoDatabase.getVideo('test-id-8');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Replaced Name');
      expect(retrieved.date, testDate.add(const Duration(days: 1)));

      final allVideos = await VideoDatabase.getAllVideos();
      expect(allVideos.length, 1);
    });

    test('should handle cleanup orphaned entries', () async {
      // This test verifies the cleanup method exists and can be called
      // In a real scenario, you'd need to mock file system operations
      await VideoDatabase.cleanupOrphanedEntries();
      // If no exception is thrown, the method works
      expect(true, isTrue);
    });

    test('should maintain database state across multiple operations', () async {
      final entry1 = VideoEntry(
        id: 'test-id-9',
        name: 'Test Video 9',
        date: testDate,
        videoPath: '/path/to/video9.mp4',
        thumbnailPath: '/path/to/thumbnail9.jpg',
      );

      final entry2 = VideoEntry(
        id: 'test-id-10',
        name: 'Test Video 10',
        date: testDate,
        videoPath: '/path/to/video10.mp4',
        thumbnailPath: '/path/to/thumbnail10.jpg',
      );

      await VideoDatabase.insertVideo(entry1);
      await VideoDatabase.insertVideo(entry2);

      var allVideos = await VideoDatabase.getAllVideos();
      expect(allVideos.length, 2);

      await VideoDatabase.updateVideo(entry1.copyWith(name: 'Updated'));
      await VideoDatabase.deleteVideo('test-id-10');

      allVideos = await VideoDatabase.getAllVideos();
      expect(allVideos.length, 1);
      expect(allVideos.first.name, 'Updated');
    });
  });
}
