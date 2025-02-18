import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:utube/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _enrollmentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      String enrollment = _enrollmentController.text.trim();
      String password = _passwordController.text.trim();

      var url = Uri.parse("http://127.0.0.1:8000/login/");
      var response = await http.post(
        url,
        body: jsonEncode({"enrollment": enrollment, "password": password}),
        headers: {"Content-Type": "application/json"},
      );

      print("Response: ${response.body}"); // Debugging

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["status"] == "success") {
          _showSuccessAlert(); // Show success alert before redirection
        } else {
          _showAlert("Invalid credentials! Please try again.");
        }
      } else {
        _showAlert("Server error! Please try again later.");
      }
    }
  }

  void _showSuccessAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Successful"),
        content: const Text("Welcome! Redirecting to Home..."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close alert
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Full black background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/UTUBE.png", width: 200), // Logo
              const SizedBox(height: 20),

              const Text(
                "Welcome to Utube",
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Glass-like Login Form
              Card(
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 10,
                shadowColor: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField(
                          controller: _enrollmentController,
                          label: "Enrollment",
                          icon: Icons.person,
                          isPassword: false,
                        ),
                        const SizedBox(height: 15),

                        _buildTextField(
                          controller: _passwordController,
                          label: "Password",
                          icon: Icons.lock,
                          isPassword: true,
                        ),
                        const SizedBox(height: 20),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 5,
                            ),
                            onPressed: _login,
                            child: const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Text Field Widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isPassword,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter your $label";
        }
        if (isPassword && value.length < 6) {
          return "Password must be at least 6 characters";
        }
        return null;
      },
    );
  }
}
