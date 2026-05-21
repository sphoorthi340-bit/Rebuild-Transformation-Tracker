import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'video_player_page.dart';
import 'dart:ui'; // Needed for the blur filter

class ExerciseListPage extends StatelessWidget {
  // --- 1. THIS IS THE FIX ---
  // We now accept a 'collectionId'
  final String collectionId; // e.g., 'program' or 'mobility'
  // --- END OF FIX ---
  
  final String weekId;       // e.g., 'week_01' or 'morning_flow'
  final String dayKey;       // e.g., 'monday_workout' or 'exercises'
  final String dayName;

  const ExerciseListPage({
    super.key,
    this.collectionId = 'program', // Default to 'program'
    required this.weekId,
    required this.dayKey,
    required this.dayName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dayName),
        backgroundColor: Colors.transparent, // Make app bar transparent
        elevation: 0,
      ),
      // Use a Stack to put the background image behind the list
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
          
          // --- The List of Exercises ---
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            // --- 2. THIS IS THE FIX ---
            // Use the new 'collectionId' variable
            stream: FirebaseFirestore.instance
                .collection(collectionId) 
                .doc(weekId)
                .snapshots(),
            // --- END OF FIX ---
            builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) { 
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Workout not found.'));
              }

              final docData = snapshot.data!.data();
              if (docData == null) {
                return const Center(child: Text('Workout data is empty.'));
              }
              
              final List<dynamic> exercises = docData[dayKey] ?? [];

              if (exercises.isEmpty) {
                return const Center(child: Text('No exercises found for this day.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0), // Add padding
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index] as Map<String, dynamic>;
                  final String name = exercise['name'] ?? 'No name';
                  final String reps = exercise['reps'] ?? 'No reps';
                  final String videoUrl = exercise['video'] ?? ''; 
                  final bool hasVideo = videoUrl.isNotEmpty;

                  // --- 3. STYLED "GLOW" CARD ---
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(reps, style: const TextStyle(color: Colors.grey)),
                      trailing: hasVideo
                          ? Icon(Icons.play_circle_filled, color: Colors.orange, size: 30)
                          : null, 
                      onTap: hasVideo
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerPage(
                                    videoUrl: videoUrl,
                                    exerciseName: name,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}