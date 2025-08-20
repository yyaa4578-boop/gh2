import 'package:app/ParentWebRTCPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ParentScreen extends StatefulWidget {
  final String inviteCode; // رمز الدعوة

  const ParentScreen({Key? key, required this.inviteCode}) : super(key: key);

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  List<Map<String, dynamic>> children = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('children')
          .where('inviteCode', isEqualTo: widget.inviteCode)
          .get();

      final kids = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'email': doc.data()['email'] ?? 'بدون بريد',
          'name': doc.data()['name'] ?? 'طفل بدون اسم',
        };
      }).toList();

      setState(() {
        children = kids;
      });
    } catch (e) {
      print('خطأ بجلب بيانات الأطفال: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openChildStream(String childId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ParentWebRTCPage(roomId: childId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('صفحة الأب'),
        backgroundColor: const Color(0xFF7B2FF7),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChildren,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'رمز الدعوة الخاص بك:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              widget.inviteCode,
              style: const TextStyle(fontSize: 24, color: Colors.deepPurple),
            ),
            const SizedBox(height: 24),
            const Text(
              'الأطفال المرتبطين بك:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (children.isEmpty)
              const Text('لا يوجد أطفال مرتبطين حتى الآن.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    return ListTile(
                      leading:
                          const Icon(Icons.child_care, color: Colors.pink),
                      title: Text(child['name']),
                      subtitle: Text(child['email']),
                      trailing: ElevatedButton(
                        onPressed: () => _openChildStream(child['id']),
                        child: const Text('عرض البث'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
