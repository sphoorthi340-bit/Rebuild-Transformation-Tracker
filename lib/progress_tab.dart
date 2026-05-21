import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // 1. IMPORT THE CHART PACKAGE
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Needed for the blur filter

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  // --- Controllers for Log Progress Form ---
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _chestController = TextEditingController();
  final TextEditingController _armsController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _thighsController = TextEditingController();
  bool _isLoading = false;

  // --- Controllers & State for BMI Calculator ---
  final TextEditingController _bmiHeightController = TextEditingController();
  final TextEditingController _bmiWeightController = TextEditingController();
  String _bmiResult = 'Enter height (cm) and weight (kg)';

  // --- 1. Function to Save Progress (Same as before) ---
  Future<void> _saveProgress() async {
    setState(() { _isLoading = true; });

    final double weight = double.tryParse(_weightController.text) ?? 0;
    final double chest = double.tryParse(_chestController.text) ?? 0;
    final double arms = double.tryParse(_armsController.text) ?? 0;
    final double waist = double.tryParse(_waistController.text) ?? 0;
    final double thighs = double.tryParse(_thighsController.text) ?? 0;

    try {
      await FirebaseFirestore.instance.collection('progress_log').add({
        'timestamp': FieldValue.serverTimestamp(),
        'weight': weight,
        'chest': chest,
        'arms': arms,
        'waist': waist,
        'thighs': thighs,
      });

      _weightController.clear();
      _chestController.clear();
      _armsController.clear();
      _waistController.clear();
      _thighsController.clear();

      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress saved!')),
      );
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  // --- 2. Function to Calculate BMI (Same as before) ---
  void _calculateBmi() {
    final double heightCm = double.tryParse(_bmiHeightController.text) ?? 0;
    final double weightKg = double.tryParse(_bmiWeightController.text) ?? 0;

    if (heightCm <= 0 || weightKg <= 0) {
      setState(() { _bmiResult = 'Please enter valid numbers'; });
      return;
    }
    
    final double heightM = heightCm / 100;
    final double bmi = weightKg / (heightM * heightM);

    setState(() {
      _bmiResult = 'Your BMI is: ${bmi.toStringAsFixed(1)}';
    });
  }

  // --- 3. Widget to build the history "Data Story" page (NEW DESIGN) ---
  Widget _buildHistoryPage() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('progress_log')
          .orderBy('timestamp', descending: false) 
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty || snapshot.data!.docs.length <= 1) {
          return const Center(child: Text('Log at least two entries to see your graph.'));
        }

        // --- Process Data for Graph ---
        final List<FlSpot> weightSpots = [];
        final List<DocumentSnapshot> progressDocs = snapshot.data!.docs;
        
        // Get latest measurements
        final latestData = progressDocs.last.data() as Map<String, dynamic>;
        final String chest = (latestData['chest'] ?? 0).toString();
        final String arms = (latestData['arms'] ?? 0).toString();
        final String waist = (latestData['waist'] ?? 0).toString();
        final String thighs = (latestData['thighs'] ?? 0).toString(); 

        double minWeight = double.maxFinite;
        double maxWeight = double.minPositive;
        int validSpotIndex = 0; 

        for (int i = 0; i < progressDocs.length; i++) {
          if (progressDocs[i].id == 'init') continue;
          final data = progressDocs[i].data() as Map<String, dynamic>;
          final double weight = (data['weight'] ?? 0).toDouble();
          
          if (weight > 0) {
            if (weight < minWeight) minWeight = weight;
            if (weight > maxWeight) maxWeight = weight;
            weightSpots.add(FlSpot(validSpotIndex.toDouble(), weight));
            validSpotIndex++;
          }
        }
        
        if (weightSpots.isEmpty) {
          return const Center(child: Text('Log your weight to see the graph.'));
        }

        // --- Build The UI ---
        return Stack( // Use a Stack for the background image
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
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Data Story',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Progress in motion',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // --- Quick Stats Card ---
                  _buildGlowCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Stats',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow(Icons.local_fire_department, 'Current Streak', '12 days strong'),
                          const SizedBox(height: 12),
                          _buildStatRow(Icons.fitness_center, 'Workouts This Week', '5/7 completed'),
                        ],
                      ),
                    )
                  ),

                  // --- Weight Trend Graph Card ---
                  _buildGlowCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weight Trend',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You're up 5 lbs since Oct 01", // Placeholder
                            style: TextStyle(color: Colors.orange, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                minY: minWeight - 2, 
                                maxY: maxWeight + 2,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey.withOpacity(0.1),
                                    strokeWidth: 1,
                                  ),
                                  getDrawingVerticalLine: (value) => FlLine(
                                    color: Colors.grey.withOpacity(0.1),
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(color: Colors.grey, fontSize: 10)))),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: weightSpots,
                                    isCurved: true,
                                    color: Colors.orange,
                                    barWidth: 4,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.orange.withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // --- Body Measurements Card ---
                  _buildGlowCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Body Measurements',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildMeasurementRow(Icons.format_size, 'Chest', '$chest inches', '+1.2 in (last 30 d)'),
                          _buildMeasurementRow(Icons.fitness_center, 'Arms', '$arms inches', '+0.5 in (last 30 d)'),
                          _buildMeasurementRow(Icons.straighten, 'Waist', '$waist inches', '-0.8 in (last 30 d)'),
                          _buildMeasurementRow(Icons.directions_run, 'Thighs', '$thighs inches', '+1.0 in (last 30 d)'),
                        ],
                      ),
                    )
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper for Quick Stat rows
  Widget _buildStatRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 16, color: Colors.white70)),
      ],
    );
  }

  // Helper for Measurement rows (Now with sub-text)
  Widget _buildMeasurementRow(IconData icon, String title, String value, String change) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(change, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
  
  // --- Helper: Builds the "glass/glow" card ---
  Widget _buildGlowCard({required Widget child}) {
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

  // --- 4. Main Build Method (with Tabs) ---
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Three tabs
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: 'My Data Story'),
              Tab(text: 'Log Progress'),
              Tab(text: 'BMI Calc'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- Tab 1: History Page (The new design) ---
            _buildHistoryPage(),

            // --- Tab 2: Log Progress Form ---
            // This tab now also gets the background image
            Stack(
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
                    children: [
                      _buildTextField(_weightController, 'Weight (kg)'),
                      _buildTextField(_chestController, 'Chest (cm)'),
                      _buildTextField(_armsController, 'Arms (cm)'),
                      _buildTextField(_waistController, 'Waist (cm)'),
                      _buildTextField(_thighsController, 'Thighs (cm)'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProgress,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Save Progress', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Tab 3: BMI Calculator ---
            // This tab also gets the background
            Stack(
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
                    children: [
                      const SizedBox(height: 20),
                      Text(_bmiResult, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildTextField(_bmiHeightController, 'Height (cm)'),
                      _buildTextField(_bmiWeightController, 'Weight (kg)'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _calculateBmi,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Calculate BMI', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to make text fields (same as before)
  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
      ),
    );
  }
}