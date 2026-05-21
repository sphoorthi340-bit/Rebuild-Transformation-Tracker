import 'package:flutter/material.dart';
import 'dart:ui'; // Needed for the blur filter
import 'exercise_list_page.dart'; // Import the exercise list page

class MobilityTab extends StatelessWidget {
  const MobilityTab({super.key});

  // --- 1. Helper: Builds the "glass/glow" card ---
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

  // --- 2. NEW HELPER WIDGET: Builds the large flow cards ---
  Widget _buildFlowCard({
    required BuildContext context,
    required String title,
    required String duration,
    required IconData icon,
    required String docId, // The doc to load, e.g., 'morning_flow'
  }) {
    return _buildGlowCard(
      context: context,
      child: InkWell(
        onTap: () {
          // Navigate to the exercise list page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseListPage(
                collectionId: 'mobility', // Pass 'mobility' as the collection
                weekId: docId,       // Pass the docId (e.g., 'morning_flow')
                dayKey: 'exercises',   // The field name in your 'mobility' doc
                dayName: title,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 24, color: Colors.orange),
              const Spacer(),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '$duration minutes',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseListPage(
                        collectionId: 'mobility',
                        weekId: docId,
                        dayKey: 'exercises',
                        dayName: title,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.withOpacity(0.8),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Start Flow'),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. MAIN BUILD METHOD (Rebuilt) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Title ---
                  const Text(
                    'Mobility & Recovery',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // --- Description ---
                  const Text(
                    'Enhance flexibility, reduce stiffness, and improve posture.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // --- Grid of Flow Cards ---
                  GridView.count(
                    crossAxisCount: 2, // 2 cards per row
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 12.0,
                    childAspectRatio: 0.8, // Makes cards taller
                    children: [
                      _buildFlowCard(
                        context: context,
                        title: 'Morning Mobility',
                        duration: '10',
                        icon: Icons.wb_sunny_outlined,
                        docId: 'morning_flow',
                      ),
                      _buildFlowCard(
                        context: context,
                        title: 'Night Stretch',
                        duration: '8',
                        icon: Icons.nightlight_round,
                        docId: 'night_flow', // (You'll need to create this doc in Firestore)
                      ),
                      _buildFlowCard(
                        context: context,
                        title: 'Full Body Reset',
                        duration: '15',
                        icon: Icons.refresh,
                        docId: 'full_body_reset', // (You'll need to create this doc in Firestore)
                      ),
                      _buildFlowCard(
                        context: context,
                        title: 'Lower Body Focus',
                        duration: '12',
                        icon: Icons.directions_run,
                        docId: 'lower_body_focus', // (You'll need to create this doc in Firestore)
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}