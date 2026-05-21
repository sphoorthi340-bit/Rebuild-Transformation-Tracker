import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // Needed for the blur filter

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  
  // --- 1. ADDED DYNAMIC DATE FUNCTION ---
  String getTodayDocId() {
    final DateTime now = DateTime.now();
    // Format as YYYY-MM-DD
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'; 
  }

  // --- (Add Habit Dialog is the same) ---
  Future<void> _showAddHabitDialog() async {
    _nameController.clear();
    _timeController.clear(); 

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        String selectedList = 'morning_habits'; 

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Text('Add a New Habit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Habit Name'),
                  ),
                  TextField(
                    controller: _timeController,
                    decoration: const InputDecoration(labelText: 'Time (e.g., 5:00 AM)'),
                  ),
                  DropdownButton<String>(
                    value: selectedList,
                    items: const [
                      DropdownMenuItem(
                        value: 'morning_habits',
                        child: Text('Morning Routine'),
                      ),
                      DropdownMenuItem(
                        value: 'evening_habits',
                        child: Text('Evening Routine'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          selectedList = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    _saveHabit(selectedList); 
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- (Save Habit is the same) ---
  Future<void> _saveHabit(String collectionName) async {
    if (_nameController.text.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection(collectionName).add({
        'name': _nameController.text,
        'time': _timeController.text, 
        'isCompleted': false, 
        'timestamp': FieldValue.serverTimestamp(), 
      });
      _nameController.clear();
      _timeController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save habit: $e')),
      );
    }
  }

  // --- 2. UPDATED HABIT COMPLETION FUNCTION (Now smarter) ---
  Future<void> _updateHabitCompletion(String habitKey, bool isCompleted) async {
    // Note: We're changing this logic. We no longer save 'isCompleted'
    // on the habit definition. We save it in a daily log, just like nutrition.
    final docRef = FirebaseFirestore.instance
        .collection('habit_tracker')
        .doc(getTodayDocId()); // Use dynamic date
        
    try {
      // This will create the doc if it doesn't exist and set the habit's state
      await docRef.set({
        habitKey: isCompleted,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating habit: $e");
    }
  }

  // --- (Delete Habit is the same) ---
  Future<void> _deleteHabit(String collectionName, String docId) async {
    try {
      await FirebaseFirestore.instance.collection(collectionName).doc(docId).delete();
    } catch (e) {
      print("Error deleting habit: $e");
    }
  }

  // --- 3. WIDGET TO BUILD A HABIT LIST (HEAVY REWORK) ---
  // This now takes TWO streams: one for the habit list, one for today's log
  Widget _buildHabitList(BuildContext context, String collectionName, String title) {
    return _buildGlowCard(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // This StreamBuilder gets the HABIT DEFINITIONS (e.g., "Mewing")
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>( 
              stream: FirebaseFirestore.instance
                  .collection(collectionName)
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> listSnapshot) { 
                
                // This StreamBuilder gets TODAY'S LOG (e.g., "{ 'Mewing': true }")
                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('habit_tracker').doc(getTodayDocId()).snapshots(),
                  builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> logSnapshot) {

                    if (listSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!listSnapshot.hasData || listSnapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: Text('No habits yet. Add one!')),
                      );
                    }
                    
                    // Get today's log data. It's ok if it's null.
                    final logData = logSnapshot.data?.data() ?? {};

                    return ListView.builder(
                      itemCount: listSnapshot.data!.docs.length,
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(), 
                      itemBuilder: (context, index) {
                        final doc = listSnapshot.data!.docs[index];
                        if (doc.id == 'init') return const SizedBox.shrink(); 
                        
                        final data = doc.data(); 
                        final String time = data['time'] ?? ''; 
                        final String name = data['name'] ?? 'No Name';
                        
                        // Check if this habit is in our log and is 'true'
                        final bool isCompleted = logData[doc.id] ?? false;

                        return CheckboxListTile(
                          title: Text(name),
                          subtitle: Text(time),
                          value: isCompleted,
                          onChanged: (bool? newValue) {
                            // We now update using the DOCUMENT ID as the key
                            _updateHabitCompletion(doc.id, newValue ?? false);
                          },
                          activeColor: Colors.orange,
                          controlAffinity: ListTileControlAffinity.leading, 
                          secondary: IconButton( 
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () => _deleteHabit(collectionName, doc.id),
                          ),
                        );
                      },
                    );
                  }
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. WEEKLY PROGRESS BARS (Same as before) ---
  Widget _buildWeeklyProgress(BuildContext context) {
    return _buildGlowCard(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Week's progress",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildProgressRow("Mon", 0.33), // Placeholders
            _buildProgressRow("Tue", 0.0),
            _buildProgressRow("Wed", 0.33),
            _buildProgressRow("Thu", 0.0),
            _buildProgressRow("Fri", 0.0),
            _buildProgressRow("Sat", 0.0),
            _buildProgressRow("Sun", 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String day, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 40, 
            child: Text(day, style: const TextStyle(color: Colors.grey))
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.shade800,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGlowCard({required Widget child, required BuildContext context}) {
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
      child: child,
    );
  }

  // --- 5. MAIN BUILD METHOD (Same as before) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        backgroundColor: Colors.orange, 
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView( 
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Routine',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildWeeklyProgress(context),
                  _buildHabitList(context, 'morning_habits', 'Morning Routine'),
                  _buildHabitList(context, 'evening_habits', 'Evening Routine'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}