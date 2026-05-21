import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Needed for the blur filter

class GlowupTab extends StatefulWidget {
  const GlowupTab({super.key});

  @override
  State<GlowupTab> createState() => _GlowupTabState();
}

class _GlowupTabState extends State<GlowupTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // --- 1. FUNCTION TO SHOW THE "ADD NOTE" DIALOG (Styled) ---
  Future<void> _showAddNoteDialog() async {
    _titleController.clear();
    _noteController.clear();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Use the theme's card color for the dialog
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Add a New Glowup Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note'),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // Use an ElevatedButton to match your theme
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                _saveNote();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- 2. LOGIC FUNCTIONS (Save, Delete, Confirm) ---
  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty || _noteController.text.isEmpty) {
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('glowup_notes').add({
        'title': _titleController.text,
        'note': _noteController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save note: $e')),
      );
    }
  }

  Future<void> _deleteNote(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('glowup_notes')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete note: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmDialog(String docId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Delete Note?'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete'),
              onPressed: () {
                _deleteNote(docId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- 3. Helper: Builds the "glass/glow" card ---
  Widget _buildGlowCard(
      {required Widget child, EdgeInsets padding = const EdgeInsets.all(16.0)}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  // --- 4. MAIN BUILD METHOD (Now styled) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        backgroundColor: Colors.orange, // Match theme
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Stack(
        children: [
          // --- Background Image ---
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // --- Blur Effect ---
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // --- Scrollable Content ---
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Title for the page ---
                const Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Glowup Notes',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                // --- StreamBuilder is now wrapped in an Expanded ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('glowup_notes')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context,
                        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                            snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No notes yet. Add one!'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          if (doc.id == 'init') return const SizedBox.shrink();

                          final data = doc.data();
                          // if (data == null) return const SizedBox.shrink(); // <-- THIS IS THE FIX

                          final String date = data['timestamp'] == null
                              ? 'No date'
                              : DateFormat.yMMMd().format(
                                  (data['timestamp'] as Timestamp).toDate());

                          // --- NEW: Styled "Glow" Card ---
                          return _buildGlowCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 12.0),
                              title: Text(
                                data['title'] ?? 'No Title',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                child: Text(
                                  data['note'] ?? 'No Note',
                                  style: const TextStyle(color: Colors.white70),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              trailing: Text(date,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              onLongPress: () =>
                                  _showDeleteConfirmDialog(doc.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}