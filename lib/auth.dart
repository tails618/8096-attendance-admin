import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;

class Auth {
  Auth();

  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Future<UserCredential> signInWithGoogle() async {
    // Create a new provider
    GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope("https://www.googleapis.com/auth/userinfo.email");
    googleProvider.addScope("https://www.googleapis.com/auth/userinfo.profile");
    // googleProvider
    //     .setCustomParameters({'login_hint': 'user@ucls.uchicago.edu'});

    // Once signed in, return the UserCredential
    return await firebaseAuth.signInWithPopup(googleProvider);

    // Or use signInWithRedirect
    // return await FirebaseAuth.instance.signInWithRedirect(googleProvider);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  bool isSignedIn() {
    return firebaseAuth.currentUser != null;
  }
}

class SignInButton extends StatelessWidget {
  const SignInButton({
    super.key,
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Auth().signInWithGoogle().then((value) => html.window.location.reload());
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
          // html.window.location.reload();
        });
      },
      child: const Text('Sign In'),
    );
  }
}

class SignOutButton extends StatelessWidget {
  const SignOutButton({
    super.key,
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Auth().signOut();
        html.window.location.reload();
      },
      child: const Text('Sign out of account'),
    );
  }
}
