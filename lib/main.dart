import 'package:chatty_teacher/screens/home_page.dart';
import 'package:chatty_teacher/screens/login_page.dart';
import 'package:chatty_teacher/screens/profile_page.dart';
import 'package:chatty_teacher/widgets/files_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyBND2xVxsqT414VCux5T9IDWXqz3kt4ouU",
        authDomain: "intelligent-study-buddy.firebaseapp.com",
        projectId: "intelligent-study-buddy",
        storageBucket: "intelligent-study-buddy.appspot.com",
        messagingSenderId: "530746457718",
        appId: "1:530746457718:web:3f5265fa4d6a3b640ce957",
        measurementId: "G-JF5PY3NPZX"),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) =>
                FileProvider()), // Create FileProvider instance
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intelligent Study Buddy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Remove the home property
      // home: AuthWrapper(),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(), // Change this to AuthWrapper
        '/profile': (context) => ProfilePage(), // Add this line
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasData) {
          return HomePage(); // User is logged in
        } else {
          return LoginPage(); // User is not logged in
        }
      },
    );
  }
}
