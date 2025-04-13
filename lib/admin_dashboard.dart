import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'user_details_page.dart';

// ApiService class to fetch data from Django API
class ApiService {
  final String baseUrl = 'http://127.0.0.1:8001/api/dashboard/'; // Your Django API URL

  // Function to fetch stats from the Django API
  Future<Map<String, dynamic>> fetchStats() async {
    final response = await http.get(Uri.parse(baseUrl + 'stats/'));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON data
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      // If the server does not return a 200 OK response, throw an error
      throw Exception('Failed to load stats');
    }
  }

  // Fetch users data
  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(Uri.parse(baseUrl + 'users/'));

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Fetch videos data
  Future<List<dynamic>> fetchVideos() async {
    final response = await http.get(Uri.parse(baseUrl + 'videos/'));

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load videos');
    }
  }
}

void main() {
  runApp(AdminDashboardApp());
}

class AdminDashboardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.red,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 5,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardColor: Colors.black,
      ),
      home: AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<Map<String, dynamic>> _stats;
  final ApiService _apiService = ApiService();

  // Add these methods for user operations
  Future<void> updateUser(int userId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:8001/api/dashboard/edit/update_user/$userId/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        // Refresh the stats and user list
        setState(() {
          _stats = _apiService.fetchStats();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User updated successfully'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:8001/api/dashboard/edit/delete_user/$userId/'),
      );

      if (response.statusCode == 200) {
        // Refresh the stats and user list
        setState(() {
          _stats = _apiService.fetchStats();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    TextEditingController passwordController = TextEditingController(text: user['password']);
    int statusValue = user['status'] ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Edit User",
              style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Password Field
              TextFormField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: Colors.redAccent),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 15),

              // Status Dropdown
              DropdownButtonFormField<int>(
                value: statusValue,
                dropdownColor: Colors.grey[900],
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Status",
                  labelStyle: TextStyle(color: Colors.redAccent),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: [
                  DropdownMenuItem(value: 0, child: Text("Inactive", style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 1, child: Text("Active", style: TextStyle(color: Colors.white))),
                ],
                onChanged: (value) {
                  statusValue = value ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                // Update user with new data
                updateUser(user['user_id'], {
                  'password': passwordController.text,
                  'status': statusValue,
                });
                Navigator.pop(context);
              },
              child: Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Delete User",
              style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
          content: Text(
            "Are you sure you want to delete this user?",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                deleteUser(user['user_id']);
                Navigator.pop(context);
              },
              child: Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Update the user list item trailing widgets
  Widget _buildUserListItem(Map<String, dynamic> user) {
    return Card(
      color: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red, width: 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(10),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.red,
          child: Icon(Icons.person, color: Colors.white, size: 30),
        ),
        title: Text(
          user['enrollment'].toString(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          user['status'].toString() == '1' ? 'Active' : 'Inactive',
          style: TextStyle(
            color: user['status'].toString() == '1' ? Colors.green : Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.visibility, color: Colors.blueAccent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserDetailsPage(user: user),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.greenAccent),
              onPressed: () => _showEditUserDialog(context, user),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _showDeleteConfirmation(context, user),
            ),
          ],
        ),
      ),
    );
  }

  // Update the user modal to use the new list item builder
  void _showUserModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                height: 5,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  "User List",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: ApiService().fetchUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Colors.red));
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.red)
                        ),
                      );
                    } else if (snapshot.hasData) {
                      final users = snapshot.data!;
                      return Scrollbar(
                        thickness: 3,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.all(10),
                          itemCount: users.length,
                          itemBuilder: (context, index) => _buildUserListItem(users[index]),
                        ),
                      );
                    } else {
                      return Center(
                        child: Text(
                          'No users available',
                          style: TextStyle(color: Colors.white)
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _stats = ApiService()
        .fetchStats(); // Fetch the stats when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Center(
                child: Text(
                  "UTU-BE",
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic, // Italic text
                    fontFamily: "cursive", // Default cursive font
                    letterSpacing: 2.0, // Adds spacing between letters
                    color: Colors.black, // Red text color
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildDrawerItem("Dashboard", Icons.dashboard),
            _buildDrawerItem("Reports", Icons.bar_chart),
            _buildDrawerItem("Logout", Icons.logout),

          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _stats, // Wait for the stats to be fetched
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator()); // Show loading indicator while waiting
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}',
                style: TextStyle(color: Colors
                    .red))); // Show error message if something went wrong
          } else if (snapshot.hasData) {
            final data = snapshot.data!;

            // Extract the values from the API response
            final totalUsers = data['total_users'];
            final totalVideos = data['total_videos'];

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showUserModal(
                              context); // Show user modal when clicked
                        },
                        child: _buildStatCard("Users", totalUsers.toString(),
                            Colors.red),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showVideoModals(context);// Show video modal when clicked
                        },
                        child: _buildStatCard("Videos", totalVideos.toString(),
                            Colors.deepOrange),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text("Reports", style: TextStyle(fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  _buildPieChart(totalUsers, totalVideos),
                ],
              ),
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  // Stat card widget
  Widget _buildStatCard(String title, String count, Color color) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.black,
      child: Container(
        width: 160,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
            SizedBox(height: 8),
            Text(count, style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // Drawer item widget
  Widget _buildDrawerItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      onTap: () {},
    );
  }

  // Pie chart widget
  Widget _buildPieChart(int totalUsers, int totalVideos) {
    if (totalUsers == 0 && totalVideos == 0) {
      totalUsers = 1;
      totalVideos = 1;
    }

    double total = totalUsers + totalVideos.toDouble();

    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2)
        ],
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 60,
          sections: [
            PieChartSectionData(
              value: totalUsers.toDouble(),
              color: Colors.red,
              title: "${((totalUsers / total) * 100).toStringAsFixed(1)}%",
              radius: 50,
              titleStyle: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            PieChartSectionData(
              value: totalVideos.toDouble(),
              color: Colors.blue,
              title: "${((totalVideos / total) * 100).toStringAsFixed(1)}%",
              radius: 50,
              titleStyle: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Show modal for video details
  // 🔥 Updated video modal with a beautiful UI
  Future<void> _showVideoModals(BuildContext context) async {
    final videos = await ApiService().fetchVideos();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];

            return ListTile(
              title: Text(video['video_name'] ?? 'No title'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Uploaded: ${video['upload_date'] ?? 'N/A'}'),
                  Text('Enrollment: ${video['enrollment'] ?? 'N/A'}'),
                ],
              ),
              onTap: () {
                // You can open a video player here or pass the file path
                print('Selected video path: ${video['video_file']}');
              },
            );
          },
        );
      },
    );
  }
}
