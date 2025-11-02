// screens/profile/edit_name_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditNameDialog extends StatefulWidget {
  final String currentName;
  const EditNameDialog({required this.currentName});

  @override
  _EditNameDialogState createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late TextEditingController _ctrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentName);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sửa tên'),
      content: TextField(
        controller: _ctrl,
        decoration: const InputDecoration(hintText: 'Nhập tên mới'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Lưu'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'name': name});
    Navigator.pop(context);
  }
}