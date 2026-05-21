import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'exercise_list_page.dart';

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({super.key});

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  String _currentWeekId = 'week_01'; // Default selected week

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. "Workouts" Title & Subtitle ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Text(
                'Workouts',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Text(
                'Rebuild Stronger This Week.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),

            // --- 2. Week Selection Bar ---
            Container(
              height: 50,
              padding: const EdgeInsets.only(left: 16.0),
              child: ListView( // Use a scrollable ListView for the chips
                scrollDirection: Axis.horizontal,
                children: [
                  _buildWeekChip('WEEK 01', 'week_01'),
                  const SizedBox(width: 8),
                  _buildWeekChip('WEEK 05', 'week_05'),
                  const SizedBox(width: 8),
                  _buildWeekChip('WEEK 09', 'week_09'),
                  const SizedBox(width: 8),
                  _buildWeekChip('WEEK 13', 'week_13'),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                'WEEK PROGRESS',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),

            // --- 3. StreamBuilder to get the workout data ---
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
                  return const Center(
                    heightFactor: 5, // Give it some space
                    child: Text('Workout plan not found for this week.'),
                  );
                }

                final workoutData = snapshot.data!.data();
                if (workoutData == null) {
                   return const Center(child: Text('Workout data is empty.'));
                }
                
                final List<Widget> workoutDayCards = [];

                // --- 4. Build the list of cards ---
                if (workoutData.containsKey('monday_workout')) {
                  workoutDayCards.add(_buildWorkoutDayCard(
                    context: context,
                    dayName: 'MONDAY',
                    workoutTitle: 'Push Day',
                    dayKey: 'monday_workout',
                    icon: Icons.fitness_center,
                  ));
                }
                if (workoutData.containsKey('tuesday_workout')) {
                  workoutDayCards.add(_buildWorkoutDayCard(
                    context: context,
                    dayName: 'TUESDAY',
                    workoutTitle: 'Leg Day',
                    dayKey: 'tuesday_workout',
                    icon: Icons.directions_run,
                  ));
                }
                if (workoutData.containsKey('wednesday_workout')) {
                  workoutDayCards.add(_buildWorkoutDayCard(
                    context: context,
                    dayName: 'WEDNESDAY',
                    workoutTitle: 'Mobility',
                    dayKey: 'wednesday_workout',
                    icon: Icons.self_improvement,
                  ));
                }
                if (workoutData.containsKey('thursday_workout')) {
                  workoutDayCards.add(_buildWorkoutDayCard(
                    context: context,
                    dayName: 'THURSDAY',
                    workoutTitle: 'Calisthenics',
                    dayKey: 'thursday_workout',
                    icon: Icons.local_fire_department,
                  ));
                }
                if (workoutData.containsKey('friday_workout')) {
                  workoutDayCards.add(_buildWorkoutDayCard(
                    context: context,
                    dayName: 'FRIDAY',
                    workoutTitle: 'Full Body',
                    dayKey: 'friday_workout',
                    icon: Icons.bolt,
                  ));
                }

                // --- 5. Display the cards in a Grid ---
                return GridView.count(
                  crossAxisCount: 2, // 2 cards per row
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  mainAxisSpacing: 12.0,
                  crossAxisSpacing: 12.0,
                  children: workoutDayCards,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget for the Week Chips ---
  Widget _buildWeekChip(String label, String weekId) {
    final bool isSelected = (_currentWeekId == weekId);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _currentWeekId = weekId; // Change the week when tapped
          });
        }
      },
      // Styling for the "orange glow" pill
      backgroundColor: Colors.white.withOpacity(0.1),
      selectedColor: Colors.orange,
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? Colors.orange : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
    );
  }

  // --- Helper Widget for the new "orange glow" Workout Card ---
  Widget _buildWorkoutDayCard({
    required BuildContext context,
    required String dayName,
    required String workoutTitle,
    required String dayKey,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        // This is the navigation logic, now pointing to the correct collection
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseListPage(
              collectionId: 'program', // This tells it to look in the 'program' collection
              weekId: _currentWeekId,
              dayKey: dayKey,
              dayName: '$dayName - $workoutTitle',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow( // This creates the "glow" effect
              color: Colors.orange.withOpacity(0.1),
              blurRadius: 8.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 24, color: Colors.orange), // Resized icon
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  workoutTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}