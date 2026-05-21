import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // Needed for the blur filter

class JournalTab extends StatefulWidget {
  const JournalTab({super.key});

  @override
  State<JournalTab> createState() => _JournalTabState();
}

// We need TickerProviderStateMixin for the TabController
class _JournalTabState extends State<JournalTab> with TickerProviderStateMixin {
  late TabController _tabController;

  // --- Variables for the Daily Check-in ---
  double _mood = 5.0; 
  double _energy = 5.0; 
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- Function to Save Check-in (Same logic as before) ---
  Future<void> _saveCheckIn() async {
    if (_notesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out a quick note.')),
      );
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final collection = FirebaseFirestore.instance.collection('journal');
      
      await collection.add({
        'mood': _mood,
        'energy': _energy,
        'notes': _notesController.text,
        'timestamp': FieldValue.serverTimestamp(), 
      });

      _notesController.clear();
      setState(() {
        _mood = 5.0;
        _energy = 5.0;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in saved!')),
      );
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }
  
  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- 1. Background Image ---
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // --- 2. Blur Effect ---
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          
          // --- 3. Scrollable Content ---
          // Use SafeArea to avoid the top phone notch
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Title & Subtitle ---
                  const Text(
                    'Reflection & Vision',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your mind shapes your rebuild',
                    style: TextStyle(fontSize: 16, color: Colors.orange),
                  ),
                  const SizedBox(height: 24),

                  // --- Custom Styled TabBar Chips ---
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.orange, // Selected color
                      ),
                      labelColor: Colors.black, // Text on selected tab
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: 'Daily'),
                        Tab(text: 'Weekly'),
                        Tab(text: 'Vision'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Tab Content ---
                  // We need to give the TabBarView a fixed height
                  SizedBox(
                    height: 600, // Adjust this height as needed
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // --- Daily Tab (The Check-in Form) ---
                        _buildDailyCheckinTab(),

                        // --- Weekly Tab (Placeholder) ---
                        _buildGlowCard(
                          child: const Center(
                            child: Text('Weekly Review (Coming Soon)'),
                          ),
                        ),

                        // --- Vision Tab (Placeholder) ---
                        _buildGlowCard(
                          child: const Center(
                            child: Text('Vision Board (Coming Soon)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget for the "Daily Check-in" tab ---
  Widget _buildDailyCheckinTab() {
    return _buildGlowCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Check-in',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // --- Mood Slider ---
            const Text(
              'Mood',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Slider(
              value: _mood,
              min: 1,
              max: 10,
              divisions: 9,
              label: _mood.round().toString(),
              activeColor: Colors.orange, 
              thumbColor: Colors.orange.shade100,
              onChanged: (double value) {
                setState(() { _mood = value; });
              },
            ),
            const SizedBox(height: 24),

            // --- Energy Slider ---
            const Text(
              'Energy',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Slider(
              value: _energy,
              min: 1,
              max: 10,
              divisions: 9,
              label: _energy.round().toString(),
              activeColor: Colors.blueAccent,
              thumbColor: Colors.blue.shade100,
              onChanged: (double value) {
                setState(() { _energy = value; });
              },
            ),
            const SizedBox(height: 24),

            // --- Quick Note ---
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Quick Note',
                hintText: 'Write your thoughts or gratitude for today...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // --- Save Button ---
            ElevatedButton(
              onPressed: _isLoading ? null : _saveCheckIn,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Save Check-in',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  // --- Helper: Builds the "glass/glow" card ---
  Widget _buildGlowCard({required Widget child}) {
    return Container(
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
}