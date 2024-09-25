import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Add this import

class ProfilePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    _auth.currentUser?.displayName?.substring(0, 1) ?? 'A',
                    style: TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),

                SizedBox(height: 20),

                // Display username
                Text(
                  _auth.currentUser?.displayName ?? "N/A",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                // Display email
                Text(
                  _auth.currentUser?.email ?? "N/A",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),

                SizedBox(height: 40),

                // Button to change password
                ElevatedButton.icon(
                  onPressed: () async {
                    await _showChangePasswordDialog(context);
                  },
                  icon: Icon(Icons.lock_outline),
                  label: Text('Change Password'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    textStyle: TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Button to delete account
                ElevatedButton.icon(
                  onPressed: () async {
                    await _deleteAccount(context);
                  },
                  icon: Icon(Icons.delete_outline),
                  label: Text('Delete Account'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    textStyle: TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    bool isLoading = false; // Track loading state

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: isLoading
              ? Center(
                  child: SpinKitThreeBounce(
                      color: Colors.blue)) // Show loading spinner
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPasswordController,
                      decoration: InputDecoration(hintText: "Old Password"),
                      obscureText: true,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: newPasswordController,
                      decoration: InputDecoration(hintText: "New Password"),
                      obscureText: true,
                    ),
                  ],
                ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if (!isLoading) {
                  // Prevent multiple submissions
                  final oldPassword = oldPasswordController.text;
                  final newPassword = newPasswordController.text;

                  if (oldPassword.isNotEmpty && newPassword.isNotEmpty) {
                    isLoading = true; // Set loading state
                    Navigator.of(context).pop(); // Close dialog to show spinner

                    try {
                      User? user = _auth.currentUser;
                      if (user == null) {
                        throw Exception(
                            "No user is currently signed in."); // Check for user
                      }

                      final cred = EmailAuthProvider.credential(
                        email: user.email!, // Use null assertion operator
                        password: oldPassword,
                      );

                      await user.reauthenticateWithCredential(cred);
                      await user.updatePassword(newPassword);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Password changed successfully!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    } finally {
                      isLoading = false; // Reset loading state
                      Navigator.of(context).pop(); // Close spinner dialog
                    }
                  }
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    // Inform user about data deletion
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text(
              'All uploaded data will be deleted. Are you sure you want to proceed?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      // Proceed only if confirmed
      try {
        await _auth.currentUser?.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account deleted successfully!')),
        );
        // Navigate back to the login page
        Navigator.pushReplacementNamed(context, '/'); // Add this line
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }
}
