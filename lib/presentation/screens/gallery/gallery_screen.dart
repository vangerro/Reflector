import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/video_entry.dart';
import '../../../data/services/video_database.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<VideoEntry> videoEntries = [];
  final DateFormat dateFormat = DateFormat('dd.MM.yyyy');

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      if (kDebugMode) {
        print('Loading videos from database...');
      }
      
      // Clean up orphaned entries first
      await VideoDatabase.cleanupOrphanedEntries();
      
      final videos = await VideoDatabase.getAllVideos();
      if (kDebugMode) {
        print('Found ${videos.length} videos in database');
      }
      
      // Check if video files still exist
      final List<VideoEntry> validVideos = [];
      for (final video in videos) {
        final videoFile = File(video.videoPath);
        final thumbnailFile = File(video.thumbnailPath);
        
        if (await videoFile.exists() && await thumbnailFile.exists()) {
          validVideos.add(video);
          if (kDebugMode) {
            print('Video file exists: ${video.name}');
          }
        } else {
          if (kDebugMode) {
            print('Video file missing: ${video.name}');
          }
          if (kDebugMode) {
            print('Video path: ${video.videoPath}');
          }
          if (kDebugMode) {
            print('Thumbnail path: ${video.thumbnailPath}');
          }
        }
      }
      
      if (kDebugMode) {
        print('Valid videos: ${validVideos.length}');
      }
      
      setState(() {
        videoEntries = validVideos;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading videos: $e');
      }
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load videos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<VideoEntry> get sortedVideoEntries {
    final sorted = List<VideoEntry>.from(videoEntries);
    sorted.sort((a, b) {
      final dateComparison = b.date.compareTo(a.date);
      if (dateComparison != 0) return dateComparison;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  void _onVideoTap(VideoEntry entry) {
    Navigator.pushNamed(
      context,
      '/playback',
      arguments: entry,
    );
  }

  void _onVideoLongPress(VideoEntry entry) {
    _showEditDialog(entry);
  }

  void _showEditDialog(VideoEntry entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(entry);
                },
              ),
              ListTile(
                leading: const Icon(Icons.save_alt, color: Colors.green),
                title: const Text('Save to Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _saveToGallery(entry);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(entry);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(VideoEntry entry) {
    final TextEditingController controller = TextEditingController(text: entry.name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename video'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _renameVideo(entry, controller.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(VideoEntry entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete video'),
          content: Text('Are you sure to delete "${entry.name}" ? This action can´t be undone !'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteVideo(entry);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameVideo(VideoEntry entry, String newName) async {
    try {
      final updatedEntry = entry.copyWith(name: newName);
      await VideoDatabase.updateVideo(updatedEntry);

      if (!mounted) return; // ✅ prevents using context if widget disposed

      setState(() {
        final index = videoEntries.indexWhere((v) => v.id == entry.id);
        if (index != -1) {
          videoEntries[index] = updatedEntry;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renamed video')),
      );
    } catch (e) {
      if (!mounted) return; // ✅
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to rename video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _saveToGallery(VideoEntry entry) async {
    try {
      final videoFile = File(entry.videoPath);
      if (!await videoFile.exists()) {
        throw Exception('Video file not found');
      }

        // Create XFile with proper mime type
        final xFile = XFile(
          entry.videoPath,
          name: '${entry.name}.mp4',
          mimeType: 'video/mp4',
        );

        // Share the video file - user can save to gallery from share sheet
        await Share.shareXFiles(
          [xFile],
          text: 'Check out this video!',
          subject: 'Video from Reflector',
        );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video shared - you can save to gallery from the share sheet'),
          backgroundColor: Colors.green,
        ),
      );
      } catch (e) {
        if (kDebugMode) print('Error sharing video: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

  Future<void> _deleteVideo(VideoEntry entry) async {
    try {
      // Delete from database
      await VideoDatabase.deleteVideo(entry.id);
      
      // Delete video file
      final videoFile = File(entry.videoPath);
      if (await videoFile.exists()) {
        await videoFile.delete();
      }
      
      // Delete thumbnail file
      final thumbnailFile = File(entry.thumbnailPath);
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }

      if (!mounted) return;

      setState(() {
        videoEntries.removeWhere((v) => v.id == entry.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed video')),
      );
    } catch (e) {
      if (!mounted) return; // ✅
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToRecord() async {
    final result = await Navigator.pushNamed(context, '/record');
    
    // If we returned with a new video entry, refresh the list
    if (result != null) {
      _loadVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Journal'),
        elevation: 0,
      ),
      body: videoEntries.isEmpty
          ? _buildEmptyState()
          : _buildVideoGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToRecord,
        elevation: 0,
        backgroundColor: Colors.transparent,
        tooltip: 'Record video',
        child: const Center(
          child: Icon(
            Icons.video_camera_front,
            color: Colors.black87,
            size: 50.0,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
              'Gallery is empty !',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    final sorted = sortedVideoEntries;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final entry = sorted[index];
          return _buildVideoCard(entry);
        },
      ),
    );
  }

  Widget _buildVideoCard(VideoEntry entry) {
    return GestureDetector(
      onTap: () => _onVideoTap(entry),
      onLongPress: () => _onVideoLongPress(entry),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: Stack(
                  children: [
                    // Display actual thumbnail if available
                    FutureBuilder<File>(
                      future: Future.value(File(entry.thumbnailPath)),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.existsSync()) {
                          return ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            child: Image.file(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderThumbnail();
                              },
                            ),
                          );
                        } else {
                          return _buildPlaceholderThumbnail();
                        }
                      },
                    ),
                    // Play button overlay
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    // Duration overlay
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(entry.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      dateFormat.format(entry.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.video_library,
          size: 48,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
