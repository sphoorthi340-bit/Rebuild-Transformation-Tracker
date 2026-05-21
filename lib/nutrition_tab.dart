import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';

class NutritionTab extends StatefulWidget {
  const NutritionTab({super.key});

  @override
  State<NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  // --- 1. REMOVED HARD-CODED DATE ---
  
  // --- 2. ADDED DYNAMIC DATE FUNCTION ---
  String getTodayDocId() {
    final DateTime now = DateTime.now();
    // Format as YYYY-MM-DD
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}'; 
  }
  
  final TextEditingController _waterController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _sleepController = TextEditingController();

  // --- 3. UPDATED NUTRITION FUNCTION (Now smarter) ---
  Future<void> _updateNutrition(String field, num amount,
      {bool isIncrement = true}) async {
    
    final docRef = FirebaseFirestore.instance
        .collection('nutrition_log')
        .doc(getTodayDocId()); // Use dynamic date

    try {
      if (isIncrement) {
        // This will create the doc if it doesn't exist and add the value
        await docRef.set({
          field: FieldValue.increment(amount),
        }, SetOptions(merge: true)); // SetOptions(merge: true) is key
      } else {
        // This will create the doc if it doesn't exist and set the value
        await docRef.set({
          field: amount,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating data: $e'))
      );
    }
  }

  // --- (All other helper functions are the same) ---

  // --- Function to show "Add Macros" dialog ---
  Future<void> _showAddMacrosDialog() async {
    _caloriesController.clear();
    _proteinController.clear();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Add Macros'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _caloriesController,
                decoration:
                    const InputDecoration(labelText: 'Add Calories (kcal)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _proteinController,
                decoration: const InputDecoration(labelText: 'Add Protein (g)'),
                keyboardType: TextInputType.number,
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
                final double calories =
                    double.tryParse(_caloriesController.text) ?? 0.0;
                final double protein =
                    double.tryParse(_proteinController.text) ?? 0.0;

                if (calories > 0) _updateNutrition('total_calories', calories);
                if (protein > 0) _updateNutrition('total_protein', protein);

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- Function to show "Log Sleep" dialog ---
  Future<void> _showLogSleepDialog() async {
    _sleepController.clear();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Log Sleep'),
          content: TextField(
            controller: _sleepController,
            decoration:
                const InputDecoration(labelText: 'Hours Slept (e.g., 7.5)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                final double sleep =
                    double.tryParse(_sleepController.text) ?? 0.0;
                if (sleep > 0) {
                  _updateNutrition('sleep_hours', sleep, isIncrement: false);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- Helper Widget for Macro Progress Bars ---
  Widget _buildMacroBar(String title, num current, num goal) {
    double percent = 0.0;
    if (goal > 0) {
      percent = current / goal;
    }
    if (percent > 1.0) percent = 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$current / $goal',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  // --- Helper: Builds the "glass/glow" card ---
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


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      // --- 4. USE THE DYNAMIC DATE FUNCTION ---
      stream: FirebaseFirestore.instance
          .collection('nutrition_log')
          .doc(getTodayDocId()) // Use dynamic date
          .snapshots(),
      builder: (context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        
        // --- 5. SMART DATA HANDLING ---
        // We no longer require the doc to exist. If it's missing,
        // we just show 0 for everything.
        num calories = 0;
        num protein = 0;
        num water = 0;
        num sleep = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          if (data != null) {
            calories = data['total_calories'] ?? 0;
            protein = data['total_protein'] ?? 0;
            water = data['water_liters'] ?? 0;
            sleep = data['sleep_hours'] ?? 0;
          }
        }

        // (rest of the build method is the same)
        final num goalCalories = 2350;
        final num goalProtein = 180;
        final num goalWater = 4;
        final num goalSleep = 8;
        
        double sleepPercent = 0.0;
        if (goalSleep > 0) sleepPercent = sleep / goalSleep;
        if (sleepPercent > 1.0) sleepPercent = 1.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_fire_department_outlined,
                      color: Colors.orange, size: 32),
                  SizedBox(width: 12),
                  Text(
                    "Today's Fuel",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Macro Breakdown Card (NOW TAPPABLE) ---
              GestureDetector(
                onTap: _showAddMacrosDialog,
                child: _buildGlowCard(
                  context: context,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Macro Breakdown',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildMacroBar('Calories', calories, goalCalories),
                        _buildMacroBar('Protein', protein, goalProtein),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Water Tracker Card ---
              _buildGlowCard(
                context: context,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Water Tracker',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const FaIcon(FontAwesomeIcons.glassWater, 
                              color: Colors.blueAccent, size: 30),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '$water / $goalWater L',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _updateNutrition('water_liters', 0.25); // 250ml
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade800,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50)),
                        child: const Text('Drink 250ml'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _waterController,
                              decoration: const InputDecoration(
                                  labelText: 'Custom amount (ml)',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10)),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              final double ml =
                                  double.tryParse(_waterController.text) ?? 0.0;
                              if (ml > 0) {
                                final double liters = ml / 1000;
                                _updateNutrition('water_liters', liters);
                                _waterController.clear();
                                FocusScope.of(context).unfocus();
                              }
                            },
                            child: const Text('Add'),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // --- Sleep Card (NOW TAPPABLE) ---
              GestureDetector(
                onTap: _showLogSleepDialog,
                child: _buildGlowCard(
                  context: context,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        const Icon(Icons.bedtime_outlined,
                            color: Colors.purpleAccent, size: 40),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sleep',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Last Night: $sleep hours',
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        CircularPercentIndicator(
                          radius: 35.0,
                          lineWidth: 8.0,
                          percent: sleepPercent,
                          center: Text(
                            '${sleep}h',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          footer: const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Goal: 8 h',
                                style: TextStyle(color: Colors.grey)),
                          ),
                          progressColor: Colors.purpleAccent,
                          backgroundColor: Colors.grey.shade800,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}