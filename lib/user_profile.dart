import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Used only for colors

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.black,
        middle: const Text(
          "Profile",
          style: TextStyle(color: Colors.white),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {},
          child: const Icon(CupertinoIcons.settings, color: Colors.white),
        ),
      ),
      child: SafeArea(
        child: Container(
          color: Colors.black, // Background color
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile Avatar
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage("assets/UTUBE.png"),
              ),

              const SizedBox(height: 10),

              // User Name
              const Text(
                "Shubham Gupta",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),

              // Subscribers Count
              const Text(
                "1.2M Subscribers",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 15),

              // Profile Actions (Edit Profile, Switch Account, Sign Out)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildProfileButton("Edit Profile"),
                  const SizedBox(width: 10),
                  _buildProfileButton("Switch Account"),
                  const SizedBox(width: 10),
                  _buildProfileButton("Sign Out"),
                ],
              ),

              const SizedBox(height: 20),

              // Segmented Control (Tabs for Videos & Playlists)
              CupertinoSlidingSegmentedControl<int>(
                backgroundColor: Colors.grey[900] ?? Colors.black,
                thumbColor: Colors.red,
                groupValue: 0,
                onValueChanged: (int? value) {},
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text("Videos", style: TextStyle(color: Colors.white)),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text("Playlists", style: TextStyle(color: Colors.white)),
                  ),
                },
              ),

              const SizedBox(height: 10),

              // Video List
              Expanded(
                child: _buildVideoList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Profile Action Buttons (Pure Cupertino)
  Widget _buildProfileButton(String text) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red, // Red button color
      borderRadius: BorderRadius.circular(20),
      onPressed: () {},
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  // Dummy Video List (Cupertino)
  Widget _buildVideoList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return CupertinoListTile(
          backgroundColor: Colors.grey[900], // Dark grey background
          leading: Container(
            width: 100,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[850], // Slightly lighter dark grey
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Center(
              child: Icon(CupertinoIcons.play_arrow_solid, color: Colors.red),
            ),
          ),
          title: Text(
            "Video Title ${index + 1}",
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            "1.5M views • 2 days ago",
            style: TextStyle(color: Colors.grey),
          ),
          onTap: () {}, // Navigate to video details
        );
      },
    );
  }
}
