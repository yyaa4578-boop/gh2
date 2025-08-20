import 'package:app/ChildWebRTCPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ChildScreen extends StatefulWidget {
  const ChildScreen({Key? key}) : super(key: key);

  @override
  State<ChildScreen> createState() => _ChildScreenState();
}

class _ChildScreenState extends State<ChildScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final TextEditingController _inviteCodeController = TextEditingController();

  bool _isLoading = false;
  String? _parentEmail;
  String? _error;

  Future<void> _linkWithParent() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _parentEmail = null;
    });

    try {
      final inviteCode = _inviteCodeController.text.trim();

      if (inviteCode.isEmpty) {
        setState(() {
          _error = 'يرجى إدخال رمز الدعوة';
          _isLoading = false;
        });
        return;
      }

      // ابحث عن الأب برمز الدعوة هذا
      final parentQuery = await _firestore
          .collection('parents')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (parentQuery.docs.isEmpty) {
        setState(() {
          _error = 'رمز الدعوة غير صحيح';
          _isLoading = false;
        });
        return;
      }

      final parentDoc = parentQuery.docs.first;
      final parentId = parentDoc.id;
      final parentEmail = parentDoc.get('email');

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'لم يتم تسجيل الدخول';
          _isLoading = false;
        });
        return;
      }

      // حفظ الربط في بيانات الطفل مع رمز الدعوة
      await _firestore.collection('children').doc(currentUser.uid).set({
        'parentId': parentId,
        'inviteCode': inviteCode,
        'email': currentUser.email,
      }, SetOptions(merge: true));

      setState(() {
        _parentEmail = parentEmail;
        _isLoading = false;
        _error = null;
      });

      // الانتقال إلى صفحة بث WebRTC وتمرير معرف الغرفة (roomId)
      // هنا نستخدم UID الطفل كـ roomId (يمكن تغييره حسب تصميمك)
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ChildWebRTCPage(roomId: currentUser.uid)));
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ، حاول مرة أخرى';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شاشة الطفل'),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_parentEmail != null) ...[
                  Text(
                    'أنت مرتبط بالأب: $_parentEmail',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'جاري الانتقال إلى بث الفيديو...',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Text(
                    'أدخل رمز دعوة الأب لربط حسابك:',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _inviteCodeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'رمز الدعوة',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _linkWithParent,
                          child: const Text('ربط الحساب'),
                        ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
