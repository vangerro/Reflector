import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../data/models/video_entry.dart';

class PlaybackScreen extends StatefulWidget {
  final VideoEntry videoEntry;

  const PlaybackScreen({
    super.key,
    required this.videoEntry,
  });

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _videoFinished = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      final videoFile = File(widget.videoEntry.videoPath);
      if (!await videoFile.exists()) {
        throw Exception('Video file not found');
      }

      _controller = VideoPlayerController.file(videoFile);
      await _controller!.initialize();
      
      _duration = _controller!.value.duration;
      
      // Add listener to update position and handle video completion
      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _position = _controller!.value.position;
            
            // Check if video finished
            if (_controller!.value.position >= _controller!.value.duration) {
              _videoFinished = true;
              _isPlaying = false;
              _showControls = true; // Show controls when video finishes
            }
          });
        }
      });

      setState(() {
        _isInitialized = true;
        _showControls = true; // Always show controls on entry
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load video: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startControlsTimer() {
    // Cancel any existing timer
    _controlsTimer?.cancel();
    
    // Start new timer
    _controlsTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _isPlaying && !_videoFinished) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _togglePlayPause() {
    if (_videoFinished) {
      // Restart video if it finished
      _controller!.seekTo(Duration.zero);
      setState(() {
        _videoFinished = false;
        _isPlaying = true;
        _showControls = true;
      });
      _controller!.play();
      _startControlsTimer();
    } else {
      // Normal play/pause
      setState(() {
        if (_isPlaying) {
          _controller!.pause();
          _isPlaying = false;
          _showControls = true; // Show controls when paused
        } else {
          _controller!.play();
          _isPlaying = true;
          _showControls = true; // Show controls when starting to play
          _startControlsTimer(); // Start timer to hide controls
        }
      });
    }
  }

  void _seekTo(Duration position) {
    _controller!.seekTo(position);
    setState(() {
      _showControls = true;
      _videoFinished = false;
    });
    _startControlsTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video Player or Thumbnail with Tap Gesture
            GestureDetector(
              onTap: () {
                if (_videoFinished) {
                  // If video finished, just restart
                  _togglePlayPause();
                } else if (_isPlaying) {
                  // If playing, toggle controls
                  setState(() {
                    _showControls = !_showControls;
                  });
                  if (_showControls) {
                    _startControlsTimer(); // Start timer if showing controls
                  }
                } else {
                  // If paused, show controls and play
                  setState(() {
                    _showControls = true;
                  });
                  _togglePlayPause();
                }
              },
              child: Center(
                child: _isInitialized
                    ? _videoFinished
                        ? _buildThumbnailView()
                        : AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: VideoPlayer(_controller!),
                          )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
              ),
            ),

            // Controls Overlay
            if (_showControls) _buildControlsOverlay(),
            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailView() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Thumbnail
          Center(
            child: FutureBuilder<File>(
              future: Future.value(File(widget.videoEntry.thumbnailPath)),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.existsSync()) {
                  return Image.file(
                    snapshot.data!,
                    fit: BoxFit.contain,
                  );
                } else {
                  return Container(
                    color: Colors.grey[900],
                    child: Icon(
                      Icons.video_library,
                      size: 80,
                      color: Colors.grey[600],
                    ),
                  );
                }
              },
            ),
          ),
          
          // Large Play Button
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
                onPressed: _togglePlayPause,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.videoEntry.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return IgnorePointer(
      ignoring: _isPlaying && !_videoFinished,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Large Play/Pause Button
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                  onPressed: _togglePlayPause,
                ),
              ),
            ),

            // Bottom Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Bar
          _buildProgressBar(),
          const SizedBox(height: 16),
          
          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Rewind 10 seconds
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white),
                onPressed: () {
                  final newPosition = _position - const Duration(seconds: 10);
                  _seekTo(newPosition.isNegative ? Duration.zero : newPosition);
                },
              ),
              
              // Play/Pause
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: _togglePlayPause,
              ),
              
              // Forward 10 seconds
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white),
                onPressed: () {
                  final newPosition = _position + const Duration(seconds: 10);
                  _seekTo(newPosition > _duration ? _duration : newPosition);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        // Progress Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.red,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.red,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: _position.inMilliseconds.toDouble(),
            min: 0,
            max: _duration.inMilliseconds.toDouble(),
            onChanged: (value) {
              _seekTo(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
        
        // Time Display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
