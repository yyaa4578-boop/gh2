import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'parent_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? selectedRole; // الدور المختار (parent أو child)
  bool isLoading = false;

  Color getColor() {
    if (selectedRole == 'parent') {
      return const Color(0xFF7B2FF7);
    } else if (selectedRole == 'child') {
      return const Color(0xFFF107A3);
    }
    return Colors.grey;
  }

  // دالة توليد رمز دعوة عشوائي (6 أحرف، أرقام وحروف كبيرة)
  String generateInviteCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> register() async {
    if (selectedRole == null) {
      _showError('اختر نوع الحساب أولاً');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user!.uid;
      final email = emailController.text.trim();

      if (selectedRole == 'parent') {
        // توليد رمز دعوة عشوائي
        final inviteCode = generateInviteCode(6);

        // حفظ بيانات الأب مع رمز الدعوة في مجموعة 'parents'
        await FirebaseFirestore.instance.collection('parents').doc(uid).set({
          'email': email,
          'inviteCode': inviteCode,
        });

        // حفظ بيانات الدور في مجموعة 'users'
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'role': 'parent',
        });

        if (!mounted) return;

        // الانتقال لصفحة الأب مع تمرير رمز الدعوة
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ParentScreen(inviteCode: inviteCode),
          ),
        );
      } else if (selectedRole == 'child') {
        // حفظ بيانات الطفل في مجموعة 'children'
        await FirebaseFirestore.instance.collection('children').doc(uid).set({
          'email': email,
        });

        // حفظ بيانات الدور في مجموعة 'users'
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'role': 'child',
        });

        if (!mounted) return;

        Navigator.pop(context); // العودة لشاشة تسجيل الدخول بعد التسجيل
      }
    } on FirebaseAuthException catch (e) {
      String message = 'فشل في إنشاء الحساب';

      if (e.code == 'email-already-in-use') {
        message = 'هذا البريد مستخدم مسبقاً';
      } else if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة، يجب أن تكون 6 أحرف على الأقل';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صالح';
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
      backgroundColor: getColor().withOpacity(0.05),
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        backgroundColor: getColor(),
        centerTitle: true,
        elevation: 6,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _roleRadio('parent', 'أب / مراقب', Icons.security),
                  const SizedBox(width: 20),
                  _roleRadio('child', 'طفل', Icons.child_care),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: getColor()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
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
                        labelStyle: TextStyle(color: getColor()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'أدخل كلمة مرور 6 أحرف على الأقل'
                          : null,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: getColor(),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 8,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'إنشاء الحساب',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleRadio(String roleValue, String label, IconData icon) {
    return Row(
      children: [
        Radio<String>(
          value: roleValue,
          groupValue: selectedRole,
          onChanged: (value) {
            setState(() {
              selectedRole = value;
            });
          },
          activeColor: roleValue == 'parent' ? const Color(0xFF7B2FF7) : const Color(0xFFF107A3),
        ),
        Icon(icon, color: selectedRole == roleValue ? getColor() : Colors.grey),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
