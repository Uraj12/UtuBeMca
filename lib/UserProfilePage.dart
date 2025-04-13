import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? _profileImagePath;
  String _enrollmentNumber = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// ✅ Load user profile details (Profile Image + Enrollment Number)
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profile_image');
      _enrollmentNumber = prefs.getString('enrollment_number') ?? "Not Set";
    });
    print("Loaded Image Path: $_profileImagePath");
  }

  /// ✅ Pick a profile image from the gallery and save it
  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final newImagePath = '${directory.path}/profile_picture.png';
      final imageFile = File(pickedFile.path);

      // ✅ Copy Image to App Directory
      await imageFile.copy(newImagePath);

      // ✅ Save Path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', newImagePath);

      // ✅ UI Update Immediately
      setState(() {
        _profileImagePath = newImagePath;
      });

      print("Profile Image Updated: $_profileImagePath"); // Debugging
    }
  }

  /// ✅ Save Profile Image Path to SharedPreferences
  Future<void> _saveProfileImage() async {
    if (_profileImagePath != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', _profileImagePath!);

      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green),
      );

      // ✅ Update UI immediately
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Profile Image Upload
              GestureDetector(
                onTap: _pickProfileImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _profileImagePath != null && File(_profileImagePath!).existsSync()
                      ? FileImage(File(_profileImagePath!)) // Show selected image
                      : null,
                  child: _profileImagePath == null || !File(_profileImagePath!).existsSync()
                      ? const Icon(Icons.person, size: 60, color: Colors.black) // Default icon
                      : null,
                ),
              ),
              const SizedBox(height: 15),

              // ✅ Save Profile Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfileImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 5,
                  ),
                  child: const Text("Save Profile", style: TextStyle(color: Colors.white)),
                ),
              ),

              // ✅ Enrollment Number
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Enrollment No: $_enrollmentNumber",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}