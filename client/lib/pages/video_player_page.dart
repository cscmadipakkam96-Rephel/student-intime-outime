import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// Plays a video in-app by streaming the presigned URL directly — no
// external browser/app is launched, so there's no "download" affordance
// anywhere in the flow. The player only ever holds a short-lived buffer in
// memory; nothing is written to persistent storage.
class VideoPlayerPage extends StatefulWidget {
  final String url;
  final String title;

  const VideoPlayerPage({super.key, required this.url, required this.title});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _ready = true);
          _controller.play();
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() => _error = 'Could not play this video: $e');
        });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: const TextStyle(color: Colors.white)),
              )
            : !_ready
                ? const CircularProgressIndicator(color: Colors.white)
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio == 0 ? 16 / 9 : _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _controller.value.isPlaying ? _controller.pause() : _controller.play();
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: _controller.value.isPlaying ? 0 : 1,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(Icons.play_arrow, color: Colors.white70, size: 64),
                              ),
                            ),
                          ),
                        ),
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.all(8),
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFF2D1B4E),
                            bufferedColor: Colors.white38,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
