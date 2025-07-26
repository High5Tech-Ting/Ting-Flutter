import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String videoUrl;
  final String? fileName;

  const VideoPreviewScreen({super.key, required this.videoUrl, this.fileName});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      // Add listener for playback completion
      _controller.addListener(() {
        if (_controller.value.hasError) {
          setState(() {
            _hasError = true;
            _errorMessage = _controller.value.errorDescription;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.fileName ?? 'Video',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Center(
        child: _hasError
            ? _buildErrorWidget()
            : _isInitialized
            ? _buildVideoPlayer()
            : _buildLoadingWidget(),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.white),
        SizedBox(height: 16),
        Text('Loading video...', style: TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Failed to load video',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _hasError = false;
              _isInitialized = false;
            });
            _initializeVideoPlayer();
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video player
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

          // Controls overlay
          if (_showControls) _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Top controls (currently empty, can add more controls here)
          const Spacer(),

          // Center play/pause button
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),

          const Spacer(),

          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress bar
          Row(
            children: [
              Text(
                _formatDuration(_controller.value.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white30,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_controller.value.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Rewind button
              IconButton(
                onPressed: () {
                  final currentPosition = _controller.value.position;
                  final newPosition =
                      currentPosition - const Duration(seconds: 10);
                  _controller.seekTo(
                    newPosition > Duration.zero ? newPosition : Duration.zero,
                  );
                },
                icon: const Icon(
                  Icons.replay_10,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              // Play/Pause button
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              // Fast forward button
              IconButton(
                onPressed: () {
                  final currentPosition = _controller.value.position;
                  final newPosition =
                      currentPosition + const Duration(seconds: 10);
                  final duration = _controller.value.duration;
                  _controller.seekTo(
                    newPosition < duration ? newPosition : duration,
                  );
                },
                icon: const Icon(
                  Icons.forward_10,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              // Fullscreen toggle (currently just shows icon)
              IconButton(
                onPressed: () {
                  // Toggle fullscreen mode
                  if (MediaQuery.of(context).orientation ==
                      Orientation.portrait) {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                      DeviceOrientation.landscapeRight,
                    ]);
                  } else {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                    ]);
                  }
                },
                icon: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
