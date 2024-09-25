import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chatty_teacher/screens/chat_screen.dart';
import 'package:chatty_teacher/widgets/file_upload_widget.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _navigateToProfile() {
    // Navigate to the profile page
    Navigator.pushNamed(context, '/profile');
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () async {
                // Perform logout operation using Firebase Auth
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                // Navigate to login page or perform other actions
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Intelligent Study Buddy'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: _navigateToProfile,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1024) {
            return ChatScreen();
          } else {
            return Row(
              children: <Widget>[
                Flexible(
                  child: FileUploadWidget(),
                  flex: 2,
                ),
                Flexible(child: ChatScreen(), flex: 5),
              ],
            );
          }
        },
      ),
    );
  }
}