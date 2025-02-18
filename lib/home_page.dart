import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'video_player_screen.dart';

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
  late stt.SpeechToText _speech;
  bool _isListening = false;
  File? _selectedVideo; // Variable to hold the selected video
  String _selectedVideoName = ''; // To show the name of the selected video
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    fetchVideos();
    _speech = stt.SpeechToText();
  }

  Future<void> fetchVideos() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:8000/get_videos/'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List videos = data['videos'];

      setState(() {
        _videoData = videos.map((video) {
          return {
            'video_name': video['video_name'] ?? 'Unknown Video',
            'video_url': 'http://127.0.0.1:8000${video['video_url']}',
          };
        }).toList();
      });
    } else {
      print('Failed to load videos');
    }
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _searchController.text = query; // Update UI with voice input
    });
  }

  // Video upload with description generation
  void _uploadVideo(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    bool isGeneratingDescription = false;

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
                      suffixIcon: isGeneratingDescription
                          ? CircularProgressIndicator()
                          : IconButton(
                        icon: Icon(Icons.auto_awesome),
                        onPressed: () {
                          setState(() {
                            isGeneratingDescription = true;
                          });

                          // Call API to generate description
                          _generateDescription();
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
                      if (result != null) {
                        File videoFile = File(result.files.single.path!);
                        _uploadVideoToServer(videoFile, titleController.text);
                        Navigator.pop(context);
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
                        onPressed: () => Navigator.pop(context),
                        child: Text("Upload"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  // Generate video description by making API call
  Future<void> _generateDescription() async {
    String videoUrl = 'http://127.0.0.1:8000/generate_description/'; // Replace with actual URL

    try {
      final response = await http.post(
        Uri.parse(videoUrl),
        body: json.encode({
          'video_id': 'your_video_id_here', // Replace with the actual video ID
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          TextEditingController descriptionController = TextEditingController();
        });
      } else {
        throw Exception('Failed to generate description');
      }
    } catch (error) {
      print('Error generating description: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate description')));
    }
  }

  // Upload video to the server with progress
  Future<void> _uploadVideoToServer(File videoFile, String title) async {
    String url = 'http://127.0.0.1:8000/upload_video/';
    var request = http.MultipartRequest('POST', Uri.parse(url));

    request.fields['video_name'] = title;

    if (kIsWeb) {
      Uint8List videoBytes = videoFile.readAsBytesSync();
      request.files.add(http.MultipartFile.fromBytes('video_file', videoBytes, filename: 'video.mp4'));
    } else {
      request.files.add(await http.MultipartFile.fromPath('video_file', videoFile.path));
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Uploading Video..."),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: _uploadProgress),
            SizedBox(height: 20),
            Text("${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded"),
          ],
        ),
      ),
    );

    var streamedResponse = await request.send();

    int totalBytes = videoFile.lengthSync();
    int uploadedBytes = 0;

    streamedResponse.stream.listen(
          (List<int> chunk) {
        uploadedBytes += chunk.length;
        setState(() {
          _uploadProgress = uploadedBytes / totalBytes;
        });
      },
      onDone: () async {
        Navigator.pop(context);

        if (streamedResponse.statusCode == 200) {
          final response = await http.Response.fromStream(streamedResponse);
          final responseData = json.decode(response.body);

          final videoUrl = responseData['video_url'] ?? '';

          print('Video uploaded successfully');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video uploaded successfully')));

          print('Video URL: $videoUrl');
        } else {
          print('Failed to upload video');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload video')));
        }
      },
      onError: (error) {
        print('Error uploading video: $error');
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading video')));
      },
    );
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (errorNotification) => print('Speech error: $errorNotification'),
    );

    if (available) {
      setState(() => _isListening = true);
      print("Listening started...");

      _speech.listen(
        onResult: (result) {
          print("Recognized Words: ${result.recognizedWords}");
          _updateSearchQuery(result.recognizedWords);
        },
        listenFor: const Duration(seconds: 5),
      );
    } else {
      print("Speech recognition not available.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
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
      body: _buildVideoGrid(),
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
    return TextField(
      controller: _searchController,
      onChanged: _updateSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search for videos...',
        suffixIcon: IconButton(
          icon: const Icon(CupertinoIcons.mic),
          onPressed: () {
            if (!_isListening) {
              _startListening();
            } else {
              setState(() => _isListening = false);
              _speech.stop();
            }
          },
        ),
      ),
    );
  }

  Widget _buildVideoGrid() {
    final filteredVideos = _videoData.where((video) {
      return video['video_name']!.toLowerCase().contains(_searchQuery);
    }).toList();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5.0,
        mainAxisSpacing: 5.0,
      ),
      itemCount: filteredVideos.length,
      itemBuilder: (context, index) {
        final video = filteredVideos[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(videoUrl: video['video_url']),
              ),
            );
          },
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Image.asset('assets/thumbnail.png', fit: BoxFit.cover, height: 90, width: 120),
                Text(video['video_name'], style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text("Shubham", style: TextStyle(fontSize: 18)),
            accountEmail: Text("shubham123@gmail.com"),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage("assets/UTUBE.png"),
            ),
          ),
          ListTile(
            title: const Text('Profile'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Favorites'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Logout'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
