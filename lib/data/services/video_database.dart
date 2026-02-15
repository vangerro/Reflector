import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video_entry.dart';

class VideoDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // Use documents directory for persistent storage
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, 'video_journal.db');

    if (kDebugMode) {
      print('Database path: $path');
    }
    if (kDebugMode) {
      print('Documents directory: ${documentsDir.path}');
    }
    if (kDebugMode) {
      print('Documents directory exists: ${await documentsDir.exists()}');
    }
    
    // Check if database file already exists
    final dbFile = File(path);
    final dbExists = await dbFile.exists();
    if (kDebugMode) {
      print('Database file exists: $dbExists');
    }
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      singleInstance: true, // Ensure single instance for better persistence
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE videos(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        videoPath TEXT NOT NULL,
        thumbnailPath TEXT NOT NULL,
        duration INTEGER
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add duration column to existing table
      await db.execute('ALTER TABLE videos ADD COLUMN duration INTEGER');
    }
  }

  // Insert a new video entry
  static Future<void> insertVideo(VideoEntry video) async {
    final db = await database;
    await db.insert(
      'videos',
      video.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all video entries
  static Future<List<VideoEntry>> getAllVideos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('videos');
    
    return List.generate(maps.length, (i) {
      return VideoEntry.fromJson(maps[i]);
    });
  }

  // Get a single video by ID
  static Future<VideoEntry?> getVideo(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'videos',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return VideoEntry.fromJson(maps.first);
    }
    return null;
  }

  // Update a video entry
  static Future<void> updateVideo(VideoEntry video) async {
    final db = await database;
    await db.update(
      'videos',
      video.toJson(),
      where: 'id = ?',
      whereArgs: [video.id],
    );
  }

  // Delete a video entry
  static Future<void> deleteVideo(String id) async {
    final db = await database;
    await db.delete(
      'videos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clean up orphaned entries (videos in database but files missing)
  static Future<void> cleanupOrphanedEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> allVideos = await db.query('videos');
    
    for (final video in allVideos) {
      final videoPath = video['videoPath'] as String;
      final thumbnailPath = video['thumbnailPath'] as String;
      
      final videoFile = File(videoPath);
      final thumbnailFile = File(thumbnailPath);
      
      if (!await videoFile.exists() || !await thumbnailFile.exists()) {
        if (kDebugMode) {
          print('Cleaning up orphaned video: ${video['name']}');
        }
        await db.delete(
          'videos',
          where: 'id = ?',
          whereArgs: [video['id']],
        );
      }
    }
  }

  // Close the database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Delete database file (for testing/reset)
  static Future<void> deleteDatabase() async {
    await close();
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, 'video_journal.db');
    await databaseFactory.deleteDatabase(path);
  }
}
