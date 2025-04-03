import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'SharedPref.dart';
import 'main.dart';
import 'video_player_screen.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:chewie/chewie.dart';
import 'package:http_parser/http_parser.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<Map<String, dynamic>> _videoData = [];
  List<Map<String, dynamic>> _filteredVideos = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;
  File? _selectedVideo; // Variable to hold the selected video
  String _selectedVideoName = ''; // To show the name of the selected video
  double _uploadProgress = 0.0;
  List videos = [];
  bool isLoading = true;
  Map<String, String> _thumbnailCache = {};




  void main() {
    WidgetsFlutterBinding.ensureInitialized(); // ✅ Ensure plugins are initialized
    runApp(MyApp());
  }
  @override
  void initState() {
    super.initState();
    fetchVideos();
    _speech = stt.SpeechToText();
    _searchController.addListener(() {
      _updateSearchQuery(_searchController.text);
    });
  }

  Future<void> fetchVideos() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/get_videos/'));
      print("API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Data: $data"); // Check what the API returns

        final List videos = data['videos'];

        List<Map<String, dynamic>> updatedVideos = videos.map((video) {
          return {
            'video_id': video['video_id'], // ✅ Extract video_id
            'video_name': video['video_name'] ?? 'Unknown Video',
            'video_url': 'http://127.0.0.1:8000${video['video_url']}',
          };
        }).toList();

        setState(() {
          _videoData = updatedVideos;
          _filteredVideos = updatedVideos; // ✅ Ensure UI updates

          isLoading = false;
        });
      } else {
        print('Failed to load videos: ${response.body}');
      }
    } catch (e) {
      print('Error fetching videos: $e');
    }
  }


  //  Future<String?> generateThumbnail(String videoUrl) async {
  //    VideoPlayerController controller = VideoPlayerController.network(videoUrl);
  //
  //    await controller.initialize();
  //    await controller.seekTo(Duration(seconds: 0));
  //    await Future.delayed(Duration(milliseconds: 500));
  //
  //    if (controller.value.isInitialized) {
  //      return controller.value.thumbnail?.toString(); // Get the first frame
  //    }
  //
  //    return null;
  //
  // //   // final firstFrame = controller.value.position;
  // //   // controller.seekTo(firstFrame);
  //    ////
  //   // // return controller.value.isInitialized ? controller.value.thumbnail.toString() : null;
  //
  //    // final tempDir = await getTemporaryDirectory();
  //    // final filePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
  //    //
  //    // return await VideoThumbnail.thumbnailFile(
  //    //   video: videoUrl,
  //    //   thumbnailPath: '${tempDir.path}/thumb.jpg',
  //    //   imageFormat: ImageFormat.JPEG,
  //    //   maxHeight: 100,
  //    //   quality: 50,
  //    // );
  //
  //  }
  Future<void> _generateThumbnails() async {
    for (var video in _videoData) {
      String videoUrl = video['video_url'];
      if (!_thumbnailCache.containsKey(videoUrl)) {
        String? thumbnailPath = await generateThumbnail(videoUrl);
        if (thumbnailPath != null) {
          setState(() {
            _thumbnailCache[videoUrl] = thumbnailPath;
          });
        }
      }
    }
  }

  Future<String?> generateThumbnail(String videoUrl) async {
    try {
      VideoPlayerController controller = VideoPlayerController.network(videoUrl);
      await controller.initialize();

      final directory = await getTemporaryDirectory();
      final thumbnailPath = '${directory.path}/${videoUrl.hashCode}.png';

      RenderRepaintBoundary boundary = RenderRepaintBoundary();
      var image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData != null) {
        File file = File(thumbnailPath);
        await file.writeAsBytes(byteData.buffer.asUint8List());
        controller.dispose();
        return thumbnailPath;
      }
      controller.dispose();
    } catch (e) {
      print("Error generating thumbnail: $e");
      return null;
    }
    return null;
  }


  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      List<String> searchWords = _searchQuery.split(' ');
      _filteredVideos = _videoData.where((video) {
        String videoName = video['video_name'].toLowerCase();
        return searchWords.every((word) => videoName.contains(word));
      }).toList();
    });
  }

  // Video upload with description generation
  void _uploadVideo(BuildContext context) async {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    File? selectedFile;
    Uint8List? selectedFileBytes; // Store file bytes for Web
    String selectedFileName = "";
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    // if (result != null) {
    //   setState(() {
    //     _selectedVideo = File(result.files.single.path!);
    //     _selectedVideoName = result.files.single.name;
    //   });
    //   await _generateThumbnail(_selectedVideo!);
    // }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              height: MediaQuery.of(context).size.height * 0.9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Upload Video", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: "Video Title"),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Description",
                    ),
                  ),
                  SizedBox(height: 10),

                  // Auto Generate Description Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.autorenew), // Auto-generate icon
                        onPressed: () {
                          if (selectedFile != null || selectedFileBytes != null) {
                            _generateDescription(selectedFile, selectedFileBytes, descriptionController);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Please select a video first")),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  // Display selected video name
                  Text(
                    selectedFileName.isNotEmpty ? "Selected Video: $selectedFileName" : "No video selected",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selectedFileName.isNotEmpty ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);

                      if (result != null) {
                        setState(() {
                          selectedFileName = result.files.single.name;

                          if (kIsWeb) {
                            // For Web: Handle file as bytes
                            selectedFileBytes = result.files.single.bytes;
                            selectedFile = null;
                          } else {
                            // For Mobile/Desktop: Handle file using path
                            if (result.files.single.path != null) {
                              selectedFile = File(result.files.single.path!);
                              selectedFileBytes = null;
                            } else {
                              selectedFile = null;
                              selectedFileBytes = null;
                              print("Error: No file path available on mobile/desktop");
                            }
                          }
                        });
                        print("File selected: ${selectedFile?.path ?? 'No file path on mobile/desktop'}");
                        print("File bytes: ${selectedFileBytes?.length ?? 'No bytes on web'}");
                      } else {
                        print("No file selected");
                      }
                    },
                    icon: Icon(Icons.upload),
                    label: Text("Select Video"),
                    style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          print("Selected File Path: ${selectedFile?.path ?? 'No file selected'}");
                          print("Selected File Bytes: ${selectedFileBytes != null ? 'File loaded in memory (Web)' : 'No file bytes'}");

                          if (selectedFile != null || selectedFileBytes != null) {
                            _uploadVideoToServer(selectedFile, selectedFileBytes, titleController.text, descriptionController.text);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Please select a video first")),
                            );
                          }
                        },
                        child: Text("Upload"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),


                ],
              ),
            );
          },
        );
      },
    );
  }



  void _uploadVideoBytes(Uint8List fileBytes, String title) {
    // Implement the logic to upload video bytes to the server (for Web)
    print("Uploading video as bytes with title: $title");
  }


  // Generate video description by making API call
  Future<void> _generateDescription(
      File? file, Uint8List? selectedFileBytes, TextEditingController descriptionController) async {
    if (file == null && selectedFileBytes == null) {
      print("Error: No file selected");
      return;
    }

    String videoUrl = 'http://127.0.0.1:8000/generate_description/';
    var request = http.MultipartRequest('POST', Uri.parse(videoUrl));

    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath('video', file.path));
    } else if (selectedFileBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('video', selectedFileBytes, filename: 'video.mp4'));
    }

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);

        String hindiSummary = responseData['hindi_summary'] ?? 'No summary generated';

        // Ensure UI is updated safely
        descriptionController.text = hindiSummary;
      } else {
        throw Exception('Failed to generate transcription');
      }
    } catch (error) {
      print('Error generating transcription: $error');
    }
  }

  // Upload video to the server with progress
  Future<void> _uploadVideoToServer(File? videoFile, Uint8List? videoBytes, String title, String description) async {
    String url = 'http://127.0.0.1:8000/upload_video/';
    var request = http.MultipartRequest('POST', Uri.parse(url));

    request.fields['video_name'] = title;
    request.fields['description'] = description; // ✅ Ensure description is included

    try {
      if (videoFile != null) {
        print("Uploading Video from File: ${videoFile.path}");
        request.files.add(await http.MultipartFile.fromPath('video_file', videoFile.path));
      } else if (videoBytes != null) {
        print("Uploading Video from Bytes (Web)");
        request.files.add(http.MultipartFile.fromBytes(
          'video_file',
          videoBytes,
          filename: "$title.mp4",
          contentType: MediaType('video', 'mp4'),
        ));
      } else {
        throw Exception("No file selected for upload");
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Video uploaded successfully!")),
        );
        print("Server Response: ${response.body}");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload video")),
        );
        print("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Upload Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading video: $e")),
      );
    }
  }

// Function to update progress
  void _updateProgress(double progress) {
    setState(() {
      _uploadProgress = progress;
    });
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (errorNotification) => print('Speech error: $errorNotification'),
    );

    if (available) {
      _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _updateSearchQuery(result.recognizedWords);
          }
        },
      );
      setState(() => _isListening = true);
    } else {
      print("Speech recognition not available");
    }
  }

  @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     drawer: _buildDrawer(),
  //     appBar: AppBar(
  //       backgroundColor: Colors.black,
  //       title: Row(
  //         children: [
  //           Image.asset("assets/UTUBE.png", width: 100),
  //           const Spacer(),
  //           Expanded(child: _buildSearchBar()),
  //           IconButton(
  //             onPressed: () => _uploadVideo(context),
  //             icon: const Icon(CupertinoIcons.cloud_upload, color: Colors.white),
  //           ),
  //           const SizedBox(width: 10),
  //           CircleAvatar(
  //             radius: 16,
  //             backgroundImage: AssetImage("assets/UTUBE.png"),
  //           ),
  //           const SizedBox(width: 10),
  //           IconButton(
  //             onPressed: () {},
  //             icon: const Icon(CupertinoIcons.bell, color: Colors.white),
  //           ),
  //         ],
  //       ),
  //     ),
  //     body: isLoading
  //         ? const Center(child: CircularProgressIndicator())
  //         : ListView.builder(
  //       itemCount: _videoData.length,
  //       itemBuilder: (context, index) {
  //         String? thumbnailUrl = _videoData[index]['thumbnail_url'].isNotEmpty
  //             ? _videoData[index]['thumbnail_url']
  //             : null;
  //
  //         return GestureDetector(
  //           onTap: () {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) => VideoPlayerScreen(
  //                   videoUrl: _videoData[index]['video_url'],
  //                 ),
  //               ),
  //             );
  //           },
  //           child: Column(
  //             children: [
  //               Row(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   thumbnailUrl != null
  //                       ? Image.network(
  //                     thumbnailUrl,
  //                     width: 150,
  //                     height: 100,
  //                     fit: BoxFit.cover,
  //                   )
  //                       : FutureBuilder<String?>(
  //                     future: generateThumbnail(_videoData[index]['video_url']),
  //                     builder: (context, snapshot) {
  //                       if (snapshot.connectionState == ConnectionState.waiting) {
  //                         return Container(
  //                           width: 150,
  //                           height: 100,
  //                           color: Colors.grey,
  //                           child: const Center(child: CircularProgressIndicator()),
  //                         );
  //                       } else if (snapshot.hasError || snapshot.data == null) {
  //                         return Container(
  //                           width: 150,
  //                           height: 100,
  //                           color: Colors.grey,
  //                           child: const Center(child: Icon(Icons.play_arrow, color: Colors.white)),
  //                         );
  //                       } else {
  //                         return Image.file(
  //                           File(snapshot.data!),
  //                           width: 150,
  //                           height: 100,
  //                           fit: BoxFit.cover,
  //                         );
  //                       }
  //                     },
  //                   ),
  //                   SizedBox(width: 10),
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           _videoData[index]['video_name'],
  //                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  //                           maxLines: 2,
  //                           overflow: TextOverflow.ellipsis,
  //                         ),
  //                         SizedBox(height: 5),
  //                         Row(
  //                           children: [
  //                             CircleAvatar(radius: 14, backgroundColor: Colors.grey),
  //                             SizedBox(width: 5),
  //                             Text("Channel Name", style: TextStyle(color: Colors.grey)),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               Divider(color: Colors.grey),
  //             ],
  //           ),
  //         );
  //       },
  //     ),
  //     bottomNavigationBar: BottomNavigationBar(
  //       currentIndex: _selectedIndex,
  //       onTap: (index) => setState(() => _selectedIndex = index),
  //       selectedItemColor: Colors.red,
  //       unselectedItemColor: Colors.grey,
  //       items: const [
  //         BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), label: 'Home'),
  //         BottomNavigationBarItem(icon: Icon(CupertinoIcons.search), label: 'Search'),
  //         BottomNavigationBarItem(icon: Icon(CupertinoIcons.add_circled), label: 'Upload'),
  //         BottomNavigationBarItem(icon: Icon(CupertinoIcons.heart), label: 'Favorites'),
  //         BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profile'),
  //       ],
  //     ),
  //   );
  // }
  Future<String?> getEnrollment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('enrollmentNumber'); // 🎯 Fetch enrollment
  }
  Future<void> logVideoWatch(int videoId, video) async {
    String? enrollment = await SharedPrefService.getString('enrollmentNumber');

    if (enrollment == null || enrollment.isEmpty) {
      print("❌ Enrollment number is missing");
      return;
    }

    final url = Uri.parse("http://127.0.0.1:8000/video/watch/");

    print("🚀 Sending API Request to: $url");
    print("📌 Request Body: {enrollment: $enrollment, video_id: $videoId}");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "enrollment": enrollment,
          "video_id": videoId
        }),
      );

      print("📌 Response Status: ${response.statusCode}");
      print("📌 Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ Video view logged successfully");
      } else {
        print("❌ Failed to log video watch: ${response.body}");
      }
    } catch (e) {
      print("❌ Error logging video watch: $e");
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            Image.asset("assets/UTUBE.png", width: 100),
            const Spacer(),
            Expanded(child: _buildSearchBar()),
            IconButton(
              onPressed: () => _uploadVideo(context),
              icon: const Icon(CupertinoIcons.cloud_upload, color: Colors.white),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage("assets/UTUBE.png"),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {},
              icon: const Icon(CupertinoIcons.bell, color: Colors.white),
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 16 / 9,
          ),
          itemCount: _filteredVideos.length,
          itemBuilder: (context, index) {
            final video = _filteredVideos[index];
            return GestureDetector(
              onTap: () async {
                print("🛠 Video tapped! Checking enrollment...");

                String? enrollment = await getEnrollment();
                print("🎓 Enrollment: ${enrollment ?? 'NULL'}");

                print("🧐 Full video object: $video");

                // ✅ Ensure `video_id` and `video_url` exist
                if (video['video_id'] == null || video['video_url'] == null || video['video_url'].toString().trim().isEmpty) {
                  print("❌ Invalid video data! video_id: ${video['video_id']}, video_url: ${video['video_url']}");
                  return;
                }

                // ✅ Convert `enrollment` to `int` properly
                int? enrollmentNumber = int.tryParse(enrollment ?? '');
                if (enrollmentNumber == null) {
                  print("❌ Enrollment number is invalid!");
                  return;
                }

                try {
                  print("🚀 Calling logVideoWatch with Video ID: ${video['video_id']}");

                  // ✅ Call API with correct types
                  await logVideoWatch(video['video_id'], {"enrollment": enrollmentNumber});

                  print("✅ logVideoWatch executed!");

                  print("🎥 Navigating to VideoPlayerScreen...");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        videoId: video['video_id'],
                        videoUrl: video['video_url'],
                        channelName: '',
                        channelLogo: '', videoTitle: '', videoDescription: '', title: null,
                      ),
                    ),
                  );

                } catch (e) {
                  print("❌ Error: $e");
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: VideoThumbnailWidget(videoUrl: video['video_url']),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    video['video_name'],
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Channel Name",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );






          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.add_circled), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.heart), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _updateSearchQuery,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search for videos...',
          hintStyle: TextStyle(color: Colors.white70, fontSize: 16),
          filled: true,
          fillColor: Colors.black,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey, width: 2),
          ),
          prefixIcon: Icon(Icons.search, color: Colors.white70, size: 24),
          suffixIcon: IconButton(
            icon: Icon(CupertinoIcons.mic, color: Colors.redAccent, size: 24),
            onPressed: () {
              if (!_isListening) {
                _startListening();
              } else {
                setState(() => _isListening = false);
                _speech.stop();
              }
            },
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
    );
  }
  String getFullVideoUrl(String videoUrl) {
    return videoUrl.startsWith("http") ? videoUrl : "http://127.0.0.1:8000$videoUrl";
  }

  Widget _buildVideoGrid() {
    List<dynamic> validVideos = videos.where((video) =>
    video['video_url'] != null &&
        video['video_url'].toString().trim().isNotEmpty &&
        !video['video_url'].contains('.mp4_')  // Exclude invalid formats
    ).toList();


    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5.0,
        mainAxisSpacing: 5.0,
      ),
      itemCount: validVideos.length,
      itemBuilder: (context, index) {
        final video = validVideos[index];

        return GestureDetector(
          onTap: () async {
            print("🛠 Video tapped! Checking enrollment...");

            String? enrollment = await getEnrollment();
            print("🎓 Enrollment: ${enrollment ?? 'NULL'}");

            print("🧐 Full video object: $video");

            if (video['video_id'] == null || video['video_url'] == null || video['video_url'].toString().trim().isEmpty) {
              print("❌ Invalid video data! video_id: ${video['video_id']}, video_url: ${video['video_url']}");
              return;
            }

            int? enrollmentNumber = int.tryParse(enrollment ?? '');
            if (enrollmentNumber == null) {
              print("❌ Enrollment number is invalid!");
              return;
            }

            try {
              print("🚀 Calling logVideoWatch with Video ID: ${video['video_id']}");

              final url = Uri.parse("http://127.0.0.1:8000/log_video_watch");  // Use 127.0.0.1 for browser

              await logVideoWatch(video['video_id'], {"enrollment": enrollmentNumber});

            } catch (e) {
              print("❌ Error logging video watch: $e");
            }

            if (mounted) {
              print("🎥 Navigating to VideoPlayerScreen...");
              setState(() {});  // Force UI Refresh

              Navigator.pushNamed(
                context,
                '/videoPlayer',
                arguments: {
                  'videoId': video['video_id'],
                  'videoUrl': video['video_url'],
                  'channelName': '',
                  'channelLogo': '',
                },
              );
            }
          },
        );


      },
    );
  }

// Widget _buildDrawer() {
//   return Drawer(
//     child: ListView(
//       padding: EdgeInsets.zero,
//       children: [
//         const UserAccountsDrawerHeader(
//           accountName: Text("Shubham", style: TextStyle(fontSize: 18)),
//           accountEmail: Text("shubham123@gmail.com"),
//           currentAccountPicture: CircleAvatar(
//             backgroundImage: AssetImage("assets/UTUBE.png"),
//           ),
//         ),
//         ListTile(
//           title: const Text('Profile'),
//           onTap: () {},
//         ),
//         ListTile(
//           title: const Text('Favorites'),
//           onTap: () {},
//         ),
//         ListTile(
//           title: const Text('Logout'),
//           onTap: () {},
//         ),
//       ],
//     ),
//   );
// }
}





class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;

  VideoThumbnailWidget({required this.videoUrl});

  @override
  _VideoThumbnailWidgetState createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  late VideoPlayerController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.pause(); // Show first frame as a thumbnail
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() {
      _isHovered = hovering;
      if (hovering) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to full video player screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(videoUrl: widget.videoUrl, channelName: '', channelLogo: '', videoId: null, videoTitle: '', videoDescription: '', title: null,),
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: _controller.value.isInitialized
              ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
              : Container(
            width: double.infinity,
            height: 100,
            color: Colors.grey, // Placeholder when video is not initialized
          ),
        ),
      ),
    );
  }
}










class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  VideoPlayerWidget({required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isMuted = true;
  bool _isHovered = false; // Track hover state

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.setVolume(_isMuted ? 0.0 : 1.0); // Start muted
        _controller.play();
      });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: _isHovered ? Matrix4.translationValues(0, -10, 0) : Matrix4.identity(), // Push-up effect
        child: Stack(
          children: [
            // Video Player
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: _controller.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
                  : Container(
                width: double.infinity,
                height: 100,
                color: Colors.grey,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

            // Mute/Unmute Button (Overlay at Top-Right)
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
