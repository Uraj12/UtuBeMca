import 'package:flutter/material.dart';

class UserDetailsPage extends StatelessWidget {
  final Map<String, dynamic> user; // Receiving user data

  UserDetailsPage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user['username']), // Display username in AppBar
        backgroundColor: Colors.red, // Red theme
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.red,
                child: Icon(Icons.person, color: Colors.white, size: 40), // User Icon
              ),
            ),
            SizedBox(height: 20),
            Text("Username: ${user['username']}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Email: ${user['email']}",
                style: TextStyle(fontSize: 18, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
