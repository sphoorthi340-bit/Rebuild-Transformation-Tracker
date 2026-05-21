import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'exercise_list_page.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:ui'; // Needed for blur
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. ADD THIS

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final String _currentWeekId = 'week_01';
  final String _todayWorkoutKey = 'monday_workout';
  final String _todayWorkoutName = 'Today: Push Day';

  // Helper: Builds the "glass/glow" card
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

  // Helper: Builds the "Quick Stats" cards
  Widget _buildStatCard(String title, Widget content) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- 2. MOTIVATION HEADER (NOW DYNAMIC) ---
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  // Get the current user's document from the 'users' collection
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid) // Get logged-in user's ID
                      .snapshots(),
                  builder: (context, snapshot) {
                    int dayNumber = 1; // Default to Day 1
                    
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final userData = snapshot.data!.data();
                      if (userData != null && userData.containsKey('joinDate')) {
                        final Timestamp joinTimestamp = userData['joinDate'];
                        final DateTime joinDate = joinTimestamp.toDate();
                        final DateTime today = DateTime.now();
                        // Calculate the difference in days + 1
                        dayNumber = today.difference(joinDate).inDays + 1;
                      }
                    }

                    return _buildGlowCard(
                      context: context,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAY $dayNumber', // <-- This is now dynamic
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Consistency builds the foundation.',
                              style: TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // --- END OF DYNAMIC HEADER ---
                
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 12.0),
                  child: Text(
                    'Quick Stats',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70),
                  ),
                ),
                Row(
                  children: [
                    _buildStatCard(
                      'WORKOUTS',
                      CircularPercentIndicator(
                        radius: 30.0,
                        lineWidth: 6.0,
                        percent: 5 / 7, // Placeholder
                        center: const Text(
                          '5/7',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        progressColor: Colors.orange,
                        backgroundColor: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'STREAK',
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                          SizedBox(width: 8),
                          Text('12',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'LEVEL',
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.orange, size: 20),
                          Icon(Icons.star, color: Colors.orange, size: 20),
                          Icon(Icons.star_border, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // --- "Push Day" Card (Live Data) ---
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('program')
                      .doc(_currentWeekId)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return _buildGlowCard(
                          context: context,
                          child: const ListTile(title: Text('No workout found')));
                    }

                    final workoutData = snapshot.data!.data();
                    if (workoutData == null) {
                      return _buildGlowCard(
                          context: context,
                          child: const ListTile(title: Text('Workout data is empty.')));
                    }
                    final exercises = workoutData[_todayWorkoutKey] ?? [];
                    final exercisesPreview = exercises.take(2).toList(); 

                    return _buildGlowCard(
                      context: context,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _todayWorkoutName.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Stronger than yesterday',
                              style: TextStyle(color: Colors.orange, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ...exercisesPreview.map((exercise) {
                              final String name = exercise['name'] ?? 'No name';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.fitness_center,
                                        size: 20, color: Colors.white70),
                                    const SizedBox(width: 12),
                                    Text(name,
                                        style: const TextStyle(fontSize: 16)),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExerciseListPage(
                                      weekId: _currentWeekId,
                                      dayKey: _todayWorkoutKey,
                                      dayName: _todayWorkoutName,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                'START WORKOUT',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // --- Today's Nutrition (Placeholder) ---
                _buildGlowCard(
                  context: context,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TODAY'S NUTRITION",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('1200 / 2000 kcal',
                                style: TextStyle(color: Colors.white70)),
                            Text('80 g / 150 g',
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: 1200 / 2000,
                          backgroundColor: Colors.grey.shade800,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.orange),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: 80 / 150,
                          backgroundColor: Colors.grey.shade800,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.orange),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
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