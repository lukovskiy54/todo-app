import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:todo_front/auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: <String>[
        'email',
      ],
      clientId:
          "48608572513-19oeb7v99nj1sjbksiqq41npdh4sv768.apps.googleusercontent.com");
  @override
  void initState() {
    checkSignIn();
    super.initState();
  }

  void checkSignIn() async {
    bool isSignedIn = await googleSignIn.isSignedIn();
    if (isSignedIn) {
      print('Signed in successful');
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      print('Signed in not successful');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          "Welcome!",
          style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 150,
        ),
        ElevatedButton.icon(
          label: Text('Sign in with Google'),
          icon: Image.asset(
            'assets/google-logo.png',
          ),
          onPressed: signInWithGoogle,
        )
      ]),
    );
  }

  void signInWithGoogle() async {
    var googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return;
    }
    final storage = new FlutterSecureStorage();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    if (googleAuth.accessToken != null) {
      final String accessToken = googleAuth.accessToken!;
      final String userEmail = googleUser.email;
      await storage.write(key: 'google_access_token', value: accessToken);
      await storage.write(key: 'email', value: userEmail);
      checkSignIn();
    } else {
      print('Google Sign-In did not return an access token.');
    }
  }
}
