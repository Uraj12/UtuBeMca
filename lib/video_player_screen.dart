import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool isFullScreen = false;
  bool isLiked = false;
  bool isDisliked = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {}); // Refresh UI after initialization
      });

    _controller.addListener(() {
      setState(() {}); // Refresh UI on video updates
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void toggleFullScreen() {
    setState(() {
      isFullScreen = !isFullScreen;
    });
  }

  void playNextVideo() {
    setState(() {
      _controller.pause();
      _controller = VideoPlayerController.network(
        'https://samplelib.com/lib/preview/mp4/sample-5s.mp4', // Dummy next video
      )..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: isFullScreen
          ? null
          : AppBar(
        title: const Text(
          "Video Player",
          style: TextStyle(fontFamily: 'SF Pro', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Main Video Player
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Video Player Section
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      _controller.value.isInitialized
                          ? AspectRatio(
                        aspectRatio: isFullScreen
                            ? MediaQuery.of(context).size.aspectRatio
                            : _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                          : const Center(child: CircularProgressIndicator()),

                      // Play Button Overlay
                      if (!_controller.value.isPlaying)
                        Positioned(
                          child: IconButton(
                            icon: const Icon(Icons.play_circle_fill, size: 80, color: Colors.white),
                            onPressed: () => setState(() => _controller.play()),
                          ),
                        ),
                    ],
                  ),

                  // Video Progress Bar
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                  const SizedBox(height: 8),

                  // Video Duration & Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDuration(_controller.value.position),
                          style: const TextStyle(color: Colors.white, fontFamily: 'SF Pro', fontSize: 16),
                        ),
                        Text(
                          formatDuration(_controller.value.duration),
                          style: const TextStyle(color: Colors.white, fontFamily: 'SF Pro', fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  // Controls: Play/Pause, Next, Fullscreen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 50,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 50),
                        onPressed: playNextVideo,
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: Icon(
                          isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white,
                          size: 50,
                        ),
                        onPressed: toggleFullScreen,
                      ),
                    ],
                  ),

                  // Like, Dislike, Comment, Share Buttons (YouTube-style)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                color: isLiked ? Colors.blue : Colors.white,
                                size: 40,
                              ),
                              onPressed: () {
                                setState(() {
                                  isLiked = !isLiked;
                                  if (isDisliked) {
                                    isDisliked = false; // Remove dislike if liked
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                color: isDisliked ? Colors.blue : Colors.white,
                                size: 40,
                              ),
                              onPressed: () {
                                setState(() {
                                  isDisliked = !isDisliked;
                                  if (isLiked) {
                                    isLiked = false; // Remove like if disliked
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 40),
                        IconButton(
                          icon: const Icon(Icons.comment, color: Colors.white, size: 40),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 40),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white, size: 40),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  // Comment Section (YouTube-style)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const Divider(color: Colors.white),
                        ListTile(
                          title: const Text("User 1",
                              style: TextStyle(color: Colors.white)),
                          subtitle: const Text("Great video!",
                              style: TextStyle(color: Colors.grey)),
                        ),
                        ListTile(
                          title: const Text("User 2",
                              style: TextStyle(color: Colors.white)),
                          subtitle: const Text("Very informative.",
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Suggested Videos (Only in Normal Mode)
          if (!isFullScreen)
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.black87,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Suggested Videos",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'SF Pro', fontWeight: FontWeight.bold),
                    ),
                    const Divider(color: Colors.white),

                    // Suggested Video 1
                    GestureDetector(
                      onTap: playNextVideo,
                      child: Row(
                        children: [
                          Container(
                            width: 100,
                            height: 60,
                            color: Colors.grey, // Placeholder for thumbnail
                            child: const Center(child: Icon(Icons.play_arrow, color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Sample Video 1",
                              style: TextStyle(color: Colors.white, fontFamily: 'SF Pro'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Suggested Video 2
                    GestureDetector(
                      onTap: playNextVideo,
                      child: Row(
                        children: [
                          Container(
                            width: 100,
                            height: 60,
                            color: Colors.grey, // Placeholder for thumbnail
                            child: const Center(child: Icon(Icons.play_arrow, color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Sample Video 2",
                              style: TextStyle(color: Colors.white, fontFamily: 'SF Pro'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
