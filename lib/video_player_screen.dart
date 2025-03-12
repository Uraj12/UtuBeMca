import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String channelName;
  final String channelLogo;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.channelName,
    required this.channelLogo, required videoId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool isLiked = false;
  bool isDisliked = false;
  bool isFullScreen = false;
  String videoSummary = "";
  bool isLoadingSummary = false;
  List<Map<String, String>> suggestedVideos = [];
  bool isLoadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchVideoSummary() async {
    setState(() {
      isLoadingSummary = true;
    });

    try {
      var response = await http.get(Uri.parse(widget.videoUrl));
      if (response.statusCode != 200) {
        throw Exception("Failed to fetch video");
      }

      Uint8List videoBytes = response.bodyBytes;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/summarize/'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          videoBytes,
          filename: "video.mp4",
        ),
      );

      var streamedResponse = await request.send();
      var finalResponse = await http.Response.fromStream(streamedResponse);

      if (finalResponse.statusCode == 200) {
        var data = jsonDecode(finalResponse.body);
        setState(() {
          videoSummary = "**English:**\n${data['english_summary'] ?? "No summary available."}\n\n"
              "**हिन्दी प्रतिलिपि:**\n${data['hindi_transcription'] ?? "कोई प्रतिलिपि उपलब्ध नहीं है।"}";
        });
      } else {
        setState(() {
          videoSummary = "Error: ${finalResponse.body}";
        });
      }
    } catch (e) {
      setState(() {
        videoSummary = "Failed: $e";
      });
    } finally {
      setState(() {
        isLoadingSummary = false;
      });
    }
  }
  Future<void> fetchSuggestedVideos() async {
    try {
      final url = Uri.parse("http://127.0.0.1:8000/video/suggested/");
      print("🔹 Fetching from: $url");

      final response = await http.get(url);

      print("✅ API Status Code: ${response.statusCode}");
      print("✅ API Response Body: ${response.body}"); // Debug API response

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data["suggested_videos"] == null || data["suggested_videos"].isEmpty) {
          print("❌ No suggested videos found in API response");
        } else {
          print("✅ Suggested videos received: ${data["suggested_videos"].length}");
        }

        setState(() {
          suggestedVideos = List<Map<String, String>>.from(
            data["suggested_videos"].map((video) {
              print("📌 Processing video: $video");

              return {
                "videoUrl": video["video_url"] != null
                    ? "http://127.0.0.1:8000${video["video_url"]}"
                    : "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4", // Placeholder video
                "title": video["video_name"] ?? "No title",
                "channelName": video.containsKey("channel_name") ? video["channel_name"] : "Unknown Channel",
                "channelLogo": video.containsKey("channel_logo") ? video["channel_logo"] : "",
                "thumbnail": video.containsKey("thumbnail") ? video["thumbnail"] : "",
              };
            }),
          );

          print("✅ Fetched ${suggestedVideos.length} videos");
          isLoadingSuggestions = false;
        });
      } else {
        throw Exception("❌ Failed to load suggested videos. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoadingSuggestions = false;
      });
      print("❌ Error fetching suggested videos: $e");
    }
  }
  void likeVideo(int videoId, bool isLiked) async {
    final url = Uri.parse("http://127.0.0.1:8000/like/");
    final String enrollment = "202404104610003"; // Fetch dynamically in a real app

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "enrollment": enrollment,
          "video_id": videoId,
          "status": isLiked ? null : "like"  // Set "like", remove entry if already liked
        }),
      );

      final data = jsonDecode(response.body);
      print("Response: ${data['message']}");

      if (response.statusCode == 200) {
        setState(() {
          isLiked = !isLiked; // Toggle like state
        });
      } else {
        print("Error: ${data['error']}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }


  void toggleFullScreen() {
    setState(() {
      isFullScreen = !isFullScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller.value.isInitialized
                ? _controller.value.aspectRatio
                : 16 / 9,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                _controller.value.isInitialized
                    ? VideoPlayer(_controller)
                    : const Center(child: CircularProgressIndicator()),

                // Video Controls
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      // Progress Bar
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.red,
                          bufferedColor: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10, color: Colors.white),
                            onPressed: () {
                              _controller.seekTo(
                                _controller.value.position - const Duration(seconds: 10),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.forward_10, color: Colors.white),
                            onPressed: () {
                              _controller.seekTo(
                                _controller.value.position + const Duration(seconds: 10),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: Colors.white,
                            ),
                            onPressed: toggleFullScreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Video Details and Interactions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.channelLogo),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.channelName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: isLiked ? Colors.blue : Colors.white,
                      ),
                      onPressed: () {
                        likeVideo(1, isLiked); // Call API when user clicks like
                      },
                    ),

                    IconButton(
                      icon: Icon(
                        isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                        color: isDisliked ? Colors.blue : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          isDisliked = !isDisliked;
                          if (isLiked) isLiked = false;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: fetchVideoSummary,
                  child: const Text("Generate Summary"),
                ),
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      videoSummary,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Suggested Videos",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 120, // Fixed height for horizontal scrolling
                  child: suggestedVideos.isEmpty
                      ? const Center(

                  )
                      : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: suggestedVideos.length,
                    itemBuilder: (context, index) {
                      var video = suggestedVideos[index];
                      print("🔹 Rendering video: ${video["title"]}");

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerScreen(
                                videoUrl: video["videoUrl"]!,
                                channelName: video["channelName"]!,
                                channelLogo: video["channelLogo"]!, videoId: null,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  video["thumbnail"] != null && video["thumbnail"]!.isNotEmpty
                                      ? video["thumbnail"]!
                                      : "https://via.placeholder.com/160x80?text=No+Image",
                                  height: 80,
                                  width: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.network(
                                      "https://via.placeholder.com/160x80?text=Error",
                                      height: 80,
                                      width: 160,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                video["title"] ?? "No Title",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
