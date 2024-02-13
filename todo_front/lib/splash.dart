import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Welocome!'), CircularProgressIndicator()]),
    );
  }

  void checkSignIn() async {
    bool isSignedIn = await googleSignIn.isSignedIn();
    if (isSignedIn) {
      print('Signed in successful');
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      print('Signed in not successful');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
