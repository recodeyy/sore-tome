import 'package:flutter/material.dart';
import 'package:sero/app/theme.dart';
import 'package:sero/services/firestore_service.dart';
import 'package:sero/models/notice.dart';

class PostNoticeScreen extends StatefulWidget {
  const PostNoticeScreen({super.key});

  @override
  State<PostNoticeScreen> createState() => _PostNoticeScreenState();
}

class _PostNoticeScreenState extends State<PostNoticeScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _tag = 'info';
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final notice = Notice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      createdAt: DateTime.now(),
      tag: _tag,
    );
    await FirestoreService().postNotice(notice);
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryGreen,
        title: const Text('Post Notice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Title',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'Notice title'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Body',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyCtrl,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Notice details...'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tag',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _tag,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFDDDDDD),
                    width: 0.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFDDDDDD),
                    width: 0.5,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'info', child: Text('Info')),
                DropdownMenuItem(value: 'new', child: Text('New')),
                DropdownMenuItem(value: 'today', child: Text('Today')),
              ],
              onChanged: (v) => setState(() => _tag = v ?? 'info'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Post Notice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






