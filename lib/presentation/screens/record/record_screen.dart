import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as video_thumbnail;
import 'package:video_player/video_player.dart';
import '../../../data/models/video_entry.dart';
import '../../../data/services/video_database.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isRecording = false;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  String? _recordedVideoPath;
  Duration _recordingDuration = Duration.zero;
  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'No cameras available on this device';
        });
        return;
      }

      await _requestPermissions();

      final frontCamera = _cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        ),
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high, // 1080p
        enableAudio: true,
      );

      await _cameraController!.initialize();

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Camera initialization failed: ${e.toString()}';
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final cameraStatus = await Permission.camera.request();
      if (kDebugMode) {
        print('Camera permission status: $cameraStatus');
      }
      final microphoneStatus = await Permission.microphone.request();
      if (kDebugMode) {
        print('Microphone permission status: $microphoneStatus');
      }
      if (cameraStatus != PermissionStatus.granted) {
        return;
      }
      if (microphoneStatus != PermissionStatus.granted) {
        return;
      }
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Permission request error: $e');
      }
    }
  }


  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isRecording) return;

    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final Directory appDir = await getApplicationDocumentsDirectory();
      path.join(appDir.path, 'video_$timestamp.mp4');

      await _cameraController!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        _recordingDuration = Duration.zero;
      });

      // Start timer to update recording duration
      _startRecordingTimer();

    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to start recording: ${e.toString()}';
      });
    }
  }

  void _startRecordingTimer() {
    // Update recording duration every second
    Future.doWhile(() async {
      if (!_isRecording || _recordingStartTime == null) return false;

      await Future.delayed(const Duration(seconds: 1));

      if (mounted && _isRecording) {
        setState(() {
          _recordingDuration = DateTime.now().difference(_recordingStartTime!);
        });
        return true;
      }
      return false;
    });
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_isRecording) return;

    try {
      final XFile videoFile = await _cameraController!.stopVideoRecording();

      setState(() {
        _isRecording = false;
        _recordedVideoPath = videoFile.path;
        _recordingStartTime = null;
      });

      // Show save dialog
      _showSaveDialog();

    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to stop recording: ${e.toString()}';
        _isRecording = false;
      });
    }
  }

  void _showSaveDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // User must provide a name
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Give your video a name:'),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Video name',
                  border: OutlineInputBorder(),
                  hintText: 'Enter a name for your video',
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Cancel - delete the recorded video
                _discardRecording();
                Navigator.pop(context);
              },
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  _saveVideo(name);
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

  Future<void> _saveVideo(String name) async {
    if (_recordedVideoPath == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Saving video...'),
            ],
          ),
        );
      },
    );

    try {
      // Generate unique ID and paths
      final String id = const Uuid().v4();
      final Directory appDir = await getApplicationDocumentsDirectory();

      // Create final video file path
      final String finalVideoPath = path.join(
          appDir.path,
          'videos',
          '$id.mp4'
      );

      // Create videos directory if it doesn't exist
      final Directory videosDir = Directory(path.dirname(finalVideoPath));
      if (!await videosDir.exists()) {
        await videosDir.create(recursive: true);
      }

      // Create thumbnails directory if it doesn't exist
      final String thumbnailPath = path.join(
          appDir.path,
          'thumbnails',
          '$id.jpg'
      );
      final Directory thumbnailsDir = Directory(path.dirname(thumbnailPath));
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }

      // Move video to final location
      final File tempFile = File(_recordedVideoPath!);
      if (!await tempFile.exists()) {
        throw Exception('Temporary video file not found');
      }
      
      await tempFile.copy(finalVideoPath);
      await tempFile.delete(); // Clean up temp file

      // Generate thumbnail from the first frame
      await _generateThumbnail(finalVideoPath, thumbnailPath);

      // Get video duration
      final Duration? duration = await _getVideoDuration(finalVideoPath);

      // Create VideoEntry
      final VideoEntry newEntry = VideoEntry(
        id: id,
        name: name,
        date: DateTime.now(),
        videoPath: finalVideoPath,
        thumbnailPath: thumbnailPath,
        duration: duration,
      );

      // Save to database
      await VideoDatabase.insertVideo(newEntry);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video "$name" saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to gallery with the new entry
        Navigator.pop(context, newEntry);
      }

    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateThumbnail(String videoPath, String thumbnailPath) async {
    try {
      // Generate thumbnail from the first frame of the video
      final thumbnail = await video_thumbnail.VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: video_thumbnail.ImageFormat.JPEG,
        quality: 75,
        timeMs: 0, // First frame
      );
      
      if (thumbnail == null) {
        if (kDebugMode) {
          print('Failed to generate thumbnail - result is null');
        }
      } else {

        if (kDebugMode) {
          print('Thumbnail generated: $thumbnail');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to generate thumbnail: $e');
      }
      // Don't throw - thumbnail generation failure shouldn't prevent video save
    }
  }

  Future<Duration?> _getVideoDuration(String videoPath) async {
    try {
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      return duration;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get video duration: $e');
      }
      return null;
    }
  }

  Future<void> _discardRecording() async {
    if (_recordedVideoPath == null) return;

    try {
      final File videoFile = File(_recordedVideoPath!);
      if (await videoFile.exists()) {
        await videoFile.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete temp video file: $e');
      }
    }

    setState(() {
      _recordedVideoPath = null;
    });
  }

  void _flipCamera() async {
    if (_cameras.length < 2) return;

    final currentLensDirection = _cameraController!.description.lensDirection;
    final newCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection != currentLensDirection,
      orElse: () => _cameras.first,
    );

    await _cameraController!.dispose();

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            if (_isRecording) {
              _showExitConfirmation();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: _isRecording
            ? Text(
          _formatDuration(_recordingDuration),
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        )
            : const Text(
          'Record Video',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (_isInitialized && _cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              onPressed: _isRecording ? null : _flipCamera,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),

        // Recording indicator
        if (_isRecording)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildControls(),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Initializing camera...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black,
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Spacer for balance
          const SizedBox(width: 60),

          // Record/Stop Button
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : Colors.white,
                border: Border.all(
                  color: _isRecording ? Colors.white : Colors.red,
                  width: 4,
                ),
              ),
              child: _isRecording
                  ? const Icon(
                Icons.stop,
                color: Colors.white,
                size: 40,
              )
                  : Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
            ),
          ),

          // Spacer for balance
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stop Recording?'),
          content: const Text('Do you want to stop the current recording and go back?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Recording'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _stopRecording();
              },
              child: const Text('Stop & Save'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();

                if (_isRecording) {
                  await _cameraController!.stopVideoRecording();
                  if (!mounted) return;
                  setState(() => _isRecording = false);
                }

                navigator.pop(); // Go back to gallery
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
  }
}
