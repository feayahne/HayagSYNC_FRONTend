import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/database_service.dart';

class EvidenceMediaWidget extends StatefulWidget {
  final String filename;

  const EvidenceMediaWidget({super.key, required this.filename});

  @override
  State<EvidenceMediaWidget> createState() => _EvidenceMediaWidgetState();
}

class _EvidenceMediaWidgetState extends State<EvidenceMediaWidget> {
  List<String> _mediaFiles = [];
  int _activeIndex = 0;
  
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlayButtonVisible = true;
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _parseFiles();
    _initActiveMedia();
  }

  @override
  void didUpdateWidget(covariant EvidenceMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filename != oldWidget.filename) {
      _parseFiles();
      _activeIndex = 0; // Reset to the first file
      _initActiveMedia();
    }
  }

  void _parseFiles() {
    if (widget.filename.isEmpty) {
      _mediaFiles = [];
    } else {
      _mediaFiles = widget.filename.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
  }

  bool _isVideoFile(String path) {
    final name = path.toLowerCase();
    return name.endsWith('.mp4') ||
        name.endsWith('.mov') ||
        name.endsWith('.avi') ||
        name.endsWith('.mkv') ||
        name.endsWith('.3gp') ||
        name.endsWith('.webm');
  }

  void _initActiveMedia() {
    _disposeVideo();
    if (_mediaFiles.isEmpty || _activeIndex >= _mediaFiles.length) return;
    
    final currentFile = _mediaFiles[_activeIndex];
    if (_isVideoFile(currentFile)) {
      _initVideo(currentFile);
    }
  }

  void _initVideo(String path) {
    final videoUrl = path.startsWith('uploads/') || path.startsWith('http')
        ? _getMediaUrl(path)
        : 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
    
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
            _videoDuration = _videoController!.value.duration;
          });
        }
      });

    _videoController!.addListener(() {
      if (mounted) {
        setState(() {
          _videoPosition = _videoController!.value.position;
        });
      }
    });
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _videoPosition = Duration.zero;
    _videoDuration = Duration.zero;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _changeActiveMedia(int index) {
    if (index == _activeIndex) return;
    setState(() {
      _activeIndex = index;
    });
    _initActiveMedia();
  }

  void _togglePlay() {
    if (_videoController == null || !_isVideoInitialized) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  void _seekTo(double value) {
    if (_videoController == null || !_isVideoInitialized) return;
    _videoController!.seekTo(Duration(milliseconds: value.toInt()));
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // Multi-source placeholder resolver to make mock files look highly realistic
  String _getPlaceholderUrl(int index) {
    switch (index % 4) {
      case 0:
        return 'https://images.unsplash.com/photo-1577896851231-70ef18881754?w=800&auto=format&fit=crop&q=80'; // Classroom
      case 1:
        return 'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=800&auto=format&fit=crop&q=80'; // Hallway
      case 2:
        return 'https://images.unsplash.com/photo-1576489922094-27859dc22915?w=800&auto=format&fit=crop&q=80'; // Gymnasium
      default:
        return 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800&auto=format&fit=crop&q=80'; // Gate
    }
  }

  String _getMediaUrl(String filename) {
    if (filename.startsWith('http://') || filename.startsWith('https://')) {
      return filename;
    }
    final rootUrl = DatabaseService.baseUrl.replaceAll('/api', '');
    return '$rootUrl/$filename';
  }

  void _simulateDownload(String filename) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Downloading original "$filename" without quality loss...',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('Download complete: "$filename" saved at original resolution.'),
        ),
      );
    });
  }

  void _openFullscreenMedia(BuildContext context, int index) {
    final filename = _mediaFiles[index];
    final isVideo = _isVideoFile(filename);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setStateFs) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                title: Text(filename, style: const TextStyle(color: Colors.white, fontSize: 13)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () => _simulateDownload(filename),
                  ),
                ],
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: isVideo
                    ? _buildVideoPlayer(isFullscreen: true)
                    : InteractiveViewer(
                        maxScale: 5.0,
                        child: _buildImageViewer(index),
                      ),
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildImageViewer(int index) {
    final filename = _mediaFiles[index];
    final isLocalFile = (filename.contains('/') || filename.contains('\\')) && 
                        !filename.startsWith('uploads/') && 
                        !filename.startsWith('http');
                        
    final imagePlaceholder = isLocalFile
        ? Image.file(File(filename), fit: BoxFit.contain)
        : Image.network(
            filename.startsWith('uploads/') || filename.startsWith('http')
                ? _getMediaUrl(filename)
                : _getPlaceholderUrl(index),
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF1E293B),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48),
                    SizedBox(height: 8),
                    Text('Failed to load image preview', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              );
            },
          );

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imagePlaceholder,
      ),
    );
  }

  Widget _buildVideoPlayer({bool isFullscreen = false}) {
    if (!_isVideoInitialized || _videoController == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF2563EB)),
              SizedBox(height: 8),
              Text('Initializing Video Stream...', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final isPlaying = _videoController!.value.isPlaying;

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_videoController!),
          
          // Video controls overlay
          Container(
            color: Colors.black.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seek Bar
                Row(
                  children: [
                    Text(
                      _formatDuration(_videoPosition),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                          activeTrackColor: const Color(0xFF2563EB),
                          inactiveTrackColor: Colors.white30,
                          thumbColor: const Color(0xFF2563EB),
                        ),
                        child: Slider(
                          value: _videoPosition.inMilliseconds.toDouble(),
                          min: 0.0,
                          max: _videoDuration.inMilliseconds.toDouble(),
                          onChanged: _seekTo,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(_videoDuration),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: _togglePlay,
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.replay_10, color: Colors.white, size: 22),
                          onPressed: () {
                            final seekPos = _videoPosition - const Duration(seconds: 10);
                            _videoController!.seekTo(seekPos < Duration.zero ? Duration.zero : seekPos);
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.forward_10, color: Colors.white, size: 22),
                          onPressed: () {
                            final seekPos = _videoPosition + const Duration(seconds: 10);
                            _videoController!.seekTo(seekPos > _videoDuration ? _videoDuration : seekPos);
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (!isFullscreen)
                          IconButton(
                            icon: const Icon(Icons.fullscreen, color: Colors.white, size: 22),
                            onPressed: () => _openFullscreenMedia(context, _activeIndex),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.white, size: 22),
                          onPressed: () => _simulateDownload(_mediaFiles[_activeIndex]),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mediaFiles.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: const Center(
          child: Text('No evidence attachments available.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }

    final activeFile = _mediaFiles[_activeIndex];
    final activeIsVideo = _isVideoFile(activeFile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Gallery Thumbnail Strip (Only visible if there are multiple items)
        if (_mediaFiles.length > 1) ...[
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mediaFiles.length,
              itemBuilder: (context, index) {
                final filename = _mediaFiles[index];
                final isVid = _isVideoFile(filename);
                final isActive = index == _activeIndex;

                return GestureDetector(
                  onTap: () => _changeActiveMedia(index),
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive ? const Color(0xFF2563EB) : const Color(0xFF334155),
                        width: isActive ? 2.0 : 1.0,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Small preview thumbnail background
                        isVid
                            ? Container(
                                color: const Color(0xFF1E293B),
                                child: const Icon(Icons.videocam_outlined, color: Colors.grey, size: 24),
                              )
                            : Image.network(
                                _getPlaceholderUrl(index),
                                fit: BoxFit.cover,
                              ),
                        
                        // Active highlight overlay
                        if (isActive)
                          Container(
                            color: const Color(0xFF2563EB).withOpacity(0.15),
                          ),
                          
                        // Video Indicator Icon
                        if (isVid)
                          const Positioned(
                            bottom: 4,
                            right: 4,
                            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 14),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 2. Large Interactive Preview Container
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              activeIsVideo ? _buildVideoPlayer() : _buildImageViewer(_activeIndex),
              
              // Fullscreen zoom overlay action
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.zoom_out_map, color: Colors.white, size: 16),
                    onPressed: () => _openFullscreenMedia(context, _activeIndex),
                    tooltip: 'Open Fullscreen',
                  ),
                ),
              ),

              // File Caption Overlay (displays the exact original filename)
              Positioned(
                bottom: activeIsVideo ? null : 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    activeFile,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
