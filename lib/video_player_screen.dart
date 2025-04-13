

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import "package:share_plus/share_plus.dart";
import 'dart:typed_data';

import 'SharedPref.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String videoDescription;
  final String channelName;
  final String channelLogo;


  const VideoPlayerScreen({super.key, required this.videoUrl, required this.videoTitle, required this.videoDescription, required this.channelName, required this.channelLogo, required videoId, required title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;
  bool isFullScreen = false;
  bool isLiked = false;
  String videoSummary = "";
  bool isLoadingSummary = false;
  List<Map<String, dynamic>> suggestedVideos = [];
  bool isLoadingSuggestions = true;
  late String videoTitle = "No Title"; // default
  final TextEditingController _commentController = TextEditingController(); // Comment controller
  List<String> comments = [];
  late int videoId;
  late String videoUrl;
  late String channelName;
  late String channelLogo;

  bool _isArgsLoaded = false;

  @override
  void initState() {
    super.initState();
    fetchSuggestedVideos();
    initializePlayer(widget.videoUrl);


    print("Received Video Title: ${widget.videoTitle}");
  }

  @override
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isArgsLoaded) {
      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      if (routeArgs != null && routeArgs is Map<String, dynamic>) {
        videoId = routeArgs['videoId'];
        videoTitle = routeArgs['videoTitle'] ?? 'No Title';
        videoUrl = routeArgs['videoUrl'] ?? '';
        channelName = routeArgs['channelName'] ?? '';
        channelLogo = routeArgs['channelLogo'] ?? '';

        initializePlayer(videoUrl);
      } else {
        print("⚠️ Route arguments are null or in unexpected format.");
      }

      _isArgsLoaded = true;
    }
  }

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        comments.add(_commentController.text); // Add comment to the list
        _commentController.clear(); // Clear input field
      });
    }
  }
  Future<void> initializePlayer(String url) async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: {'Range': 'bytes=0-500000'}, // Load only part of the video initially
    );

    await _controller.initialize();
    if (mounted) {
      setState(() {});
    }

    _chewieController = ChewieController(
      videoPlayerController: _controller,
      aspectRatio: _controller.value.isInitialized ? _controller.value.aspectRatio : 16 / 9,
      autoPlay: true,
      looping: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red, // Change progress bar color to red
        handleColor: Colors.redAccent,
        bufferedColor: Colors.white54,
        backgroundColor: Colors.grey,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    super.dispose();
  }


  // void playNextVideo() async {
  //   String nextVideoUrl = 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4';
  //
  //   await _controller.pause();
  //   _controller.dispose();
  //   _chewieController.dispose();
  //
  //   if (mounted) {
  //     setState(() {
  //       initializePlayer(nextVideoUrl);
  //     });
  //   }
  // }
  void playNextVideo(String? video) {
    setState(() {
      _controller.pause();
      _controller = VideoPlayerController.network(
        'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
      )..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: true,
        looping: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red, // Change progress bar color to red
          handleColor: Colors.redAccent,
          bufferedColor: Colors.white54,
          backgroundColor: Colors.grey,
        ),
      );
    });
  }
  void likeVideo(int videoId, bool isLiked) async {
    final url = Uri.parse("http://127.0.0.1:8000/like/");

    // Fetch dynamically stored enrollment number
    final String? enrollment = await SharedPrefService.getString('enrollmentNumber');

    if (enrollment == null || enrollment.isEmpty) {
      print("❌ Enrollment number not found!");
      return;
    }

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "enrollment": enrollment,
          "video_id": videoId,
          "status": isLiked ? "unlike" : "like"
        }),
      );

      final data = jsonDecode(response.body);
      print("Response: ${data['message']}");

      if (response.statusCode == 200) {
        setState(() {
          isLiked = !isLiked;
        });
      } else {
        print("Error: ${data['error']}");
      }
    } catch (e) {
      print("Exception: $e");
    }
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

      var videoBytes = response.bodyBytes;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/summarize/'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          videoBytes as List<int>,
          filename: "video.mp4",
        ),
      );

      var streamedResponse = await request.send();
      var finalResponse = await http.Response.fromStream(streamedResponse);

      if (finalResponse.statusCode == 200) {
        var data = jsonDecode(finalResponse.body);
        setState(() {
          videoSummary = data['english_summary'] ?? "No summary available.";

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
    setState(() => isLoadingSuggestions = true);

    try {
      final response = await http.get(Uri.parse("http://127.0.0.1:8000/video/suggested/"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body); // Convert JSON string to Map
        final List<dynamic> videos = data["suggested_videos"] ?? [];

        setState(() {
          suggestedVideos = videos.map<Map<String, dynamic>>((video) {
            return {
              "videoUrl": video["video_url"]?.toString() ?? "",
              "title": video["video_name"]?.toString() ?? "No Title",
              "watchCount": video["watch_count"] ?? 0,
              "likeCount": video["like_count"] ?? 0,
              "thumbnail": video["thumbnail"]?.toString().isNotEmpty == true
                  ? video["thumbnail"].toString()
                  : "https://via.placeholder.com/100x60?text=No+Image",
              "description": video["description"]?.toString() ?? "",
              "channelName": video["channel_name"]?.toString() ?? "",
              "channelLogo": video["channel_logo"]?.toString() ?? "",
            };
          }).toList();
          isLoadingSuggestions = false; // ✅ Stop loading after fetching
        });

        // Debugging logs
        print("✅ Successfully fetched ${suggestedVideos.length} videos");
        for (var video in suggestedVideos) {
          print("🔹 Video Name: ${video["title"]}");
          print("🎥 Video URL: ${video["videoUrl"]}");
          print("👍 Likes: ${video["likeCount"]}");
          print("👀 Watches: ${video["watchCount"]}");
        }
      } else {
        print("❌ Failed to fetch videos. Status Code: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: Unable to fetch videos"))
        );
        setState(() => isLoadingSuggestions = false); // ✅ Ensure loading stops
      }
    } catch (e) {
      print("❌ Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"))
      );
      setState(() => isLoadingSuggestions = false); // ✅ Ensure loading stops
    }
  }

  Future<void> _addCommentofvideo() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final String? enrollment = await SharedPrefService.getString('enrollmentNumber');

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/add_comment'), // or your actual URL
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "enrollment": enrollment,
        "video_id": videoId, // 👈 directly using the class variable
        "comment": commentText,
      }),
    );

    if (response.statusCode == 201) {
      setState(() {
        comments.add(commentText);
        _commentController.clear();
      });
    } else {
      print("Failed to add comment: ${response.body}");
    }
  }
  void checkVideoUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      print("🔹 Video URL Check: ${response.statusCode}");
      if (response.statusCode == 200) {
        print("✅ Video is accessible: $url");
      } else {
        print("❌ Video is not accessible: $url");
      }
    } catch (e) {
      print("❌ Error accessing video: $e");
    }
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main video section
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 15, right: 20),
              child: SingleChildScrollView(
              child: Column(
                children: [
                  // Video Player
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: _controller.value.isInitialized
                          ? _controller.value.aspectRatio
                          : 14 / 7,
                      child: _controller.value.isInitialized
                          ? Chewie(controller: _chewieController)
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Video Title and Buttons (Like, Dislike, Share)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          videoTitle.isNotEmpty ? videoTitle : "No Title",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Like Button
                      IconButton(
                        icon: AnimatedSwitcher(
                          duration: Duration(milliseconds: 300), // Smooth effect
                          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border, // Change icon
                            key: ValueKey<bool>(isLiked), // Unique key for animation
                            color: isLiked ? Colors.red : Colors.white, // Change color
                            size: isLiked ? 32 : 28, // Slight size increase when liked
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            isLiked = !isLiked; // Toggle like state
                          });
                          likeVideo(1, isLiked); // Call API when user clicks like
                        },
                      ),

                      // Share Button
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () {
                          Share.share(widget.videoUrl);
                        },
                      ),
                    ],
                  ),
                  // Video Description
                  ElevatedButton(
                    onPressed: fetchVideoSummary,
                    child: isLoadingSummary ? CircularProgressIndicator() : Text("Generate Summary"),
                  ),
                  if (videoSummary.isNotEmpty) ...[
                    Text(videoSummary, style: TextStyle(color: Colors.white)),
                    ElevatedButton(
                      onPressed: () => Share.share(videoSummary),
                      child: Text("Share Summary"),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Comments Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Comments (${comments.length})", // Display comment count
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send, color: Colors.blue),
                        onPressed: _addComment,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(Icons.account_circle, color: Colors.white),
                        title: Text(comments[index], style: TextStyle(color: Colors.white)),
                      );
                    },
                  ),
                ],
              ),
              ),
            ),
          ),

          // Suggested videos section


          Expanded(
            child: isLoadingSuggestions
                ? const Center(child: CircularProgressIndicator())
                : suggestedVideos.isEmpty
                ? const Center(
              child: Text(
                "No suggested videos available.",
                style: TextStyle(color: Colors.white),
              ),
            )
                : ListView.builder(
              itemCount: suggestedVideos.length,
              itemBuilder: (context, index) {
                final video = suggestedVideos[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(
                          videoUrl: video["videoUrl"],
                          videoTitle: video["title"],  // ✅ Pass the correct title dynamically
                          videoDescription: video["description"] ?? "",
                          channelName: video["channelName"] ?? "",
                          channelLogo: video["channelLogo"] ?? "",
                          videoId: null,
                          title: video["title"],  // ✅ Pass the title here as well
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Thumbnail Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            video["thumbnail"] ?? "https://via.placeholder.com/100x60?text=No+Image",
                            width: 100,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 60,
                                color: Colors.grey,
                                child: const Icon(Icons.play_arrow, color: Colors.white),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Video Info with Like & Watch Count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video["title"],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // 👍 Like & 👀 Watch Count Display
                              Row(
                                children: [
                                  Icon(Icons.thumb_up, color: Colors.red, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${video["likeCount"]} Likes",
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.visibility, color: Colors.blue, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${video["watchCount"]} Views",
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )

          ),
        ],
      ),
    );
  }
}