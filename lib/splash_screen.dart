import 'package:app/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'parent_screen.dart';
import 'child_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 1));
      await _checkUserStatus();
    });
  }

  Future<void> _checkUserStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _goToLogin();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final role = doc.data()?['role'];

      if (role == 'parent') {
        final parentDoc =
            await FirebaseFirestore.instance.collection('parents').doc(user.uid).get();
        final inviteCode = parentDoc.data()?['inviteCode'] ?? '';
        _goToParent(inviteCode);
      } else if (role == 'child') {
        _goToChild();
      } else {
        _goToLogin();
      }
    } catch (e) {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToParent(String inviteCode) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ParentScreen(inviteCode: inviteCode)),
    );
  }

  void _goToChild() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChildScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.purple.shade900, Colors.pinkAccent.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.shade100.withOpacity(0.6),
                spreadRadius: 5,
                blurRadius: 20,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 5,
            ),
          ),
        ),
      ),
    );
  }
}
