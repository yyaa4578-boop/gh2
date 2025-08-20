import 'package:app/RegisterScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'parent_screen.dart';
import 'child_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Color getColor() => Colors.deepPurple;

  Future<String?> getUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['role'] as String?;
    }
    return null;
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      String? role = await getUserRole();

      if (role == 'parent') {
        // جلب رمز الدعوة من Firestore ثم الذهاب إلى ParentScreen
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final doc = await FirebaseFirestore.instance.collection('parents').doc(uid).get();
        final inviteCode = doc.data()?['inviteCode'] ?? '';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ParentScreen(inviteCode: inviteCode),
          ),
        );
      } else if (role == 'child') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChildScreen()),
        );
      } else {
        _showError('لم يتم تحديد دور المستخدم');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'فشل تسجيل الدخول';
      if (e.code == 'user-not-found') {
        message = 'البريد غير مسجل.';
      } else if (e.code == 'wrong-password') {
        message = 'كلمة المرور غير صحيحة.';
      } else if (e.code == 'invalid-email') {
        message = 'البريد غير صالح.';
      }
      _showError(message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getColor().withOpacity(0.1),
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        backgroundColor: getColor(),
        centerTitle: true,
        elevation: 6,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login, size: 90, color: getColor()),
                const SizedBox(height: 24),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  validator: (value) =>
                      value == null || !value.contains('@') ? 'أدخل بريدًا صحيحًا' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  validator: (value) =>
                      value == null || value.length < 6 ? 'أدخل كلمة مرور 6 أحرف على الأقل' : null,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: getColor(),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 8,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // التنقل لصفحة التسجيل مباشرةً
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: Text('إنشاء حساب جديد', style: TextStyle(color: getColor())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
